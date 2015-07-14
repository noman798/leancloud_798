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
   
    @_set:(
        site_id
        css
    )->
        console.log "set css", site_id, css
        if css == undefined
            return

        site = AV.Object.createWithoutData("Site", site_id)

        CustomCss.$.get_or_create(
            {
                site
            }
            {
            
                success:(o)->
                    if o.get 'css' == css
                        return
                    o.set css:css
                    o.save success:(o)->
                        redis.hset R.CustomCss, site_id, o.updatedAt
            }
        )
    
    @_get:(site_id, callback)->
        query = CustomCss.$
        query.equalTo {site}
        query.first(
            success:(css)->
                if css
                    callback(css.get 'css')
                else
                    callback ''
        )

    @_get_updatedAt:(site_id, callback)->
        redis.hget R.CustomCss, site_id, (err, time)->
            callback(time or 0)

