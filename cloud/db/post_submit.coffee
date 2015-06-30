
require "cloud/db/site_tag_post_count"
require "cloud/db/user_read"



DB class PostSubmit
    constructor : (
        @site
        @post
    )->
        super

    @by_site
    @by_self:(params, options)->
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
