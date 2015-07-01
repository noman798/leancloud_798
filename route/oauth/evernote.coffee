require "cloud/db/oauth"
require "cloud/db/sync"
DB = require "cloud/_db"

app = require("app")
OAuth = require('oauth')
CONFIG = require('cloud/config')


Evernote = require('evernote').Evernote
_sync_username = (token, callback)->
    client = new Evernote.Client({token})
    store = client.getUserStore()
    store.getUser (err, user) ->
        name = '未知'
        if not err
            name = user.username
        callback name


app.get('/oauth/:oauthstr/:host/:user_id', (request, response) ->
    host = request.params.host.toLowerCase()
    http = "https://sandbox.evernote.com/"
    evernote_url = request.params.oauthstr
    kind = DB.Oauth.KIND[evernote_url]

    query = request.query
    oauth = new OAuth.OAuth(
        http+'oauth',
        http+'oauth',
        CONFIG.EVERNOTE.KEY,
        CONFIG.EVERNOTE.SECRET,
        '1.0A',
        "#{request.protocol}://#{request.headers.host}/oauth/#{evernote_url}/#{host}/#{request.params.user_id}",
        'HMAC-SHA1'
    )

    if query.oauth_token and query.oauth_verifier
        DB.OauthSecret.by_token(
            kind
            query.oauth_token
            (oauth_token_secret) ->
                oauth.getOAuthAccessToken(
                    query.oauth_token
                    oauth_token_secret
                    query.oauth_verifier
                    (error, oauth_access_token, oauth_access_token_secret, result) ->
                        if error
                            return response.send error
                        _sync_username(oauth_access_token, (name)->
                            DB.Oauth.new(
                                {
                                    user:request.params.user_id
                                    kind
                                    token:oauth_access_token
                                    host
                                    name
                                    app_user_id:result.edam_userId
                                    meta : {
                                        store_url:result.edam_noteStoreUrl
                                        shard:result.edam_shard
                                        expire:(result.edam_expires-0)
                                        api_url:result.edam_webApiUrlPrefix
                                    }
                                }
                                (o)->
                                    response.redirect "http://#{host}/-minisite/bind!\"#{o.id}\""
                            )
                        )
                )
        )

    else
        oauth.getOAuthRequestToken (
            error, oauth_token, oauth_token_secret, result
        )->
            DB.OauthSecret.new(
                kind
                oauth_token
                oauth_token_secret
            )
            if not error
                response.redirect(
                    http+"OAuth.action?oauth_token="+oauth_token
                )
            else
                response.send error
    )

app.get('/webhook/evernote', (request, response) ->
    {userId, guid} = request.query
    query = DB.Oauth.$
    query.equalTo('app_user_id', userId)
    query.first(
        success: (oauth) ->
            DB.EvernoteSync.sync(
                {id:oauth.id}
                {
                    success: (o) ->
                        0
                }
            )
    )
    response.send ''



)
