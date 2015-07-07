
wrap = (func)->
    (request, response) ->
        request.fail = (err)->
            count = Object.keys(err).length
            if count
                response.error({code:-1, message:err})
            else
                response.success('')
        func(request, response)

_define = AV.Cloud.define
AV.Cloud.define = (name, func) ->
    _define name, wrap(func)
    

