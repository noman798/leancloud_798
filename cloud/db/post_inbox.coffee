require "cloud/db/oauth"
require "cloud/db/post"
DB = require "cloud/_db"
SITE_USER_LEVEL = require("cloud/db/site_user_level")
PAGE_LIMIT = 4

redis = require "cloud/_redis"
{R} = redis
R "POST_INBOX_SUBMIT_COUNT"
R "POST_INBOX_PUBLISH_COUNT"
R "POST_INBOX_RM_COUNT"
R "USER_PUBLISH_COUNT"

#TODO tag_list by site
#待审核， 已退回，已发布

_post_owner = (post)->
    owner = post.get 'owner'
    post.set 'owner',{
        id:owner.id
        username:owner.get 'username'
    }

DB class PostInbox
    constructor : (
        @site
        @post
        @owner
        @publisher
        @rmer
    )->
        super
   

    @by_current:(params, options)->
        params.owner_id = AV.User.current().id
        PostInbox._by_user(params, options)
    
    @by_site_rmed:(params, options)->
        params.rm = 1
        PostInbox.by_site(params, options)

    @by_current_published:(params, options)->
        params.owner_id = AV.User.current().id
        params.publisher = 1
        PostInbox.by_site(params, options)

    @by_site_published:(params, options)->
        params.publish = 1
        PostInbox.by_site(params, options)

    @by_site:(params, options)->
        query = DB.PostInbox.$
        query.equalTo "site", AV.Object.createWithoutData("Site", params.site_id)
        if params.rm
            query.exists "rmer"
            key = "RM"
        else
            if params.publish
                key = "PULISH"
                query.exists "publisher"
            else
                key = "SUBMIT"
                query.doesNotExist "publisher"

        if params.owner_id
            owner = AV.Object.createWithoutData('User', params.owner_id)
            query.equalTo "owner", owner

        if params.since
            query.lessThan('ID', params.since)

        query.descending('ID')
        query.include("post.owner")
        query.limit PAGE_LIMIT
        query.find(
            success:(post_inbox_list)->
                result = []
                for i in post_inbox_list
                    post = i.get 'post'
                    _post_owner post
                    post.set "is_submit", 1
                    publisher = i.get 'publisher'
                    if publisher
                        post.set 'publisher', publisher
                    result.push post

                redis.hget(R["POST_INBOX_#{key}_COUNT"], params.site_id, (err, count) ->
                    options.success [count, result]
                )
        )

    @_get: (params, callback)->
        data = {
            site : AV.Object.createWithoutData("Site", params.site_id)
            post : AV.Object.createWithoutData("Post", params.post_id)
        }
        is_new = false
        DB.Post.$.get(params.post_id).done (post)->
            data.owner = post.get('owner')
            PostInbox.$.get_or_create(
                data
                {
                    create:(post_inbox)->
                        is_new = true
                    success:(post_inbox)->
                        callback(post_inbox, is_new)
                }
            )
        data

    @_submit_by_evernote:(user, post, site_tag_list)->
        post_id = post.id
        #通过Oauth查找用户user_id绑定的所有站点可以通过 include site来获取这些站点的名称
        #遍历站点名toLowerCase，如site_tag_list存在，那么就发布此文章（注意同步post.tag_list）
        query = DB.Oauth.$
        query.include('site')
        query.equalTo('user', user)
        query.find({
            success: (oauth_list) ->
                for each_oauth in oauth_list
                    site_name = each_oauth.get('site').get('name')
                    if site_tag_list.indexOf(site_name.toLowerCase())>=0
                        PostInbox.submit({
                            site_id : each_oauth.get('site').id
                            owner:post.get 'owner'
                            post_id
                        }, {
                            success:(o) ->
                                0
                        })

        })

    @_post_set: (post, {tag_list, title, brief})->
        post.set({tag_list, title, brief})
        post.save()

    @save:(params, options)->
        DB.Post.get(params.post_id).done (post)->
            PostInbox._post_set post, params
    
    @publish:(params, options)->
        #管理员发布的时候可以设置标签
        data = PostInbox._get params,(o, is_new)->
            DB.SiteUserLevel._level_current_user params.site_id,(level)->

                if level < SITE_USER_LEVEL.WRITER
                    return
                o.get('post').fetch (post)->

                    if not o.get 'publisher'
                        if not is_new
                            if o.get 'rmer'
                                key = R.POST_INBOX_RM_COUNT
                            else
                                key = R.POST_INBOX_SUBMIT_COUNT
                            redis.hincrby key, params.site_id, -1
                        redis.hincrby R.POST_INBOX_PUBLISH_COUNT,  params.site_id, 1
                        redis.hincrby R.USER_PUBLISH_COUNT, post.get('owner').id, 1

                    PostInbox._post_set post, params
                    DB.SiteTagPost.$.get_or_create(
                        data
                        (site_tag_post)->
                            site_tag_post.set 'tag_list', params.tag_list or post.get('tag_list')
                            site_tag_post.save()
                    )

                    o.set 'publisher', AV.User.current()
                    o.save()
        options.success ''

    @submit:(params, options)->
        # 如果已经存在就不重复投稿
        PostInbox._get params, (o, is_new)->
            if o.get 'rmer'
                is_new = 1
                o.unset 'rmer'
                o.save()
            DB.SiteUserLevel._level_current_user params.site_id,(level)->
                # 如果是管理员/编辑就直接发布，否则是投稿等待审核
                if level >= SITE_USER_LEVEL.WRITER
                    PostInbox.publish {
                        params
                    }, options
                else
                    if is_new
                        redis.hincrby R.POST_INBOX_SUBMIT_COUNT, site_id
                    options.success ''


    @rm:(params, options)->
        # 管理员/编辑 或者 投稿者本人可以删除
        data = {
            site : AV.Object.createWithoutData("Site", params.site_id)
            post : AV.Object.createWithoutData("Post", params.post_id)
        }
        DB.PostInbox.$.find(params).first().done (post_inbox)->
            if post_inbox and not post_inbox.get 'rmer'
                post_inbox.get('post').fetch (post)->
                    PostInbox._post_set post, params

                    current = AV.User.current()

                    _count = ->
                        if post_inbox.get 'publisher'
                            key = R.POST_INBOX_PUBLISH_COUNT
                        else
                            key = R.POST_INBOX_SUBMIT_COUNT

                        redis.hincrby key, params.site_id, -1

                    if post.get('owner').id == current.id
                        o.destroy()
                        _count()
                    else
                        DB.SiteUserLevel._level_current_user params.site_id,(level)->
                            if level >= SITE_USER_LEVEL.EDITOR
                                o.set 'rmer',current
                                o.save()
                                _count()
                                redis.hincrby R.POST_INBOX_RM_COUNT, params.site_id, 1
            options.success ''


    @_by_user:(params, options)->
        query = DB.Post.$
        owner = AV.Object.createWithoutData('User', params.owner_id)
        site = AV.Object.createWithoutData('Site', params.site_id)
        query.equalTo(
            owner:owner
            kind:params.kind or DB.Post.KIND.HTML
        )
        if params.since
            query.lessThan('ID', params.since)
        query.descending('ID')
        query.limit PAGE_LIMIT
        query.include 'owner'
        query.find(
            success:(post_list)->
                result = []
                 
                for post in post_list
                    q = PostInbox.$
                    q.equalTo('post',post)
                    q.equalTo('site',site)
                    result.push q.first()

                AV.Promise.when(result).done (post_submit_list...)->
                    post_dict = {}
                    for i in post_submit_list
                        if i
                            r = {is_submit:1}
                            
                            publisher = i.get 'publisher'
                            if publisher
                                r.publisher = publisher

                            post_dict[i.get('post').id] = r
                    for i in post_list
                        if i.id of post_dict
                            i.set post_dict[i.id]
                        _post_owner i

                    if params.publisher
                        key = "PUBLISH"
                    else
                        key = "POST"
                    redis.hget(R["USRE_#{key}_COUNT"], params.owner_id, (err, count)->
                        options.success [count, post_list]
                    )
        )
