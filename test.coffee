
DB = require "cloud/_db"
AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')
require "test/redis_count_test"
require "cloud/db/site_user_level"
#require "test/redis_count_test"
#require "test/new"
#require "test/redis_count_test"
#AV.User.current = ->
#    return AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')

require "cloud/db/post_inbox"

DB.PostInbox.by_site {
    site_id:"555d759fe4b06ef0d72ce8e7"
},{
    success:->
        console.log "!!"
}
