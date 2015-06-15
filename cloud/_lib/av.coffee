
AV.Cloud.FunctionResponse?.prototype.fail = (error)->
    count = Object.keys(error).length
    if count
        @error {code:-1,message:error}
    return count
