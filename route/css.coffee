
app = require("app")
require "cloud/db/custom_css"
DB = require "cloud/_db"

app.get '/css/:site_id', (request, res)->
    DB.CustomCss._get(site_id, (css)->
        res.send css
    )
