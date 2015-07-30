rtrim = require("underscore.string/rtrim")
uuid = require "node-uuid"
b10 = require('base-x')("0123456789")
b62 = require('base-x')('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')



module.exports =
    id_b64 : (str) ->
        new Buffer(str, 'hex').toString('base64')
    
    b64_id : (str) ->
        new Buffer(str, 'base64').toString('hex')
    
    id_bin : (str) ->
        new Buffer(str, 'hex').toString('binary')
    
    bin_id : (str) ->
        new Buffer(str, 'binary').toString('hex')

    uuid : ()->
        rtrim(new Buffer(uuid.v4().replace(/-/g,''),'hex').toString('base64'),"=").replace(/\//g,'-').replace(/\\+/g,'_')

    num_b62: (num)->
        b62.encode(b10.decode(num+''))
