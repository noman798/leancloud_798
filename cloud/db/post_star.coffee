$ = require "underscore"
DB = require "cloud/_db"
redis = require "cloud/_redis"
{id_b64} = require "cloud/_lib/b64"
{R} = redis
R "PostStar",":"

PAGE_LIMIT = 20
DB class PostStar
    constructor : (
        @user
        @site
        @post
        @tag_list
    )->
        super


    @is_star: (user, post_id, callback)->
        redis.sismember R.PostStar + id_b64(user.id), post_id, (err, is_star)->
            callback is_star

    @by_user: (params, options) ->
        user = params.user or AV.User.current()
        query = PostStar.$
        query.equalTo {user}
        if params.since
            query.lessThan(
                'updatedAt', new Date(params.since)
            )
        query.descending('updatedAt')
        query.limit PAGE_LIMIT
        query.include 'post'
        query.find(
            success:(star_list) ->
                post_list = []
                for i in star_list
                    post = i.get('post')
                    post.set(
                        tag_list: i.get('tag_list')
                        is_star: 1
                    )
                    post_list.push post

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
            success: (user) ->
                params.user = user
                PostStar.by_user params, options
        })

    @new : (params, options) ->
        kwds = PostStar._params_site_post(params)
        options.create = (star)->
            star.set('tag_list',[])
            PostStarCount.incr(kwds.user, kwds.site, kwds.post)

        success = options.success
        options.success = (post_star)->
            old_tag_list = post_star.get 'tag_list'
            new_tag_list = params.tag_list
            to_incr =  $.difference(new_tag_list, old_tag_list)
            to_decr =  $.difference(old_tag_list, new_tag_list)
            if to_incr.length or to_decr.length
                for tag in to_incr
                    PostStarTagCount.incr(kwds.user, kwds.site, tag)

                for tag in to_decr
                    PostStarTagCount.decr(kwds.user, kwds.site, tag)
                
                post_star.set('tag_list', new_tag_list)
                post_star.save()
            success(post_star)
        kwds.post.fetch success:(o)->
            redis.sadd R.PostStar + id_b64(kwds.user.id), o.get("ID")
            PostStar.$.get_or_create(
                kwds
                success:options.success
            )

    @rm : (params, options) ->
        query = PostStar.$
        kwds  = PostStar._params_site_post(params)
        kwds.post.fetch success:(o)->
            redis.srem R.PostStar + id_b64(kwds.user.id), o.get("ID")
            query.equalTo kwds
            query.destroyAll success:options.success
            

    @_params_site_post:(params)->
        post = AV.Object.createWithoutData(
            'Post'
            params.post_id
        )
        site = AV.Object.createWithoutData(
            'Site'
            params.site_id
        )
        {
            user:AV.User.current()
            site
            post
        }

DB class PostStarCount
    constructor : (
        @user
        @site
        @count
    )->
        super

    @incr : (user, site, post, value=1) ->
        PostStarCount.$.get_or_create({
            user
            site
        }, {
            create:(o) ->
                o.set('count', 0)
            success:(o) ->
                post.increment('star_count', value)
                post.save()

                o.increment('count', value)
                o.save()
        })

    @decr : (user, site, post) ->
        @incr user, site, post, -1

DB class PostStarTagCount
    constructor : (
        @user
        @site
        @tag
        @count
    )->
        super

    @incr : (user, site, tag, value=1) ->
        PostStarTagCount.$.get_or_create({
            user
            site
            tag
        }, {
            create:(o) ->
                o.set('count', 0)
            success:(o) ->
                o.increment('count', value)
                if o.get('count') == 0
                    o.destroy()
                else
                    o.save()
        })

    @decr : (user, site, tag) ->
        @incr user, site, tag,  -1




AV.Cloud.afterDelete 'PostStar', (request) ->
        post_star = request.object
        user = post_star.get('user')
        site = post_star.get('site')
        post = post_star.get('post')
        PostStarCount.decr(user, site, post)

        for tag in post_star.get('tag_list')
            PostStarTagCount.decr(user, site, tag)
