
app = require("app")
require "cloud/db/custom_css"
DB = require "cloud/_db"

app.get '/css/:site_id', (request, res)->
    DB.CustomCss._get(request.params.site_id, (css)->
        res.send css
    )
