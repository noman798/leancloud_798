_post_is_star = require "cloud/db/_post_is_star"
_set_tag_list = require "cloud/db/_set_tag_list"
DB = require "cloud/_db"
PAGE_LIMIT = 20

DB class UserReadCount
    constructor: (
        @user
        @site
        @count
    ) ->
        super

    @incr:(user, site) ->
        UserReadCount.$.get_or_create(
            {user, site}
            create: (o)->
                o.set(count:0)
            success: (o)->
                o.increment('count')
                o.save()
        )

DB class UserRead
    constructor: (
        @user
        @post
        @site
        @duration
    ) ->
        super
    
    @end: (params, options) ->
        UserRead._get_or_create(
            params
            (o)->
                diff_time = (
                    (new Date()).getTime() - o.updatedAt.getTime()
                )/1000
                
                if diff_time > 180
                    diff_time = 180
                
                duration = (o.get('duration') or 0) + diff_time

                if duration > 600
                    duration = 600
                
                o.set('duration', duration)
                o.save success:options.success
        )

    @_get_or_create:(params, success)->
        user = AV.User.current()
        post = AV.Object.createWithoutData(
            'Post'
            params.post_id
        )
        site = AV.Object.createWithoutData(
            'Site'
            params.site_id
        )
        UserRead.$.get_or_create({
            user
            post
            site
        }, {
            create:->
                UserReadCount.incr(user, site)
            success: success
        })

    @begin: (site_id, post_id) ->
        user = AV.User.current()
        if user
            UserRead._get_or_create(
                {
                    site_id
                    post_id
                }
                (o)->
                    o.set('duration', o.get('duration') or 0)
                    o.save()
            )

    @by_user: (params, options) ->
        user = params.user or AV.User.current()
        query = UserRead.$
        site = AV.Object.createWithoutData(
            'Site'
            params.site_id
        )
        if params.since
            query.lessThan('updatedAt', params.since)
        query.equalTo {user, site}
        query.descending('updatedAt')
        query.include 'post'
        query.limit PAGE_LIMIT
        query.find(
            success:(read_list) ->
                post_list = []
                for i in read_list
                    post_list.push i.get('post')

                _post_is_star post_list, ->
                    _set_tag_list site, post_list, ->
                        if post_list.length >= PAGE_LIMIT
                            last_id = post_list[post_list.length-1].updatedAt
                            options.success [post_list, last_id]
                        else
                            options.success [post_list, 0]

        )


    @by_username: (params, options) ->
        query_user = new AV.Query(AV.User)
        query_user.equalTo("username", params.username)
        query_user.first({
            success:(user)->
                params.user = user
                UserRead.by_user params, options
        })
