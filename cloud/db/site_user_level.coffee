
module.exports = SITE_USER_LEVEL =
    ROOT : 1000     #管理员，可以管理团队成员
    EDITOR : 900    #可以审核投稿
    WRITER : 800    #投稿可以自动发布
    BAN : -100

# SITE_USER_LEVEL = requre 'cloud/db/site_user_level'

SITE_USER_LEVEL_VAL = []

(->
    for k,v of SITE_USER_LEVEL
        SITE_USER_LEVEL_VAL.push v
)()

R "SITE_USER_LEVEL",":"

class SiteUserLevel
    @_set : (user_id, site_id, level) ->
        key = R.SITE_USER_LEVEL+site_id
        if level
            if SITE_USER_LEVEL_VAL.indexOf level > 0
                redis.hset key, user_id, level
        else
            redis.hdel key, user_id, level

    @level : (user_id, site_id, callback) ->
        key = R.SITE_USER_LEVEL+site_id
        redis.hget R.SITE_USER_LEVEL, user_id, (err, level)->
            callback level or 0

    @set:(user_id,site_id,level)->
        SiteUserLevel.level(user_id, site_id, (_level)->
            if _level < SITE_USER_LEVEL.ROOT
                return
            SITE_USER_LEVEL._set user_id, site_id, level
        )

    @by_site_id:(site_id)->
        key = R.SITE_USER_LEVEL+site_id
        redis.hgetall key, (err, user_id_level)->
            user_list = []
            for user_id,level of user_id_level
                level.push [user_id, level-0]

           

