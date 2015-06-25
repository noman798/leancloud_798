LEVEL_DECORATOR = (level)->
    level

module.exports = LEVEL
    ROOT : 1000     #管理员，可以管理团队成员
    EDITOR : 900    #可以审核投稿
    WRITER : 800    #投稿可以自动发布

# SITE_USER_LEVEL = requre 'cloud/db/site_user_level'
# SITE_USER_LEVEL.$ROOT

