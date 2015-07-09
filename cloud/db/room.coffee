DB = require "cloud/_db"
# hset
    #Room
    #    msg_count

#Room
#    id
#    site
#    is_public

#RoomMember
#    site
#    msg_read_count
#    from_user
#    is_hidden
#    is_top
#    #私聊
#        to_user
#    room
#    #如果有自定义名称
#        show_name
#     
#    updatedAt

DB class RoomMember
    constructor: (
        @site
        @msg_read_count
        @from_user
        @to_user
        @room
        @show_name

        @is_exit
        @is_hidden
        @is_top
    )->
        super

    @send_to_user:(params, options)->
        query = RoomMember.$
        query.include('room')
        query.get_or_create({
            from_user: params.from_user_id
        }, {
            create: (room_member) ->
                room_member.set('from_user', params.from_user_id)
                room_member.set('to_user', params.to_user_id)

            success: (room_member) ->
                room = room_member.get('room')
                if room
                    room.add(params.to_user_id, ()->
                        console.log 'add success'
                    )
                else
                    realtimeObj = AV.realtime({
                        appId,
                        clientId: params.id
                    })
                    new_room = realtimeObj.room({
                        members: [params.from_user_id, params.to_user_id],
                    })
                    new_room.send({msg: params.msg}, ()->
                        console.log 'server ack.'
                    )
                    room_member.set('room', new_room)
                    room_member.save()
        })


    @send_to_room:(params, options)->
        room = AV.Object.createWithoutData("_Conversation", params.room_id)
        room.send({msg: params.msg}, ()->
            console.log 'server ack.'
        )


    @join_room:(params, options)->
        query = RoomMember.$
        room = AV.Object.createWithoutData("_Conversation", params.room_id)
        room.add(params.from_user_id, ()->
            console.log 'add success'
        )
        query.get_or_create({
            from_user: params.from_user_id
            room: room
        }, {
            create: (room_member) ->
                room_member.set('from_user', params.from_user_id)
                room_member.set('room', room)

            success: (room_member) ->
                room.save()
        })



    @by_user:()-> #[[channel], [friend]]
    # 根据最近联系时间倒序排列，只返回最近30天有联系过的, 最多100个, 当前用户,  每个人用户会set一个unread
    # query.include('room')
        query = RoomMember.$
        query.equalTo('from_user', params.from_user_id)
        query.greateThan('updated_time',
                         new Date(new Date()- 24*3600*1000*30))
        query.descending('updated_time')
        query.limit 100
        query.find({
            success:(room_member_list) ->
                user_list = []
                room_list = []
                for i in room_member_list
                    user = i.get('to_user').fetch()
                    unread = i.get('unread')
                    room = i.get('room')
                    if user
                        user_list.push(user)
                    if room
                        room_list.push(room.id)
                        
                options.success [room_list, user_list]
        })
   

    @by_current:(params, options)->
        user = AV.User.current()
        params.from_user_id = user.id
        RoomMember.by_user(params, options)

    @hide:(id)->

    @exit:()-> #只能exit channel，不能exit私聊
        #query.doesNotExist
        #query.exists
        #xxx.unset 'is_exit'

    @rename:()->
    @readed:(id, count)->
     


#DB class ImFriend
#    constructor: (
#        @from_user
#        @to_user   # 如果是群聊，to_user为null，通过room获取房间成员
#        @tag_list
#                    #updated_time    # 默认有
#        @room
#        @unread
#        @is_hide
#        @site
#    ) ->
#        super
#
#    #_messageReceived
#        #在于用户收到消息的时候，通过此会话，向服务器端发送一个transient的消息 来重置未读数 并拦截此消息 'READED'
#
#    #by_user() : 根据最近联系时间倒序排列，只返回最近30天有联系过的, 最多100个, 当前用户,  每个人用户会set一个unread
#
#    @by_user: (params, options) ->
#        query = ImFriend.$
#        query.equalTo('from_user', params.client_id)
#        query.greateThan('updated_time',
#                         new Date(new Date()- 24*3600*1000*30))
#        query.descending('updated_time')
#        query.limit 100
#        query.find({
#            success:(im_friend_list) ->
#                user_list = []
#                for i in im_friend_list
#                    user = i.get('to_user').fetch()
#                    unread = i.get('unread')
#                    if user
#                        user.set('unread', unread)
#                        user_list.push(user)
#                        
#                options.success user_list
#        })
#
#
#    @new: (params, options) ->
#        from_user = params.from_user
#        to_user = params.to_user
#        #params.msg:{data:"hi",kind:KIND.TXT}
#        query = ImFriend.$
#        query.equalTo({from_user, to_user})
#        query.first({
#            success: (im_friend) ->
#                options.success
#
#            error: (error) ->
#                # create room
#                realtimeObj = AV.realtime({
#                    appId,
#                    clientId
#                })
#                room = realtimeObj.room({
#                    members: [from_user, to_user],
#                })
#
#                im_friend = DB.ImFriend({
#                    from_user
#                    to_user
#                    room
#                    unread: 0
#                })
#                im_friend_to = DB.ImFriend({
#                    from_user: to_user
#                    to_user: from_user
#                    room
#                    unread: 0
#                })
#                im_friend.$save
#                im_friend_to.$save
#                options.success
#        })
#
#    @hide: (params, options) ->
#        {from_user,to_user} = params
#        query = ImFriend.$
#        query.equalTo({from_user, to_user})
#        query.first({
#            success: (im_friend) ->
#                im_friend.set('is_hide', true)
#                im_friend.save()
#                options.success
#        })
#
#    @read: (params, options) ->
#        from_user = params.from_user
#        to_user = params.to_user
#        query = ImFriend.$
#        query.equalTo({from_user, to_user})
#        query.first({
#            success: (im_friend) ->
#                im_friend.set('unread', 0)
#                im_friend.save()
#                option.success
#        })
#
#
#_messageReceived: (req, res) ->
#    room_id = req.params.convId
#    room = AV.Object.createWithoutData("_Conversation", room_id)
#    query = ImFriend.$
#    query.equalTo({room})
#    query.first({
#        success: (im_friend) ->
#            im_friend.increment("unread")
#            im_friend.save()
#    })
