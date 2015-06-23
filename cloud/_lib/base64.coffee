
rtrim = require("underscore.string/rtrim")

module.exports =
    hex2base64 : (hex) ->
        new rtrim Buffer(hex, 'hex').toString('base64'), "="
