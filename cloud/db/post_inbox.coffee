require "cloud/db/oauth"
require "cloud/db/post"
DB = require "cloud/_db"
SITE_USER_LEVEL = require("cloud/db/site_user_level")
PAGE_LIMIT = 20
#TODO tag_list by site
#待审核， 已退回，已发布


DB class PostInbox
    constructor : (
        @site
        @post
        @owner
        @publisher
        @rmer
    )->
        super
    
    @by_current_published:(params, options)->
        params.owner_id = AV.User.current().id
        PostInbox.by_site(params, options)

    @by_current:(params, options)->
        params.owner_id = AV.User.current().id
        PostInbox._by_user(params, options)
    
    @by_site:(params, options)->
        query = DB.PostInbox.$
        query.equalTo "site", AV.Object.createWithoutData("Site", params.site_id)
        if query.rmer
            query.notEqualTo "rmer", null
        else
            if query.publisher
                query.notEqualTo "publisher", null
            else
                query.equalTo "publisher", null

        if params.owner_id
            owner = AV.Object.createWithoutData('User', params.owner_id)
            query.equalTo "owner", owner

        if params.since
            query.lessThan('ID', params.since)
        query.descending('ID')
        query.limit PAGE_LIMIT
        query.find(
            success:(post_list)->
                result = []
                for i in post_list
                    query = DB.PostInbox.$
                    query.equalTo({
                        post
                    })
                    result.push query.first()
                AV.Promise.when(result).done (post_submit)->
                    console.log post_submit
        )


    @_get: (params, callback)->
        data = {
            site : AV.Object.createWithoutData("Site", params.site_id)
            post : AV.Object.createWithoutData("Post", params.post_id)
        }
        DB.Post.$.get(params.post_id).done (post)->
            data.owner = post.get('owner')
            PostInbox.$.get_or_create(
                data
                {
                    success:callback
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


    @publish:(params, options)->
        #管理员发布的时候可以设置标签
        data = PostInbox._get params,(o)->
            DB.SiteUserLevel._level_current_user params.site_id,(level)->
                if level < SITE_USER_LEVEL.WRITER
                    return
                o.get('post').fetch (post)->
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
        PostInbox._get params, (o)->
            if o.get 'rmer'
                o.unset 'rmer'
                o.save()
            DB.SiteUserLevel._level_current_user params.site_id,(level)->
                # 如果是管理员/编辑就直接发布，否则是投稿等待审核
                if level >= SITE_USER_LEVEL.WRITER
                    PostInbox.publish {
                        params
                    }, options
                else
                    options.success ''


    @rm:(params, options)->
        # 管理员/编辑 或者 投稿者本人可以删除
        PostInbox._get (o)->
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
                        r = {is_submit:!!i.updatedAt-0}
                        
                        publisher = i.get 'publisher'
                        if publisher
                            r.is_publish = 1

                        post_dict[i.get('post').id] = r
                        for i in post_list
                            if i.id of post_dict
                                i.set post_dict[i.id]
                        options.success post_list
        )

