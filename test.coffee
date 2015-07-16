
require "test/redis_count_test"
require "cloud/db/site_user_level"
DB = require "cloud/_db"

AV.User.current = ->
    return AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')

require "test/post_inbox_test"
