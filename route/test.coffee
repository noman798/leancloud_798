app = require 'app'


app.get '/test', (req, res) ->
    AV.Cloud.run(
        "SyncEvernote.sync"
        {
            id:"557ea6cae4b019eef746e5c6"
        }
        {
            success:(li)->
                for i in li
                    console.log i

        }
    )
    return

