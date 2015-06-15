$ = require "underscore"

module.exports = View = (cls) ->
    for k,v of cls.prototype
        if k.charAt(0) == "_" or not $.isFunction(v)
            continue
        AV.Cloud.define("#{cls.name}.#{k}", v)


module.exports.logined = logined = (func)->
    (request , response)->
        if AV.User.current()
            return func.call @,request,response
        response.error {
            code:403
            message:403
        }

module.exports.Logined = (cls)->
    for k,v of cls.prototype
        if k.charAt(0) == "_" or not $.isFunction(v)
            continue
        cls.prototype[k] = logined(v)
    View(cls)
