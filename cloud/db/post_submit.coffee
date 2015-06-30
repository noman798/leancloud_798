DB = require "cloud/_db"

DB class PostSubmit
    constructor : (
        @site
        @post
        @publisher
    )->
        super

    @submit:(params, options)->
        # 如果是管理员/编辑就直接发布，否则是投稿等待审核， 如果已经存在就不重复投稿
        0

    @by_site:(params, options)->
        0

    @by_current:(params, options)->
        query = Post.$
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
                    result.push [
                        post
                    ]
                options.success result
        )
