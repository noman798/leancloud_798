
require "cloud/db/site_user_level"
DB = require "cloud/_db"

AV.User.current = ->
    return AV.Object.createWithoutData('User', '55a5f9dce4b0bd9f4b37c2eb')

DB.SiteUserLevel._level_current_user  "555d759fe4b06ef0d72ce8e7",(level)->
    console.log level

#require "test/redis_count_test"

