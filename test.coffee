
require "cloud/db/post"
DB = require "cloud/_db"
AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')


DB.Post.rm {

    id: "55a8afdbe4b05881ac986142"
    site_id: "555d759fe4b06ef0d72ce8e7"

}, {

    success:->
        console.log 1111
}

