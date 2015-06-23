
rtrim = require("underscore.string/rtrim")

module.exports =
    hex_base64 : (str) ->
        new Buffer(str, 'hex').toString('base64')
    
    base64_hex : (str) ->
        new Buffer(str, 'base64').toString('hex')
