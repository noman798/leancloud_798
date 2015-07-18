DB = require "cloud/_db"
require "cloud/db/sync"
#AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')

#DB.EvernoteSync.sync { id: "559bbce9e4b0a35bc4d36b77" },{ success:-> console.log 'success' }
###
require "test/redis_count_test"
DB = require "cloud/_db"
AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')


DB.PostInbox.by_site {
    site_id: "555d759fe4b06ef0d72ce8e7"
}, {

    success:([count,li])->
        for i in li
            console.log i.get 'owner'
}
###
#AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')
