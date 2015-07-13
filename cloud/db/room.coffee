DB = require "cloud/_db"
redis = require "cloud/_redis"
{R} = redis
Q = require "q"

R "RoomMemberRoomId",":"
R "RoomMemberMessageReadCount",":"

APP_ID = process.env.LC_APP_ID
SITE_USER_LEVEL = require("cloud/db/site_user_level")

###
每个网站可以自定义创建一个或多个公众聊天室
-公众频道
   谈天说地 -> 公众聊天室

记录每个站点默认有的公众频道

###

DB class SiteChannel
    constructor: (
        @site_id
        @room_list
    ) ->
        super
    #用relation来存对应的频道

    @by_site_id: (params, options) ->
        query = SiteChannel.$
        query.equalTo({site_id: params.site_id})
        query.first({
            success: (site_channel) ->
                site_room = []
                room_list = site_channel.get('room_list')
                for i in room_list
                    redis.hget(R.ROOM_LOG_READ_COUNT+user_id, room_id, (err, read_count) ->
                        redis.hget(R.ROOM_LOG_COUNT+room.id, room.id, (err, count) ->
                            site_room.push [i.id, i.get('name'), count, read_count]
                        )
                    )
                Q.all(site_room).then (params)->
                    options.success params 
        })

###
{
    site_room:[
        [
            id
            name
            total_count
            read_count
        ]
    ]
}
{
###

    _new:(params, options) ->
        SiteChannel.$.get_or_create({
            site_id: params.site_id
        }, {
            create:(o)->
                room = AV.Object.new('_Conversation')
                room.set('name', params.room_name)
                room_list = [room]
                o.set('room_list', room_list)
            success:(o)->
                room = AV.Object.new('_Conversation')
                room_list = o.get('room_list')
                o.set('room_list', room_list.push(room))
                o.save()
        })
        options.success ''


    _set:(site_id, room_list) ->
    _set:(params, options) ->
        query = SiteChannel.$
        query.get(params.site_id, {
            success: (site_channel) ->
                room_list = []
                for i in room_list
                    room = AV.Object.createWithoutData('_Conversation', i)
                    room_list.push room
                site_channel.set('room_list', params.room_list)
                site_channel.save()
        })
        options.success ''



    new:SITE_USER_LEVEL.$.ROOT @_new

    set:SITE_USER_LEVEL.$.ROOT @_set

    readed:(room_id)->
        redis.hset(
            R.ROOM_LOG_READ_COUNT+user_id,
            room_id,
            count
        )


_messageReceived: (req, res) ->
    redis.hincr R.ROOM_LOG_COUNT, room_id


###

# 客服频道 ， 用户可以与多个客服聊天， 用户和用户默认之间不可见

# 广而告之 ， 全站频道，发一条消息，所以用户都收到

# 系统通知  

# -私人频道
#
#       客服咨询 -> 
#           第一次发消息的时候创建房间，并且把所有编辑身份以上的人加入进来
#           客服
           
#       通知提醒 -> 新人导航，投稿提醒什么的, 在系统通知的留言会直接转发到客服咨询

#       广而告之 -> 留言会直接转发到客服咨询
#
#       文章回复 -> 没有的时候不显示
#
#       @我 -> 
#      以上频道不能删除不能退出

# -留言对话
#       xxx项目 -> 
#               通知项目的相关人员

#_messageReceived: (req, res) ->
DB class RoomMember
    constructor: (
        @site
        @from_user
        @to_user
        @show_name
        @is_exit
        @is_hidden
        @is_top
    )->
        super

    @room_id_by_to_user:(params, options)->
        {from_user_id, to_user_id} = params
        if from_user_id > to_user_id
            key = from_user_id+"-"+to_user_id
        else
            key = to_user_id+"-"+from_user_id
        key = R.RoomMemberRoomId+key
        redis.get key, (err, room_id)->
            if room_id
                options.success room_id
            else
                room = AV.Object.new('_Conversation')
                room.set {
                    m:[from_user_id, to_user_id]
                    c:from_user_id
                    mu:[]
                }
                room.save {
                    success:(room)->
                        redis.set key, room.id, ->
                            options.success room.id
                }

    
#
#
#    @join_room:(params, options)->
#        query = RoomMember.$
#        room = AV.Object.createWithoutData("_Conversation", params.room_id)
#        room.add(params.from_user_id, ()->
#            console.log 'add success'
#        )
#        query.get_or_create({
#            from_user: params.from_user_id
#            room: room
#        }, {
#            create: (room_member) ->
#                room_member.set('from_user', params.from_user_id)
#                room_member.set('room', room)
#
#            success: (room_member) ->
#                room.save()
#        })
#
#
#
#    @by_user:()-> #[[room], [friend]]
#    # 根据最近联系时间倒序排列，只返回最近30天有联系过的, 最多100个, 当前用户,  每个人用户会set一个unread
#    # query.include('room')
#        query = RoomMember.$
#        query.equalTo('from_user', params.from_user_id)
#        query.greateThan('updated_time',
#                         new Date(new Date()- 24*3600*1000*30))
#        query.descending('updated_time')
#        query.limit 100
#        query.find({
#            success:(room_member_list) ->
#                user_list = []
#                room_list = []
#                for i in room_member_list
#                    user = i.get('to_user').fetch()
#                    unread = i.get('unread')
#                    room = i.get('room')
#                    if user
#                        user_list.push(user)
#                    if room
#                        room_list.push(room.id)
#                        
#                options.success [room_list, user_list]
#        })
#   
#
#    @by_current:(params, options)->
#        user = AV.User.current()
#        params.from_user_id = user.id
#        RoomMember.by_user(params, options)
#
#    @hide:(id)->
#
#    @exit:()-> #只能exit room，不能exit私聊
#        #query.doesNotExist
#        #query.exists
#        #xxx.unset 'is_exit'
#
#    @rename:()->
#    @readed:(id, count)->
#     
#################
#
#
#














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
