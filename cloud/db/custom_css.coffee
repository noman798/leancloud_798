DB = require "cloud/_db"
redis = require "cloud/_redis"
{R} = redis

R "CustomCss"

DB class CustomCss
    constructor:(
        @site
        @css
    )->
        super
   
    @set:(
        params
        options
    )->
        CustomCss.$.get_or_create(
            {
                site_id
            }
            {
            
                success:(o)->
                    if o.get 'css' == params.css
                        return
                    o.set css:params.css
                    o.save success:(o)->
                        redis.hset R.CustomCss, site.id, o.updatedAt
                        options.success ''
            }
        )

    @_get:(site_id, callback)->
        redis.hget R.CustomCss, site_id, (err, time)->
            callback(time or 0)

