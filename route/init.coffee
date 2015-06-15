
require("route/rss")
require("route/oauth/evernote")


app = require('app')
if app.get('env') == 'development'
    require("route/test")
