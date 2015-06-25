module.exports = {

    by_search:(word)->
        query = new AV.Query(AV.User)
        if word.indexOf("@")>0
            query.equalTo("email", word)
        else if word-0
            query.equalTo("mobilePhoneNumber", word)

    query.find({
          success: function(women) {
                    }
    })
}
