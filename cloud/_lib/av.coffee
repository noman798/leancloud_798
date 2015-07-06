
wrap = (func)->
    (request, response) ->
        response.fail = (err)->
            count = Object.keys(err).length
            if count
                response.error({code:-1, message:err})
            else
                response.success('')
        func(request, response)


AV.Cloud.define = (name, func) ->
    AV.Cloud.__code[name] = wrap func
    

