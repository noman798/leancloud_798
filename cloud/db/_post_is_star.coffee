require "cloud/db/post_star"
DB = require "cloud/_db"
redis = require "cloud/_redis"

module.exports = (post_list, success)->
    user = AV.User.current()
    if user
        redis.smismember(
            redis.R.PostStar
            i.get('ID') for i in post_list
            (is_star_list)->
                for i,_ in star_list
                    if i
                        post_list[_].set('is_star', 1)
        )
    else
        success post_list
