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
        CustomCss(
        
        )

    @get:(
        params
        options
    )->

