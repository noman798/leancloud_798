require "cloud/db/site_tag_post_count"
require "cloud/db/user_read"
{EventEmitter} = require 'events'
_post_is_star = require "cloud/db/_post_is_star"
SITE_USER_LEVEL = require "cloud/db/site_user_level"
DB = require "cloud/_db"
View = require "cloud/_view"

redis = require "cloud/_redis"
{R} = redis
R "USER_POST_COUNT"

PAGE_LIMIT = 20

DB class SiteTagPost
    constructor : (
        @tag_list
        @site
        @post
    )->
        super

    @by_site_tag:(params, options)->
        user = AV.User.current()
        params.site = AV.Object.createWithoutData("Site", params.site_id)
        delete params.site_id

        query = SiteTagPost.$
        if params.since
            query.lessThan('ID', params.since)
            delete params.since
        query.equalTo(params)
        query.descending('ID')
        query.limit PAGE_LIMIT
        query.include 'post'
        query.include 'post.owner'
        query.find(
            success:(site_tag_list)->
                post_list = []

                for i in site_tag_list
                    post = i.get('post')
                    post.set 'tag_list', i.get('tag_list')
                    post_list.push post
                    owner = post.get 'owner'
                    if owner
                        post.set 'owner', {
                            id:owner.id
                            username:owner.get 'username'
                        }
                success = (li)->
                    if site_tag_list.length >= PAGE_LIMIT
                        last_id = site_tag_list[site_tag_list.length-1].get 'ID'
                    else
                        last_id = 0
                    options.success [li, last_id]
                _post_is_star post_list, success
        )


DB class Post
    @KIND :
        HTML : 10
        TXT : 20

    constructor : (
        @owner
        @kind
    )->
        super
   
    @EVENT = new EventEmitter
    
    @rm : View.logined (params, options) ->
        query = Post.$
        query.include 'post'
        query.get(params.id, {
            success:(o) ->
                owner = o.get('owner')
                current = AV.User.current()
                _rm = ->
                    o.set('rmer', current)
                    o.save()
                    Post.EVENT.emit 'rm', o

                if owner and owner.id == current.id
                    _rm()
                else
                    post = o.get('post')
                    if post
                        owner = post.get 'owner'
                        if owner and owner.id == current.id
                            _rm()
                        else
                            DB.SiteUserLevel._level_current_user params.site_id, (level)->
                                if level >= SITE_USER_LEVEL.EDITOR
                                    _rm()


                options.success('')
        })

    @by_id: (params, options) ->
        DB.Site.by_host(
            {host:params.host}
            {
                success:(site)->
                    user = AV.User.current()
                    query = Post.$
                    query.equalTo("ID", params.ID)
                    query.first {
                        success:(post) ->
                            if post
                                post.set('site_id',site.id)
                                DB.PostStar.is_star(
                                    user
                                    params.ID
                                    (is_star)->
                                        if is_star
                                            post.set('is_star', 1)
                                        options.success post
                                )
                            else
                                options.success 0
                    }
            }
        )


DB class PostTxt extends Post
    constructor : (
        @owner
        @kind

        @txt
        @refer
        @rmer
        @post
    )->
        super

    @new : View.logined (params, options) ->
        post = AV.Object.createWithoutData(
            'Post'
            params.post_id
        )
        owner = AV.User.current()
        if params.txt
            post.increment('reply_count')
            post.save().done ->
                post_txt = DB.PostTxt {
                    owner
                    kind:Post.KIND.TXT
                    txt:params.txt
                    post
                }
                post_txt.$setACL()
                post_txt.$save success:options.success
        else
            options.success()


    @by_post : (params, options) ->

        post = AV.Object.createWithoutData(
            'Post'
            params.post_id
        )
        query = PostTxt.$
        query.equalTo {post}
        query.include 'owner'
        query.include 'rmer'
        query.ascending 'createdAt'
        query.find (
            success:(post_list) ->
                result = []
                for i in post_list
                    owner = i.get 'owner'
                    rmer = i.get 'rmer'
                    o = {
                        owner : [
                            owner.id
                            owner.get('username')
                        ]
                        createdAt:i.createdAt
                        id:i.id
                    }
                    if rmer
                        o.rmer = rmer.get 'username'
                    else
                        o.txt = i.get 'txt'

                    result.push o

                options.success(result)
                DB.UserRead.begin(params.site_id, params.post_id)
        )

    
DB class PostHtml extends Post
    constructor : (
        @owner
        @kind

        @title
        @html
        @brief
        @author
        @image
        @link
        @reply_count
        @star_count
        @tag_list
    )->
        super


    @new : (params, options) ->
        _ = (blog)->
            changed = 0
            for k,v of params
                if k == 'owner'
                    if v.id != blog.owner.id
                        changed = 1
                        break
                else if v != blog[k]
                    changed = 1
                    break
            if changed
                blog.$set params
                blog.$save success:options.success
            else
                options.success blog.$

        id = params.id #id maybe is 0
        delete params.id
        if id
            Post.$.get(
                id
                success:(post)->
                    post = new DB.Post post
                    _ post
            )
        else
            params.kind = Post.KIND.HTML
            params.owner = owner = params.owner or AV.User.current()
            blog = new PostHtml()
            blog.$setACL()
            _ blog

            if owner
                redis.hincrby R.USER_POST_COUNT, owner.id, 1

DB class PostChat extends Post
    @new : (params, options) ->
        params.owner = AV.User.current()

    constructor: (
        @owner
        @txt
    )->
        super

