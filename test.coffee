
require "cloud/db/post_inbox"
DB = require "cloud/_db"
DB.PostInbox._by_user(
    {
        site_id:"555d759fe4b06ef0d72ce8e7"
        owner_id:"559bbcb4e4b023682f148e98"
    }
    {
        success:(li)->
            for i in li
                console.log i
    }
)
#DB.PostTxt.by_post(
#    {
#        post_id:"55912b5be4b060308e872e5d"
#        site_id:"555d759fe4b06ef0d72ce8e7"
#    }
#    {
#        success:(li)->
#            for i in li
#                console.log i
#    }
#)
#require "cloud/db/site_user_level"
#DB = require "cloud/_db"
#DB.SiteUserLevel._set("5554f671e4b076f1c3451b9b","555d759fe4b06ef0d72ce8e7",1000)
#DB.SiteUserLevel._level("5554f671e4b076f1c3451b9b","555d759fe4b06ef0d72ce8e7",(level)->
#    console.log level
#
#)
#
