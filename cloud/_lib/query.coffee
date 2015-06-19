$ = require "underscore"

AV.Query.prototype.get_or_create = (
    equalTo , options
) ->
    _new = =>
        result = @objectClass.new()
        result.set equalTo
        if options
            if "create" of options
                options.create(result)
                delete options.create
        result.save options

    @equalTo(equalTo)
    @first {
        success : (object) ->
            if object
                options.success(object)
            else
                _new()
        error:(_error) ->
            if _error?.code == 101
                _new()
    }

_equalTo = AV.Query.prototype.equalTo

AV.Query.prototype.equalTo = (params...)->
    if $.isString params[0]
        _equalTo.apply @, params
    else
        for k,v of params[0]
            _equalTo.call @,k,v
    @

AV.Query.prototype.rm = (params, options)->
    @equalTo(params).destroyAll(options)
    @

    



