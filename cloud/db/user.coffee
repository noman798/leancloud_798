module.exports = {

    search:(word, callback)->
        query = new AV.Query(AV.User)
        if word.indexOf("@")>0
            query.equalTo("email", word)
        else if word-0
            query.equalTo("mobilePhoneNumber", word)

        query.first success:(o)->
            if o
                callback o
            if o
                query = new AV.Query(AV.User)
                query.equalTo "username",word
                query.first success:callback


}
