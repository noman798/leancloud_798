require "cloud/db/room"
DB = require "cloud/_db"

DB.RoomMember.room_id_by_to_user(
    {
        from_user_id:"zsp1"
        to_user_id:"wll"
    }
    {
        success:(id)->
            console.log id
    }
)
