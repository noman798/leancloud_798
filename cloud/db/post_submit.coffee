DB = require "cloud/_db"
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
        # 如果是管理员/编辑就直接发布，否则是投稿等待审核， 如果已经存在就不重复投稿
        0

    @rm:(params, options)->
        # 管理员/编辑 或者 投稿者本人可以删除
        0

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



