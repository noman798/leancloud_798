$ = require "underscore"
require "cloud/_lib/query"
require "cloud/_lib/av"
define$ = (cls_, db)->
    Object.defineProperty(
        cls_
        "$"
        {
            get : ->
                new AV.Query(db)
        }
    )

_id = {
    set : (value)->
        @$.id = value
    get : ->
        @$.id
}

_property = (k)->
    {
        set : (value)->
            @$.set(k,value)
        get : ->
            @$.get(k)
    }

_proxy = (name) ->
    (params...)->
        @$[name].apply @$, params

_PROXY = ->

for _db_funcname,_db_func of AV.Object.prototype
    _PROXY.prototype["$"+_db_funcname] = _proxy(_db_funcname)

_PROXY.prototype["$setACL"] = (params...)->

    if not params.length
        acl = new AV.ACL(AV.User.current())
        acl.setPublicWriteAccess false
        acl.setPublicReadAccess true
        params = [acl]
    @$.setACL.apply @$, params

module.exports = (cls)->

    if cls.name in module
        return

    if cls.prototype instanceof _PROXY
        cls_name = cls.prototype.__cls__.name
    else
        cls_name = cls.name
        cls.prototype = new _PROXY()
        cls.prototype.__cls__ = cls
    
    db = AV.Object.extend cls_name
    cls.__super__ =
        constructor : (params...)->
            dict = {}
            self = @
            for k,v of @
                if $.isFunction(v) or k.charAt(0)=='_'
                    continue
                dict[k] = v
                Object.defineProperty(@, k, _property(k))
            id = @id
            Object.defineProperty(@, "id", _id)
            if id
                @id = id
            @$ = db.new(dict)
    
    for k,v of db
        if $.isFunction(v)
            cls["$"+k] = v


    module.exports[cls.name] = _cls = (params...) ->
        o = new cls()
        if params[0] instanceof AV.Object
            o.$ = params[0]
        else
            o.$set params[0]
        return o

    Object.defineProperty(
        _cls
        "VIEW"
        {
            get : ->
                result = new Function(
                    "return function " + cls.name + "(){}"
                )()

                prototype = result.prototype
                result.name = cls.name
                for k,v of cls
                    char0 = k.charAt(0)
                    if $.isFunction(v) and '_$'.indexOf(char0) < 0
                        prototype[k] = _new_view(v)
                result
        }
    )
    $.extend(_cls, cls)
    define$ cls,db
    define$ _cls,db



_new_view = (func)->
    (request, response) ->
        func(
            request.params
            {
                success:(params...)->
                    response.success.apply response,params
                error:(params...)->
                    response.error.apply response,params
                fail:(error)->
                    response.error {code:-1,message:error}
            }
        )

