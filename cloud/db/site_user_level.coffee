USER = require "cloud/db/user"
DB = require "cloud/_db"
redis = require "cloud/_redis"
{R} = redis
R "SITE_USER_LEVEL",":"



module.exports.SITE_USER_LEVEL =
    ROOT : 1000     #管理员，可以管理团队成员
    EDITOR : 900    #可以审核投稿
    WRITER : 800    #投稿可以自动发布
    BAN : -100

# SITE_USER_LEVEL = requre 'cloud/db/site_user_level'

SITE_USER_LEVEL_VAL = []

(->
    extend = {}
    check
    for k,v of SITE_USER_LEVEL
        SITE_USER_LEVEL_VAL.push v
        extend["$#{k}"] = has_permission(v)


    
)()




DB class SiteUserLevel
    @_set : (user_id, site_id, level) ->
        key = R.SITE_USER_LEVEL+site_id
        if level
            if SITE_USER_LEVEL_VAL.indexOf level > 0
                redis.hset key, user_id, level
        else
            redis.hdel key, user_id, level

    @_level : (user_id, site_id, callback) ->
        key = R.SITE_USER_LEVEL+site_id
        redis.hget R.SITE_USER_LEVEL, user_id, (err, level)->
            callback level or 0

    @set: ({username,site_id,level}, options) ->
        AV.User.current().fetch (admin)->
            if admin
                SiteUserLevel._level(
                    admin.get('ID')
                    site_id
                    (_level)->
                        if _level < SITE_USER_LEVEL.ROOT
                            return
                        USER.search username, (user)->
                            if user
                                SITE_USER_LEVEL._set user.get('ID'), site_id, level
                )
            options.success ''

    @by_site_id:({site_id}, options)->
        key = R.SITE_USER_LEVEL+site_id
        redis.hgetall key, (err, user_id_level)->
            user_id_list = []
            user_level_dict = {}
            for user_id,level of user_id_level
                user_id = user_id-0
                user_list.push user_id
                user_level_dict[user_id]=level

            query = new AV.Query(AV.User)
            query.containedIn "ID", user_id_list
            query.find (user_list)->
                for i in user_list
                    i.set('level',user_level_dict[i.get('ID')])
                options.success user_list


           
        
