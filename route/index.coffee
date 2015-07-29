app = require("app")
require "cloud/db/post"
DB = require "cloud/_db"

app.get('/:host/:since/index', (request, res) ->
    host = request.params.host.toLowerCase()
    since = request.query.since
    DB.Site.by_host(
        {host}
        success: (_site) ->
            if not _site
                res.send '404'
                return
            site = DB.Site(_site)
            title = [site.name , site.name_cn].join(" · ")

            DB.SiteTagPost.by_site_tag(
                {site_id: site.id, since}, {
                success: (result) ->
                    res.render('index',
                        {
                            title
                            description: _site.get('description')
                            default_host: _site.get('default_host')
                            li: result[0]
                            last_id: result[1]
                        }
                    )
                }
            )
    )
)
