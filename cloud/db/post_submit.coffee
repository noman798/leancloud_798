DB = require "cloud/_db"
SITE_USER_LEVEL = require("cloud/db/site_user_level")
PAGE_LIMIT = 20
#待审核， 已退回，已发布
DB class PostSubmit
    constructor : (
        @site
        @post
        @publisher
        @rmer
    )->
        super

    @publish:(params, options)->
        0
        #管理员发布的时候可以设置标签

    @submit:(params, options)->
        # 如果已经存在就不重复投稿
        PostSubmit.get_or_create(
            {
                post : AV.Object.createWithoutData("Post", params.post_id)
                site : AV.Object.createWithoutData("Site", params.site_id)
            }
            {
                success:(o)->
                    if o.get 'rmer'
                        o.unset 'rmer'
                        o.save()

                    DB.SiteUserLevel._level_current_user params.site_id,(level)->
                        # 如果是管理员/编辑就直接发布，否则是投稿等待审核
                        if level >= SITE_USER_LEVEL.WRITER
                            PostSubmit.publish {
                                params
                            }, options
                        else
                            options.success ''
            }
        )


    @rm:(params, options)->
        # 管理员/编辑 或者 投稿者本人可以删除
        data = {
            post : AV.Object.createWithoutData("Post", params.post_id)
            site : AV.Object.createWithoutData("Site", params.site_id)
        }
        PostSubmit.get_or_create(
            data
            {
                success:(o)->
                    if o
                        if not o.rmer
                            o.get('post').fetch (post)->
                                current = AV.User.current()
                                if post.get('owner').id == current.id
                                    o.destroy()
                                else
                                    DB.SiteUserLevel._level_current_user params.site_id,(level)->
                                        if level >= SITE_USER_LEVEL.EDITOR
                                            o.set 'rmer',current
                                            o.save()
                    options.success ''
            }
        )

    @by_site:(params, options)->
        query = DB.PostSubmit.$
        query.equalTo "site", AV.Object.createWithoutData("Site", params.site_id)
        if query.rmer
            query.notEqualTo "rmer", null
        else
            if query.publisher
                query.notEqualTo "publisher", null
            else
                query.equalTo "publisher", null
        if params.since
            query.lessThan('ID', params.since)
        query.descending('ID')
        query.limit PAGE_LIMIT
        query.find(
            success:(post_list)->
                result = []
                for i in post_list
                    query = DB.PostSubmit.$
                    query.equalTo({
                        post
                    })
                    result.push query.first()
                AV.Promise.when(result).done (post_submit)->
                    console.log post_submit
        )

    @by_current:(params, options)->
        query = DB.Post.$
        query.equalTo(
            owner:AV.User.current()
            kind:params.kind or Post.KIND.HTML
        )
        if params.since
            query.lessThan('ID', params.since)
        query.descending('ID')
        query.limit PAGE_LIMIT
        query.find(
            success:(post_list)->
                result = []
                for i in post_list
                    query = DB.PostSubmit.$
                    query.equalTo({
                        post
                    })
                    result.push query.first()
                AV.Promise.when(result).done (post_submit)->
                    console.log post_submit
        )



