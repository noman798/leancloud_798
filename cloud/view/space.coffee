require "cloud/db/site"
require "cloud/db/post"
require "cloud/db/oauth"
require "cloud/db/site_user_level"
qiniu_token = require "cloud/db/qiniu_token"
DB = require "cloud/_db"
View = require "cloud/_view"

View class Space


    qiniu_token:(request, response)->
        response.success(
            qiniu_token( request.params.returnBody or undefined)
        )

    post_by_tag:(request,response)->
        params = request.params
        if params.tag
            params.tag_list = params.tag
        delete params.tag

        DB.SiteTagPost.by_site_tag(
            params
            {
                success:(params...)->
                    response.success.apply response, params
            }
        )


    by_host:(request,response)->
        params = request.params
        DB.Site.by_host(
            {host:params.host}
            success:(_site) ->
                if not _site
                    return response.error({})
                site = DB.Site(_site)
                DB.SiteUserLevel._level_current_user _site.id, (level)->
                    response.success(
                        [
                            site.id
                            site.name
                            site.name_cn
                            site.tag_list
                            site.logo
                            site.slogo
                            site.link_list
                            level
                        ]
                    )

            error: response.error
        )

    by_id:(request,response)->
        params = request.params
        DB.Site.by_host(
            {id:params.id}
            success:(_site) ->
                if not _site
                    return response.error({})
                site = DB.Site(_site)

                kwds = {
                    site:_site
                    page:1
                }
                DB.SiteTagPost.by_site_tag(kwds, success:(post_list, count)->
                    response.success(
                        [
                            site.id
                            site.name
                            site.tag_list
                            post_list,
                            count
                        ]
                    )
                )

            error: response.error
        )
