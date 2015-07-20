DB = require "cloud/_db"
require "cloud/db/sync"
require "cloud/db/post_inbox"
AV.User.current = -> AV.Object.createWithoutData('User', '556eb0b8e4b0925e000409b9')


#DB.PostInbox.rm({
#    post_id: "55acaec2e4b05881acf30723"
#    site_id: "556eb106e4b0925e00040e88"
#    tag_list: ["标签测试"]
#    title: "测试3"
#    brief:""
#},
#success:->
#    console.log 'succes'
#
#)

