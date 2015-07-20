require "cloud/db/room"
require "cloud/db/post_inbox"
require "cloud/db/sync"
DB = require "cloud/_db"

redis = require "cloud/_redis"
{R} = redis


site_id = "55a4d078e4b05001a77e7d5a"
owner_id = "55a5f9dce4b0bd9f4b37c2eb"


#redis.hincrby R.POST_INBOX_SUBMIT_COUNT, site_id, -1
_set = () ->
    redis.hset(R.POST_INBOX_SUBMIT_COUNT, site_id, 0)
    redis.hset(R.POST_INBOX_PUBLISH_COUNT, site_id, 1)
    redis.hset(R.POST_INBOX_RM_COUNT, site_id, 0)
    redis.hset(R.USER_POST_COUNT, owner_id, 0)
    redis.hset(R.USER_PUBLISH_COUNT, owner_id, 0)


_set()

redis.hget(R.POST_INBOX_SUBMIT_COUNT, site_id, (err, cnt) ->
    console.log "POST_INBOX_SUBMIT_COUNT"
    console.log cnt
)

redis.hget(R.POST_INBOX_PUBLISH_COUNT, site_id, (err, cnt) ->
    console.log "POST_INBOX_PUBLISH_COUNT"
    console.log cnt
)

redis.hget(R.POST_INBOX_RM_COUNT, site_id, (err, cnt) ->
    console.log "POST_INBOX_RM_COUNT"
    console.log cnt
)

redis.hget(R.USER_POST_COUNT, owner_id, (err, cnt) ->
    console.log "USER_POST_COUNT"
    console.log cnt
)

redis.hget(R.USER_PUBLISH_COUNT, owner_id, (err, cnt) ->
    console.log "USER_PUBLISH_COUNT"
    console.log cnt
)
