rtrim = require("underscore.string/rtrim")
b10 = require('base-x')("0123456789")



module.exports =
    id_b64 : (str) ->
        new Buffer(str, 'hex').toString('base64')
    
    b64_id : (str) ->
        new Buffer(str, 'base64').toString('hex')

    num_b64: (num)->
        rtrim b10.decode(num+'').toString('base64'),"="
