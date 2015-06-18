app = require 'app'
require 'cloud/db/sync'
require 'cloud/db/oauth'
DB = require 'cloud/_db'

main = ->
    ###
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
    ###

    DB.EvernoteSync.sync(
        {
            id:"55813e90e4b007f322d8874e"
            site_id:'555d759fe4b06ef0d72ce8e7'
        }
        {
            success:(li)->
                console.log li

        }
    )

    #DB.Oauth.by_user( { user_id: "5566f0cee4b09f185e943711" } { success: (li) -> console.log li } )

    #DB.Oauth.rm( { oauth_id: "5580ef47e4b007f322d39e18" } { success: (li) -> console.log li } )

main()
