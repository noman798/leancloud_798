require "cloud/db/oauth"
require "cloud/db/post"
DB = require "cloud/_db"
SITE_USER_LEVEL = require("cloud/db/site_user_level")
PAGE_LIMIT = 20

redis = require "cloud/_redis"
{R} = redis
R "POST_INBOX_SUBMIT_COUNT"
R "POST_INBOX_PUBLISH_COUNT"
R "POST_INBOX_RM_COUNT"
R "USER_PUBLISH_COUNT",":"

#TODO tag_list by site
#待审核， 已退回，已发布

_post_owner = (post)->
    owner = post.get 'owner'
    if owner
        post.set 'owner',{
            id:owner.id
            username:owner.get 'username'
        }

_rm_count = (post_inbox, real_rm) ->
    site_id = post_inbox.get('site').id
    publisher = post_inbox.get('publisher')
        
    if publisher
        key = R.POST_INBOX_PUBLISH_COUNT
        owner = post_inbox.get 'owner'
        if owner
            redis.hincrby R.USER_PUBLISH_COUNT+site_id, owner.id, -1
    else
        if real_rm
            if post_inbox.get 'rmer'
                key = R.POST_INBOX_RM_COUNT
            else
                key = R.POST_INBOX_SUBMIT_COUNT
        else
            key = R.POST_INBOX_SUBMIT_COUNT
    redis.hincrby key, site_id, -1

DB.Post.EVENT.on "rm",(post)->
    owner = post.get 'owner'
    if owner
        redis.hincrby R.USER_POST_COUNT, owner.id, -1
    q = DB.SiteTagPost.$
    q.equalTo({post})
    q.destroyAll()
    DB.PostInbox.$.equalTo({
        post
    }).find().done (post_inbox_list)->
        for post_inbox in post_inbox_list
            _rm_count post_inbox,1
            post_inbox.destroy()
    

DB class PostInbox
    constructor : (
        @site
        @post
        @owner
        @publisher
        @rmer
    )->
        super
   

    @by_current:(params, options)->    # user current
        params.owner_id = AV.User.current().id
        PostInbox._by_user(params, options)
    
    @by_site_rmed:(params, options)->
        params.rm = 1
        PostInbox.by_site(params, options)

    @by_current_published:(params, options)->    # user published
        params.owner_id = AV.User.current().id
        params.publish = 1
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
                key = "PUBLISH"
                query.exists "publisher"
            else
                key = "SUBMIT"
                query.doesNotExist "publisher"
            query.doesNotExist 'rmer'

        if params.owner_id
            owner = AV.Object.createWithoutData('User', params.owner_id)
            query.equalTo "owner", owner

        if params.since
            query.lessThan('ID', params.since)

        query.descending('ID')
        query.include(["post.owner"])
        query.limit PAGE_LIMIT
        query.find(
            success:(post_inbox_list)->
                result = []

                _set_tag_list = (post) ->
                    q = DB.SiteTagPost.$
                    q.equalTo({post})
                    q.first({
                        success: (site_tag_post) ->
                            if site_tag_post
                                tag_list = site_tag_post.get('tag_list')
                                if tag_list and tag_list.length
                                    post.set('tag_list', tag_list)
                    })

                for i in post_inbox_list
                    post = i.get 'post'
                    if not post
                        i.destroy()
                        continue
                    _post_owner post
                    post.set "is_submit", 1

                    #方便前端显示退稿人
                    rmer = i.get 'rmer'
                    if rmer
                        post.set 'rmer',rmer

                    publisher = i.get 'publisher'
                    if publisher
                        post.set 'publisher', publisher
                    _set_tag_list(post)
                    result.push post

                redis.hget(R["POST_INBOX_#{key}_COUNT"], params.site_id, (err, count) ->
                    options.success [count or 0, result]
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
                exist = {}
                for each_oauth in oauth_list
                    site_name = each_oauth.get('site').get('name')
                    if site_tag_list.indexOf(site_name.toLowerCase())>=0
                        site_id = each_oauth.get('site').id
                        if site_id of exist
                            continue
                        exist[site_id]=1
                        PostInbox._submit(
                            user
                            {
                                site_id
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
        {site_id} = params
        DB.Post.$.get(params.post_id).done (post)->
            PostInbox._post_set post, params
            data = PostInbox._get params, (o, is_new)->
                if is_new
                    redis.hincrby R.POST_INBOX_SUBMIT_COUNT, site_id, 1
                else
                    if o.get('publisher') or o.get('rmer')
                        redis.hincrby R.POST_INBOX_SUBMIT_COUNT, site_id, 1

                    if o.get 'publisher'
                        o.unset 'publisher'
                        redis.hincrby R.POST_INBOX_PUBLISH_COUNT,  site_id, -1
                        redis.hincrby R.USER_PUBLISH_COUNT+site_id,  site_id, -1

                    if o.get 'rmer'
                        o.unset 'rmer'
                        redis.hincrby R.POST_INBOX_RM_COUNT, site_id, -1

                    o.save()
                    DB.SiteTagPost.$.equalTo(data).destroyAll()

        options.success ''


    @_publish:(user, params, options)->
        {site_id}=params
        data = PostInbox._get params,(o, is_new)->
            DB.SiteUserLevel._level user.id, site_id,(level)->
                if level < SITE_USER_LEVEL.WRITER
                    options.success ''
                    return
                o.get('post').fetch (post)->
                    console.log "publish is new", is_new
                    if (not o.get('publisher')) or o.get('rmer')
                        if not is_new
                            if o.get 'rmer'
                                key = R.POST_INBOX_RM_COUNT
                            else
                                key = R.POST_INBOX_SUBMIT_COUNT
                            redis.hincrby key, params.site_id, -1
                        redis.hincrby R.POST_INBOX_PUBLISH_COUNT,  params.site_id, 1
                        owner =  post.get 'owner'
                        if owner
                            redis.hincrby R.USER_PUBLISH_COUNT+site_id, owner.id, 1
                    PostInbox._post_set post, params
                    DB.SiteTagPost.$.get_or_create(
                        data
                        success:(site_tag_post)->
                            site_tag_post.set 'tag_list', params.tag_list or post.get('tag_list')
                            site_tag_post.save()
                    )
                    o.unset 'rmer'
                    o.set 'publisher', AV.User.current()
                    o.save()
        options.success ''

    @publish:(params, options)->
        PostInbox._publish AV.User.current(), params, options

    @_submit:(submiter, params, options)->
        # 如果已经存在就不重复投稿
        PostInbox._get params, (o, is_new)->
            if o.get 'rmer'
                is_new = 1
                o.unset 'rmer'
                o.save()
            DB.SiteUserLevel._level submiter.id, params.site_id,(level)->
                # 如果是管理员/编辑就直接发布，否则是投稿等待审核
                if level >= SITE_USER_LEVEL.WRITER
                    PostInbox._publish submiter,params, options
                else
                    if is_new
                        redis.hincrby R.POST_INBOX_SUBMIT_COUNT, params.site_id, 1
                    options.success ''

    @submit:(params, options)->
        PostInbox._submit(AV.User.current(),params, options)

    @rm:(params, options)->
        # 管理员/编辑 或者 投稿者本人可以删除
        data = {
            site : AV.Object.createWithoutData("Site", params.site_id)
            post : AV.Object.createWithoutData("Post", params.post_id)
        }
        #DB.PostInbox.$.find(params).first().done (post_inbox)->
        DB.PostInbox.$.equalTo(data).first().done (post_inbox)->
            if post_inbox and not post_inbox.get 'rmer'
                post_inbox.get('post').fetch (post)->
                    PostInbox._post_set post, params

                    current = AV.User.current()

                    _count = ->
                        _rm_count post_inbox
                        DB.SiteTagPost.$.equalTo(data).destroyAll()
                    owner = post.get('owner')
                    if (not owner) or owner.id == current.id
                        post_inbox.destroy()
                        _count()
                    else
                        DB.SiteUserLevel._level_current_user params.site_id,(level)->
                            if level >= SITE_USER_LEVEL.EDITOR
                                post_inbox.set 'rmer', current
                                post_inbox.save(
                                    success:->
                                        _count()
                                        redis.hincrby R.POST_INBOX_RM_COUNT, params.site_id, 1
                                    error:(err)->
                                        console.log err
                                )

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
        query.doesNotExist "rmer"
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

                    redis.hget(R.USER_POST_COUNT, params.owner_id, (err, count)->
                        options.success [count or 0, post_list]
                    )

        )
