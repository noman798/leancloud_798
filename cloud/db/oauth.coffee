require "cloud/db/site"
require "cloud/db/sync"
DB = require "cloud/_db"
trim = require("underscore.string/trim")
#NODE_ENV = process.env.NODE_ENV || 'development'

DB class Oauth
    @KIND = {
        evernote : 1
        yinxiang : 2
    }

    @_host_by_kind : (kind)->
        #return "sandbox.evernote.com"
        if kind == DB.Oauth.KIND.evernote
            http = "www.evernote.com"
        else if kind == DB.Oauth.KIND.yinxiang
            http = "app.yinxiang.com"
        return http


    constructor:(
        @kind
        @token
        @user
        @site
        @name
        @meta
        @app_user_id
    )->
        super

    @new:(dict, callback)->
        dict.user = AV.Object.createWithoutData("_User", dict.user)
        DB.Site.by_host(
            {
                host:dict.host
            }
            success:(site)->
                delete dict['host']
                dict.site = site
                Oauth.$.get_or_create(
                    {site, kind:dict.kind, app_user_id:dict.app_user_id}
                    success:(o)->
                        o.set dict
                        o.save()
                        callback(o)
                )
        )

    @touch: (id) ->
        Oauth.$.get(id, success:(o)->
            o.save()
        )

    @by_user: (params, options) ->
        user = AV.User.current()
        ###    for test
        user = AV.Object.createWithoutData(
            '_User'
            params.user_id
        )
        ###
        query = Oauth.$
        query.equalTo('user', user)
        query.descending('updatedAt')
        query.find({
            success: (oauth_list) ->
                res_list = []
                for i in oauth_list
                    res = [i.id, i.get('kind'), i.get('name'), i.updatedAt]
                    res_list.push res
                options.success res_list
            error: (_error)->
                if _error.code == 101
                    options.success []
                else
                    console.log _error
        })

    @rm: (params, options) ->
        kwds =  oauth_id:params.id
        DB.EvernoteSync.$.rm kwds
        DB.EvernoteSyncCount.$.rm kwds
        DB.Oauth.$.rm {objectId:params.id}, options



DB class OauthSecret

    constructor: (
        @kind
        @token
        @secret
    ) ->
        super


    @new:(kind, token, secret) ->
        o = new OauthSecret()
        o.$set({
            kind
            token
            secret
        })
        o.$save()

    @by_token:(kind, token, callback)->
        OauthSecret.$.equalTo({
            token
            kind
        }).first().done (o)->
            callback(o.get('secret'))

