express    = require 'express'
logger     = require 'morgan'
bodyParser = require 'body-parser'
#routes = require 'routes/index'

xiki = require 'xiki'


app = express();

app.use logger('dev')
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use bodyParser.text()

router = express.Router()
router.get "*", xiki
app.use '/', router

app.set "view engine", "jade"

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error("Not Found")
  err.status = 404
  next(err);

# error handlers

# development error handler prints stacktrace
if app.get('env') is "development"
  app.use (err, req, res, next) ->
    res.status(err.status or 500)
    res.render 'error',
      message: err.message
      error: err

# production error handler no stacktraces
app.use (err, req, res, next) ->
  res.status(err.status or 500)
  res.render 'error',
    message: err.message
    error: {}

module.exports = app
