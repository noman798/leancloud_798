
require "cloud/db/sync"
DB = require "cloud/_db"
#AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')


DB.EvernoteSync.sync(
    {
        id: "559bbce9e4b0a35bc4d36b77"
    },{
        success:->
            console.log 'success'
    }
)
