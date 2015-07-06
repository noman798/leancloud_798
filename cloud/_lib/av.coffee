
wrap = (func)->
    (request, response) ->
        response.fail = (err)->
            count = Object.keys(err).length
            if count
                response.reject({code:-1, message:err})
            else
                response.resolve('')
        func(request, response)


AV.Cloud.define = (name, func) ->
    Cloud.__code[name] = wrap func
    

