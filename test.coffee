
DB = require "cloud/_db"
AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')
require "cloud/db/post_inbox"

DB.PostInbox.by_site {
    site_id:"555d759fe4b06ef0d72ce8e7"
},{
    success:->
        console.log "!!"
}
