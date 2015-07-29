app = require("app")
require "cloud/db/post"
marked = require('marked')
DB = require "cloud/_db"

marked.setOptions({
    renderer: new marked.Renderer()
    breaks: true
    sanitize: true
})

app.get('/post/:host/:post_ID', (request, res) ->
    host = request.params.host.toLowerCase()
    post_ID = request.params.post_ID
    query_site = request.query.site
    DB.Site.by_host(
        {host}
        success:(_site) ->
            if not _site
                res.status(404).send '404'
                return
            site = DB.Site(_site)

            DB.Post.by_id({
                ID:post_ID-0    # trans to number, not str
                host:host
            }, success:(post)->
                if post
                    DB.PostTxt.by_post({
                        post_id: post.id
                        site_id: site.id
                    }, success: (post_txt_list) ->
                            for i in post_txt_list
                                i.txt = marked(i.txt)
                            d = post.updatedAt
                            res.render(
                                'static',
                                {
                                    query_site: query_site
                                    site_name: site.name
                                    site_slogo: site.slogo
                                    site_favicon: _site.get('favicon')
                                    default_host: _site.get('default_host')
                                    baidu_code: _site.get('baidu_code')

                                    post_ID: post_ID
                                    post_title: post.get('title')
                                    post_author: post.get('author')
                                    post_time: d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate()
                                    post_html: post.get('html')
                                    post_txt: post_txt_list
                                }
                            )
                            
                )
                else
                    res.status(404).send '404'
            )
    )
)
