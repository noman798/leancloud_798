

SITE_USER_LEVEL = require "cloud/db/site_user_level"
DB = require "cloud/_db"


USER_ID = "555ec11ee4b032867864e735"
SITE_ID = "555d759fe4b06ef0d72ce8e7"


USER_ID = "556eb0b8e4b0925e000409b9"
SITE_ID = "556eb106e4b0925e00040e88"

GUEST_ID = "556be1a4e4b0aec39c81a36f"


DB.SiteUserLevel._set USER_ID, SITE_ID, SITE_USER_LEVEL.ROOT
DB.SiteUserLevel._level USER_ID, SITE_ID, (level)->
    console.log USER_ID, SITE_ID, level
