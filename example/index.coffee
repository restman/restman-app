opts = (rootPath) ->
  ENV: process.env.NODE_ENV || 'development'
  rootPath: rootPath
  configPath: "#{rootPath}/app/config"
  controllerPath: "#{rootPath}/app/controllers"
  modelPath: "#{rootPath}/app/models"
  middlewarePath: "#{rootPath}/app/middlewares"
  logPath: "#{rootPath}/logs"
  testPath: "#{rootPath}/test"

app = require('../')(opts(__dirname))

app.listen 8080, '0.0.0.0'
console.log 'restman listening at http://0.0.0.0:' + 8080
