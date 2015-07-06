require "cloud/db/site_user_level"
DB = require "cloud/_db"
DB.SiteUserLevel._set("5554f671e4b076f1c3451b9b","555d759fe4b06ef0d72ce8e7",1000)
DB.SiteUserLevel._level("5554f671e4b076f1c3451b9b","555d759fe4b06ef0d72ce8e7",(level)->
    console.log level

)

