
app = require 'app'
require 'cloud/db/sync'
DB = require 'cloud/_db'

main = ->
    console.log 111
    DB.SyncEvernote.by_tag(
        {
            id:"557ea6cae4b019eef746e5c6"
            site_id:'555d759fe4b06ef0d72ce8e7'
        }
        {
            success:(li)->
                console.log li

        }
    )

main()


