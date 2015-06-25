module.exports = {

    search:(word, callback)->
        query = new AV.Query(AV.User)

        if word.indexOf("@")>0
            key = "email"
        else if word-0
            key = "mobilePhoneNumber"
        else
            key = "username"
        
        query.equalTo key, word

        query.first success:(o)->
            if o or key == 'username'
                callback o
            else
                query = new AV.Query(AV.User)
                query.equalTo "username",word
                query.first success:callback


}
