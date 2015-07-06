AV.Cloud.run = (name, data, options) ->
    promise = new AV.Promise()
    try
        Cloud.__code[name]({params: data, user: AV.User.current()}, {
            success: (result) ->
                promise.resolve(result)
            error: (err) ->
                promise.reject(err)
            fail: (err)->
                count = Object.keys(err).length
                if count
                    promise.reject({code:-1, message:err})
                else
                    promise.resolve('')

        })
    catch
        console.log('Run function \'' + name + '\' failed with error:', _error)
        promise.reject(_error)
    return promise._thenRunCallbacks(options)
