module.exports = {

    by_search:(word)->
        query = new AV.Query(AV.User)
        if word.indexOf("@")>0
            query.equalTo("gender", "female")
    query.find({
          success: function(women) {
                  // Do stuff
                    }
    });
}
