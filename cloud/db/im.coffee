DB = require "cloud/_db"
uuid = require "node-uuid"
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
                        if not installation_id
                            installation_id = uuid.v4()
                            redis.hset(
                                key
                                user_id
                                installation_id
                            )
                        options.success installation_id
                )
        )
