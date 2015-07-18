DB = require "cloud/_db"
require "cloud/db/post_inbox"
AV.User.current = -> AV.Object.createWithoutData('User', '5566f0cee4b09f185e943711')

DB.PostInbox.submit {
    brief: "我们致力于对接 **创业** 和 **资本** ，帮助靠谱的项目找到靠谱的钱。  ↵同时，我们也期待着有更多心怀梦想的一流程序员的加入。"
    post_id: "55a9fa24e4b00d44e202936f"
    site_id: "555d759fe4b06ef0d72ce8e7"
    tag_list: ["招聘"]
    title: "天使汇 · 程序部 · 招人启事 14"
}, {
    success: ->
        console.log 'ok'
}
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
