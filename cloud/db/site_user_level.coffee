USER = require "cloud/db/user"
DB = require "cloud/_db"
redis = require "cloud/_redis"
{R} = redis
R "SITE_USER_LEVEL",":"
{id_bin,bin_id} = require "cloud/_lib/b64"

module.exports = SITE_USER_LEVEL =
    ROOT : 1000     #管理员，可以管理团队成员
    EDITOR : 900    #可以审核投稿
    WRITER : 800    #投稿可以自动发布


DB class SiteUserLevel
    @_set : (user_id, site_id, level) ->
        key = R.SITE_USER_LEVEL+site_id
        user_id = id_bin user_id
        if level
            if SITE_USER_LEVEL_VAL.indexOf(level) >= 0
                redis.hset key, user_id, level
        else
            redis.hdel key, user_id, level

    @_level_current_user:(site_id, callback)->
        current = AV.User.current()
        if current
            SiteUserLevel._level current.id, site_id, callback
        else
            callback 0


    @_level : (user_id, site_id, callback) ->
        key = R.SITE_USER_LEVEL+site_id
        user_id = id_bin user_id
        redis.hget key, user_id, (err, level)->
            level = level or 0
            callback level - 0

    @set_by_user_id: ({user_id,site_id,level}, options) ->
        AV.Object.createWithoutData(
            'User'
            user_id
        ).fetch (user)->
            SiteUserLevel.set_by_user {user, site_id, level}, options

    @set_by_user: ({user,site_id,level}, options) ->
        current = AV.User.current()
        user_id = user.id
        if current
            SiteUserLevel._level(
                current.id
                site_id
                (_level)->
                    if _level >= SITE_USER_LEVEL.ROOT
                        SiteUserLevel._set user_id, site_id, level
                    options.success [user_id, user.get('username')]
            )

    @set: ({username,site_id,level}, options) ->
        USER.search username, (user)->
            if user
                SiteUserLevel.set_by_user {user, site_id, level}, options
            else
                options.fail {
                    username:"查无此人"
                }

    @by_site_id:({site_id}, options)->
        key = R.SITE_USER_LEVEL+site_id
        redis.hgetall key, (err, user_id_level)->
            user_id_list = []
            user_level_dict = {}
            for user_id,level of user_id_level
                user_id = bin_id user_id
                user_id_list.push user_id
                user_level_dict[user_id]=level-0
            
            query = new AV.Query(AV.User)
            query.containedIn "objectId", user_id_list
            query.select "username"
            query.find (user_list)->
                result = []
                for i in user_list
                    result.push [
                        i.id
                        i.get 'username'
                        user_level_dict[i.id]
                    ]
                options.success result

SITE_USER_LEVEL_VAL = []

(->
    extend = {}
    has_permission = (_level)->
        (func)->
            (params, options)->
                error = {
                    code:403
                    message:403
                }

                user = AV.User.current()
                if user
                    SiteUserLevel._level user.id, params.site_id, (level)=>
                        if level >= _level
                            func.call @, params, options
                        else
                            options.error error
                else
                    options.error error

    for k,v of SITE_USER_LEVEL
        SITE_USER_LEVEL_VAL.push v
        extend["$#{k}"] = has_permission(v)
    
)()

