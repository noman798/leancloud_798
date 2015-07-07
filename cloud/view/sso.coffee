RE_DISABLE_CHAR_IN_USERNAME = RegExp(/[(\t)(\ )(\~)(\!)(\@)(\#)(\$)(\%)(\^)(\&)(\*)(\()(\))(\+)(\=)(\[)(\])(\{)(\})(\|)(\\)(\;)(\:)(\')(\")(\,)(\.)(\/)(\<)(\>)(\?)(\)]+/)

check=(o,error) ->
    if not o.username
        error.username = "请输入昵称"
    else if RE_DISABLE_CHAR_IN_USERNAME.test(o.username)
        error.username = "昵称请不要包含特殊符号"
    else if not isNaN(o.username - 0)
        error.username = "昵称不能为纯数字"
    else if o.username.length<=1
        error.username = "昵称不少于2个字符"
    else if o.username.length>12
        error.username = "昵称不多于14个字符"
    if not o.mobilePhoneNumber
        error.mobilePhoneNumber = "请输入手机"
    if not o.email
        error.email = "请输入邮箱"
    
AV.Cloud.define "SSO.auth.new", (request , response) ->
    o = request.params
    error = {}
    check(o,error)
    if not o.password
        error.password = "请输入密码"
    else if o.password.length < 6
        error.password = "密码不少于6个字符"

    if not request.fail error
        user = new AV.User()
        user.set(o)

        user.signUp(
            null
            {
                error:(user, _error)->
                    code = _error.code
                    if code == 125
                        error.email = "邮箱格式无效"

                    else if code == 127
                        error.mobilePhoneNumber = "手机号码无效"

                    else if code == 203 or code == 214
                        tip = """已注册。忘记密码了？<a href="javascript:URL('-SSO/auth.password_set_mail', '#{o.email}');void(0)">点此找回。</a>"""
                        if code == 203
                            error.email = "邮箱"+tip
                        else if code == 214
                            error.mobilePhoneNumber = "手机"+tip

                    else if code == 202
                        error.username = "昵称已被占用。加个数字后缀试试？"
                    
                    fail = request.fail error
                    if not fail
                        response.error _error

              success: (user) ->
                response.success user
            }
        )


AV.Cloud.define "SSO.auth.info_update",(request,response) ->
    o = request.params
    error = {}
    check(o,error)
    
    if not request.fail error
        user = AV.User.current()
        user.set(o)
        user.save(
            null
            {
                success: (user) ->
                    response.success user
                error:(user, _error)->
                    code=_error.code
                    if code == 125
                        error.email = "邮箱格式无效"
                    else if code == 127
                        error.mobilePhoneNumber = "手机号码无效"

                    else if code == 202
                        error.username = "昵称已被占用。加个数字后缀试试？"
                    else if code == 203
                        error.email = "邮箱已被占用"
                    else if code == 214
                        error.mobilePhoneNumber = "手机已被占用"

                    if not request.fail error
                        response.error _error
            }
        )

AV.Cloud.define "SSO.auth.password_update",(request,response) ->
    o = request.params
    error = {}
    if not o.oldpassword
        error.oldpassword = "请输入旧密码"
    if not o.newpassword
        error.newpassword = "请输入新密码"
    else if o.newpassword.length < 6
        error.newpassword = "密码不少于6个字符"

    if not request.fail error
        user = AV.User.current()
        
        user.updatePassword(o.oldpassword,o.newpassword,{
            success:(user) ->
                response.success user

            error:(user,_error) ->
                code=_error.code
                if code == 210
                    error.oldpassword = "旧密码错误"

                if not request.fail error
                    response.error _error
        })
