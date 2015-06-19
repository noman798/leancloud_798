require "cloud/db/oauth"
require "cloud/db/post"
DB = require "cloud/_db"
Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote

_oauth_get = (params, callback)->
    DB.Oauth.$.get(params.id, {
        success: (oauth) ->
            #TODO , 根据oauth的类型决定访问的域名serviceHost
            client = new Client(
                token:oauth.get('token')
                serviceHost:'sandbox.evernote.com'
            )
            store = client.getNoteStore()
            callback store
    })

DB class EvernoteSyncCount
    constructor : (
        @oauth_id
        @count
        @pre_count
    ) ->
        super


DB class EvernoteSync
    constructor : (
        @oauth_id
        @update_count
    ) ->
        super

    @new: (params) ->
        EvernoteSync.$.get_or_create({
            oauth_id:params.oauth_id
        }, {
            success:(o) ->
                o.set(
                    update_count : params.update_count
                )
                o.save()
        })

    @sync: (params, options) ->
        _oauth_get(params, (store)->
            _sync = (evernote_sync) ->
                update_count = 0
                if evernote_sync
                    update_count = evernote_sync.get('update_count')

                filter = new Evernote.NoteFilter()
                filter.words = """any: tag:发布 tag:publish"""
                filter.order = Evernote.NoteSortOrder.UPDATE_SEQUENCE_NUMBER
                spec = new Evernote.NotesMetadataResultSpec()
                spec.includeUpdateSequenceNum = true
                spec.includeUpdated = true
                spec.includeDeleted = true
                spec.includeTitle= true

                EvernoteSyncCount.$.get_or_create(
                    {
                        oauth_id
                    }
                    success:(_c)->
                        _c.set "count",0
                        _c.save success:(counter)->
                            to_update_count = 0
                            _ = (offset)->
                                if offset > 0
                                    limit = 3
                                else
                                    limit = 100
                                store.findNotesMetadata(
                                    filter, offset, limit, spec
                                    (err, li) ->
                                        if err or not li
                                            console.log err
                                            return

                                        the_end = 0

                                        console.log "UpdateCount",li.notes.length, update_count, li.updateCount
                                        if not li.notes.length
                                            the_end = 1
                                            return

                                        for note in li.notes

                                            if note.updateSequenceNum <= update_count
                                                the_end = 1
                                                break
                                            console.log note.title , note.updateSequenceNum
                                            ++ to_update_count

                                            store.getNote(note.guid, true, true, false, false, (err, full_note) ->
                                                if err
                                                    console.log err
                                                    return
                                                guid = full_note.guid

                                                EvernotePost.new(
                                                    guid
                                                    (id, success)->
                                                        DB.PostHtml.new(
                                                            {
                                                                id
                                                                title: full_note.title
                                                                html: full_note.content
                                                            }
                                                            success:(post)->
                                                                success post
                                                                -- to_update_count
                                                                if to_update_count
                                                                    counter.increment 'count'
                                                                else
                                                                    counter.set count:-1
                                                                    EvernoteSync.new {
                                                                        oauth_id
                                                                        update_count:li.updateCount
                                                                    }
                                                                counter.save() 
                                                        )
                                                )
                                            )
                                        if the_end
                                            if not to_update_count
                                                counter.set count:-1
                                                counter.save()
                                        else
                                            _(offset+limit)
                                )
                            _ 0
                    )

            query = EvernoteSync.$
            oauth_id = params.id
            query.equalTo {oauth_id}
            query.first(
                success: (evernote_sync) ->
                    _sync(evernote_sync)
                error:(err) ->
                    if err.code == 101
                        _sync()
                    else
                        console.log err
            )
        )
            
     @count: (params, options) ->
        q = EvernoteSyncCount.$
        q.equalTo {
            oauth_id:params.id
        }
        q.first({
            success:(counter) ->
                count = counter.get('count')
                pre_count = counter.get('pre_count')

                if count < 0 or (pre_count == count and ((new Date())-counter.updatedAt)/1000 > 30)
                    counter.set 'count', -1
                    counter.set 'pre_count', -1
                    counter.save()
                    return

                if count != pre_count
                    counter.set 'pre_count', count
                    counter.save()

                options.success count
        })




DB class EvernotePost
    constructor : (
        @guid
        @post
    ) ->
        super

    @new: (guid, post_new) ->
        EvernotePost.$.get_or_create({
            guid
        },{
            success:(o)->
                _post = o.get('post')

                if _post
                    post_id = _post.id
                else
                    post_id = 0

                post_new post_id, (post)->
                    if post_id != post.id
                        o.set {post}
                        o.save()
        })
