
module.exports = (level_dict, level_func)->
    extend = {}
    has_permission = (_level)->
        (func)->
            (params, options)->
                error = {
                    code:403
                    message:403
                }

                user = AV.User.current()
                if user
                    level_func user.id, params, (level)=>
                        if level >= _level
                            func.call @, params, options
                        else
                            options.error error
                else
                    options.error error

    for k,v of level_dict
        extend[k] = has_permission(v)
    return extend
