_redis = require("redis")
CONFIG = require('cloud/config')
{num_b62} = require 'cloud/_lib/b64'

redis = _redis.createClient CONFIG.REDIS.PORT, CONFIG.REDIS.IP, {
    socket_keepalive:true
}

redis.auth CONFIG.REDIS.PASSWORD



redis.KEY = KEY = (key)->
    _key = "_#{CONFIG.REDIS.KEY}_KEY"

    redis.hget _key, key,(err,r)->
        if r
            KEY[key] = r
        else
            redis.incr "_#{CONFIG.REDIS.KEY}_ID", (err, r)->
                r = num_b62 r
                redis.hset _key, key, r, ->
                    KEY[key] = r

    

module.exports = redis
