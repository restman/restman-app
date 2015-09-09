test = (req, res, next) ->
  console.log "call test middleware"
  req.data.test = true
  next()

module.exports = [
  test
]
