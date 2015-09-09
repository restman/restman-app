
module.exports = (app, router) ->
  app.use '/', router

  router.get '/', (req, res, next) ->
    console.log req.data.test
    res.send('hello')
