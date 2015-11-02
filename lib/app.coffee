express             = require 'express'
glob                = require 'glob'
morgan              = require 'morgan'
cookieParser        = require 'cookie-parser'
bodyParser          = require 'body-parser'
methodOverride      = require 'method-override'
responseTime        = require 'response-time'
winston             = require 'winston'
errors              = require 'restman-errors'

env = process.env.NODE_ENV or 'development'

# opts dependency logPath、middlewarePath、controllerPath
module.exports = (opts) ->

  # create app
  app = express()

  # disable x-powered-by
  app.disable 'x-powered-by'

  # use winston on production
  morganOpts = {}
  if env is 'production'
    accessLogger = new winston.Logger()
    accessLogger.add(winston.transports.DailyRotateFile, filename: opts.logPath + '/access.log')
    accessLogger.write = (message, encoding) ->
      accessLogger.info(message)
    morganOpts =
      format: 'combined'
      opts:
        stream: accessLogger
  else
    morganOpts =
      format: 'dev'
      opts: null

  # don't logged with test env
  # use morgan write access log
  app.use morgan(morganOpts.format, morganOpts.opts) if env isnt 'test'

  # parse json body
  app.use bodyParser.json()
  app.use bodyParser.urlencoded(
    extended: true
  )

  # parse cookie
  app.use cookieParser()

  # method override
  # override with different headers; last one takes precedence
  app.use methodOverride('X-HTTP-Method')          # Microsoft
  app.use methodOverride('X-HTTP-Method-Override') # Google/GData
  app.use methodOverride('X-Method-Override')      # IBM

  # responseTime
  # adds a X-Response-Time header to responses
  app.use responseTime()

  # init req.data and charset
  app.use (req, res, next) ->
    req.data = {}
    res.charset = 'utf-8'
    next()

  # load custom middlewares
  middlewares = require(opts.middlewarePath)
  middlewares.forEach (middleware) ->
    app.use middleware

  # Load controllers
  controllers = glob.sync "#{opts.controllerPath}/**/*.coffee"
  controllers.forEach (controllerPath) ->
    router = express.Router()
    require(controllerPath)(app, router)

  # catch 404 and forward to error handler
  app.use (req, res, next) ->
    next errors.ResourceNotFound()

  errorLoggerOpts =
    filename: opts.logPath + '/error.log'
    json: false
    timestamp: true
    prettyPrint: true

  errorLogger = new winston.Logger()
  errorLogger.add winston.transports.DailyRotateFile, errorLoggerOpts

  if env isnt 'production'
    errorLogger.add winston.transports.Console, errorLoggerOpts

  # catch errors handler
  app.use (err, req, res, next) ->
    return res.status(err.status_code).json(err) if err instanceof errors.RestError
    errorLogger.info err.stack
    res.status(500).json(errors.Internal())

  # Return app
  app
