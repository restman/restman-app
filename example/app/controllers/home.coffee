errors = require 'restman-errors'

module.exports = (app, router) ->
  app.use '/', router

  router.get '/', (req, res, next) ->
    console.log req.data.test
    res.send('hello')

  router.get '/other_error', (req, res, next) ->
    return next new Error("haha")

  router.get '/rest_error', (req, res, next) ->
    return next errors.Invalid('resource', 'field', 'code', 'message')