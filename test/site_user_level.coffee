SITE_USER_LEVEL = require "cloud/db/site_user_level"
DB = require "cloud/_db"

USER_ID = "555ec11ee4b032867864e735"
SITE_ID = "555d759fe4b06ef0d72ce8e7"

DB.SiteUserLevel._level USER_ID, SITE_ID, (level)->
    console.log USER_ID, SITE_ID, level

