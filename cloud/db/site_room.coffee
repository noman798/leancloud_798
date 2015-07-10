
DB SiteRoom
   @site
   @room_list

   _by_user:()
   by_current:()
    [
        id
        name
        unread_count
    ]
   room_set:SITE_USER_LEVEL.$.ROOT (
        site,
        room_list
        #[
        #    [name, id]
        #    [name, id]
        #    [name, id]
        #    [name, id]
        #]
   )->
   room_new:(site, name)->

   readed:()->
        redis.hset(
            R.ROOM_LOG_READ_COUNT+user_id,
            room_id,
            count
        )

_messageReceived: (req, res) ->
    redis.hincr R.ROOM_LOG_COUNT, room_id

