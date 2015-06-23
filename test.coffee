
#{id_b64, b64_id, num_b64} = require 'cloud/_lib/b64'

#console.log b64_id id_b64('55892bafe4b0416bdfc44c89')
#console.log num_b64 1000

redis = require "cloud/_redis"
{R} = redis
R "PostStar"
setTimeout(
    ->
        console.log R.PostStar
        redis.smismember R.PostStar+'-'+"5554f671e4b076f1c3451b9b", [ 99289, 99286, 99285, 99284, 99283, 99281, 99280, 99278, 99277, 99276, 99272, 99269, 99268, 99267, 99266, 99261, 99253, 99251, 99250, 99249 ], (err, result)->
            console.log err, result
    1000
)

###
app = require 'app'
require 'cloud/db/sync'
require 'cloud/db/oauth'
DB = require 'cloud/_db'

main = ->
    DB.EvernoteSync.by_tag(
        {
            id:"557ea6cae4b019eef746e5c6"
            site_id:'555d759fe4b06ef0d72ce8e7'
        }
        {
            success:(li)->
                console.log li

        }
    )
    DB.EvernoteSync.sync(
        {
            id:"55813e90e4b007f322d8874e"
        }
        {
            success:(li)->
                console.log li

        }
    )
    DB.EvernoteSync.count(
        {
            id:"55813e90e4b007f322d8874e"
        }
        {
            success:(li)->
                console.log 'count is', li

        }
    )
    DB.Oauth.rm(
        {
            id:"5583e3b4e4b0dc547b4ebb55"
        }
        {
            success:(li)->
                console.log 'count is', li

        }
    )

    #DB.Oauth.by_user( { user_id: "5566f0cee4b09f185e943711" } { success: (li) -> console.log li } )

    #DB.Oauth.rm( { oauth_id: "5580ef47e4b007f322d39e18" } { success: (li) -> console.log li } )

main()
###
