redis = require("redis")
module.exports = client = redis.createClient()
CONFIG = require('cloud/config')
client.auth CONFIG.REDIS.PASSWORD




