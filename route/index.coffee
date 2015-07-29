app = require("app")
require "cloud/db/post"
DB = require "cloud/_db"

app.get('/:host/index/:since', (request, res) ->
    host = request.params.host.toLowerCase()
    since = request.query.since-0
    DB.Site.by_host(
        {host}
        success: (_site) ->
            if not _site
                res.status(404).send '404'
                return
            site = DB.Site(_site)

            r = [site.name]
            if site.name_cn
                r.push site.name_cn

            title = r.join(" · ")

            DB.SiteTagPost.by_site_tag(
                {
                    site_id: site.id
                    since
                },
                {
                    success: (result) ->
                        res.render('index',
                            {
                                title
                                description: _site.get('description')
                                default_host: _site.get('default_host')
                                site_favicon: _site.get('favicon')
                                baidu_code: _site.get('baidu_code')
                                li: result[0]
                                last_id: result[1]
                            }
                        )
                }
            )
    )
)

