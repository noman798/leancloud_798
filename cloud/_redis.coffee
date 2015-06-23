redis = require("redis")
client = redis.createClient()
CONFIG = require('cloud/config')
client.auth CONFIG.REDIS.PASSWORD
module.exports = client


