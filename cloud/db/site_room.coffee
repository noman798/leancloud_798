###
    用户进来 默认会加入 频道

    # 在线客服 ， 用户可以与多个客服聊天， 用户和用户默认之间不可见

    # 全站公告 ， 全站频道，发一条消息，所以用户都收到

    # 系统通知 ,  用户回复会自动转发到 在线客服 

    # 谈天说地 ， 所有用户的聊天室

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


###

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

