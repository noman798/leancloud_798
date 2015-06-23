require "cloud/db/post_star"
DB = require "cloud/_db"
redis = require "cloud/_redis"

module.exports = (post_list, success)->
    user = AV.User.current()
    if user
        redis.smismember(
            redis.R.PostStar + "-" + user.id
            i.get('ID') for i in post_list
            (err, is_star_list)->
                for i,_ in is_star_list
                    if i
                        post_list[_].set('is_star', 1)
                success post_list
        )
    else
        success post_list
