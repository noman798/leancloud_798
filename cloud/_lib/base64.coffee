

module.exports =
    id_b64 : (str) ->
        new Buffer(str, 'hex').toString('base64')
    
    b64_id : (str) ->
        new Buffer(str, 'base64').toString('hex')


