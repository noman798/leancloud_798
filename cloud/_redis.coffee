_redis = require("redis")
CONFIG = require('cloud/config')
{num_b62} = require 'cloud/_lib/b64'



redis = _redis.createClient CONFIG.REDIS.PORT, CONFIG.REDIS.IP, {
    socket_keepalive:true
}

redis.auth CONFIG.REDIS.PASSWORD

redis.R = R = (key, suffix='')->
    _key = "_#{CONFIG.REDIS.NAMESPACE}_R"

    redis.hget _key, key,(err,r)->
        if r
            R[key] = r + suffix
        else
            redis.incr "_REDIS_KEY_ID", (err, r)->
                r = num_b62 r
                redis.hset _key, key, r, ->
                    R[key] = r + suffix
        

redis.smismember = (key, id_list, callback)->
    evalsha.exec(
        'smismember'
        [key]
        id_list
        callback
    )

module.exports = redis

Evalsha = require('redis-evalsha')
evalsha = new Evalsha(redis)
evalsha.add(
    'smismember'
    """
local ret={}
for i=1,#ARGV do
table.insert(ret,redis.call('sismember',KEYS[1],ARGV[i]) or 0) 
end
return ret 
    """
)


