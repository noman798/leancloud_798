require "cloud/db/site"
DB = require "cloud/_db"

DB class Oauth
    @KIND = {
        evernote : 1
        yinxiang : 2
    }

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

