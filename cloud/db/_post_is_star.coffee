require "cloud/db/post_star"
DB = require "cloud/_db"
redis = require "cloud/_redis"

module.exports = (post_list, success)->
    user = AV.User.current()
    if user
        console.log [i.get('ID') for i in post_list]
        redis.smismember(
            redis.R.PostStar + "-" + user.id
            i.get('ID') for i in post_list
            (is_star_list)->
                console.log "is_star_list", is_star_list
                for i,_ in is_star_list
                    if i
                        post_list[_].set('is_star', 1)
        )
    else
        success post_list
