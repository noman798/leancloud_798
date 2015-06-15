require "cloud/db/post_star"
DB = require "cloud/_db"

module.exports = (post_list, success)->
    user = AV.User.current()


    if user
        id2post = {}
        for i in post_list
            id2post[i.id] = i
        AV.Promise.when(
            DB.PostStar.is_star(
                user, i
            ) for i in post_list
        ).done(
            (star_list...)->
                for i in star_list
                    if i
                        id2post[i.get('post').id].set('is_star', 1)
                success post_list
        ).fail ->
            success post_list
    else
        success post_list
