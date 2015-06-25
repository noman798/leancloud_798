global.AV = require('leanengine')

APP_ID = process.env.LC_APP_ID
APP_KEY = process.env.LC_APP_KEY
MASTER_KEY = process.env.LC_APP_MASTER_KEY

AV.initialize(APP_ID, APP_KEY, MASTER_KEY)
AV.Cloud.useMasterKey()

require('rootpath')()
require("cloud/_redis")
require('cloud/init')
require('route/init')
app = require('app')
app.use AV.Cloud


cookieParser = require('cookie-parser')
bodyParser = require('body-parser')


app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(cookieParser())

app.use (req, res, next) ->
    err = new Error('Not Found')
    err.status = 404
    next err
    return


if app.get('env') == 'development'
    require 'test'
    app.use (err, req, res, next) ->
        res.status err.status or 500
        res.render 'error',
          message: err.message
          error: err
        return
# 如果是非开发环境，则页面只输出简单的错误信息
app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render 'error',
        message: err.message
        error: {}
    return




PORT = parseInt(process.env.LC_APP_PORT || 3000)
server = app.listen(PORT,->
    console.log('Node app is running, port:', PORT)
)


