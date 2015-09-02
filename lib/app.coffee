express             = require 'express'
glob                = require 'glob'
morgan              = require 'morgan'
cookieParser        = require 'cookie-parser'
bodyParser          = require 'body-parser'
methodOverride      = require 'method-override'
responseTime        = require 'response-time'
winston             = require 'winston'

env = process.env.NODE_ENV or 'development'

# opts dependency logPath、middlewarePath、controllerPath
module.exports = (opts) ->

  # create app
  app = express()

  # disable x-powered-by
  app.disable 'x-powered-by'

  # use morgan write access log
  if env is 'production'
    logger = new winston.Logger()
    logger.add(winston.transports.DailyRotateFile, filename: opts.logPath + '/access.log')
    logger.write = (message, encoding) ->
      logger.info(message)
    app.use morgan('combined', stream: logger)
  else
    app.use morgan 'dev'

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

  # load custom middlewares
  middlewares = require(opts.middlewarePath)
  middlewares.forEach (middleware) ->
    app.use middleware

  # init req.data and charset
  app.use (req, res, next) ->
    req.data = {}
    res.charset = 'utf-8'
    next()

  # Load controllers
  controllers = glob.sync "#{opts.controllerPath}/**/*.coffee"
  controllers.forEach (controllerPath) ->
    router = express.Router()
    require(controllerPath)(app, router)

  # catch 404 and forward to error handler
  app.use (req, res, next) ->
    error = new Error 'Resource Not Found'
    error.name = 'ResourceNotFound'
    error.resource = ''
    error.field = ''
    error.statusCode = 404
    next error

  # catch errors handler
  app.use (err, req, res, next) ->
    status = err.status or err.statusCode or 500

    body =
      code: err.name
      message: err.message
      resource: err.resource
      field: err.field

    body['error'] = err.stack if env is 'development'

    res.status(status).json(body)

  # Return app
  app
