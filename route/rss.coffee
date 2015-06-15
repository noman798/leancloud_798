app = require("app")
DB = require "cloud/_db"

app.get('/rss/:host', (request, res) ->
    host = request.params.host.toLowerCase()
    DB.Site.by_host(
        {host}
        success:(_site) ->
            if not _site
                res.success ''
            site = DB.Site(_site)
            DB.SiteTagPost.by_site_tag({
                site_id:_site.id
            }, success:(result)->
                if result
                    [post_list,_] = result
                    if post_list.length
                        pubdate = post_list[0].get('createdAt')
                    else
                        pubdate = ''

                    res.render(
                        'rss',
                        {
                            rss_title: site.name
                            rss_link: "http://#{host}"
                            pubdate: pubdate
                            items: post_list
                        }
                    )
                else
                    res.send ''
            )
    )
)

