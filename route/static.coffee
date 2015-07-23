app = require("app")
require "cloud/db/post"
DB = require "cloud/_db"

app.get('/post/:host/:post_ID', (request, res) ->
    host = request.params.host.toLowerCase()
    post_ID = request.params.post_ID
    DB.Site.by_host(
        {host}
        success:(_site) ->
            if not _site
                res.success ''
            site = DB.Site(_site)

            DB.Post.by_id({
                ID:post_ID-0    # trans to number, not str
                host:host
            }, success:(post)->
                if post
                    
                    d = post.updatedAt
                    res.render(
                        'static',
                        {
                            site_name: site.name
                            site_slogo: site.slogo
                            post_title: post.get('title')
                            post_author: post.get('author')
                            post_time: d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate()
                            post_html: post.get('html')
                        }
                    )
                else
                    res.send ''
            )
    )
)
