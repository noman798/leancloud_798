app = require("app")
DB = require "cloud/_db"

app.get('/rss/:host', (request, res) ->
    host = request.params.host.toLowerCase()
    query_site_name = request.query.site
    
    if request.query.site
        query_site = ".html?site=" + request.query.site
    else
        query_site = ''

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
                                
                    if query_site_name == 'xiaozhi'
                        for i in post_list
                            i.createdAt = i.createdAt.toISOString().slice(0, 19).replace('T', ' ')

                    if post_list.length
                        pubdate = post_list[0].createdAt
                    else
                        pubdate = ''

                    res.render(
                        'rss',
                        {
                            site_name: site.name
                            rss_title: site.name
                            rss_link: "http://#{site.default_host}"
                            rss_description: site.slogo
                            rss_generator: site.name_cn
                            pubdate: pubdate
                            items: post_list
                            query_site
                            query_site_name
                        }
                    )
                else
                    res.send ''
            )
    )
)

