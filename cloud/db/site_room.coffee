
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
   readed:(room_id)->
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

