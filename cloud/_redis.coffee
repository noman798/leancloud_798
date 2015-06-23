_redis = require("redis")
CONFIG = require('cloud/config')

console.log CONFIG.REDIS.IP
redis = _redis.createClient CONFIG.REDIS.PORT, CONFIG.REDIS.IP, {
    socket_keepalive:true
}
module.exports = redis

redis.auth CONFIG.REDIS.PASSWORD
redis.set("foo_rand000000000000", "OK")
redis.get("foo_rand000000000000", ->
    consoloe.log 111111
)


redis.hgetall "_#{CONFIG.REDIS.KEY}_KEY", (err, obj)->
    console.log obj


redis.KEY = KEY = (key)->
    console.log "t1"

    redis.get "_#{CONFIG.REDIS.KEY}_ID",(err, obj)->
        console.log err, obj

    redis.incr "_#{CONFIG.REDIS.KEY}_ID", (err, obj)->
        console.log err, obj


