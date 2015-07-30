DB = require "cloud/_db"
b64 = require "cloud/_lib/b64"
redis = require "cloud/_redis"
{R} = redis
Q = require "q"

R "IM_WEB_ID", ":"

DB class IM

    @web_id: (params, options)->

        current = AV.User.current()
        if current
            user_id = current.id
        else
            user_id = 0
        
        q = DB.Site.$
        q.select 'ID'
        q.get(
            params.site_id
            success:(site)->
                if not site
                    return
                key = R.IM_WEB_ID+site.get('ID')
                redis.hget(
                    key
                    params.user_id or 0
                    (err, installation_id) ->
                        if installation_id
                            options.success installation_id
                        else
                            installation_id = b64.uuid()
                            _Installation.save success:->
                                redis.hset(
                                    key
                                    user_id
                                    installation_id
                                )
                                options.success installation_id
                )
        )
