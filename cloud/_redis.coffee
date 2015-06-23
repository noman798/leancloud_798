redis = require("redis")
CONFIG = require('cloud/config')
client = redis.createClient 6379, CONFIG.REDIS.IP, {
    socket_keepalive:true
}
client.auth CONFIG.REDIS.PASSWORD
module.exports = client


