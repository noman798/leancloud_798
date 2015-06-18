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
    ) ->
        super


DB class EvernoteSync
    constructor : (
        @oauth_id
        @update_count
        @updated
    ) ->
        super

    @new: (params) ->
        oauth_id = params.id
        EvernoteSync.$.get_or_create({
            oauth_id
        }, {
            success:(o) ->
                o.set(
                    update_count : params.update_count
                    updated : params.updated
                )
                o.save()
        })

    @sync: (params, options) ->
        _oauth_get(params, (store)->
            query = EvernoteSync.$
            oauth_id = params.id
            query.equalTo {oauth_id}
            _sync = (evernote_sync) ->
                if evernote_sync
                    words = """updated:#{evernote_sync.get('updated')-1}"""
                    update_count = evernote_sync.get('update_count')
                else
                    update_count = 0
                    words = ''

                filter = new Evernote.NoteFilter()
                filter.words = words + """any: tag:发布 tag:publish"""
                filter.order = Evernote.NoteSortOrder.UPDATE_SEQUENCE_NUMBER
                spec = new Evernote.NotesMetadataResultSpec()
                spec.includeUpdateSequenceNum = true
                spec.includeUpdated = true
                spec.includeDeleted = true
                spec.includeTitle= true

                limit = 1
                updated = 0
                counter = EvernoteSyncCount.$.get_or_create(
                    {
                        oauth_id
                    }
                    success:(counter)->
                        _ = (offset)->
                            counter.set count:0
                            counter.save()

                            store.findNotesMetadata(
                                filter, offset, limit, spec
                                (err, li) ->
                                    if err or not li
                                        console.log err
                                        return

                                    to_update_count = 0
                                    for note in li.notes
                                        if not updated
                                            updated = note.updated
                                        if note.updateSequenceNum <= update_count
                                            to_update_count = 0
                                            break
                                        ++ to_update_count

                                        store.getNote(note.guid, true, true, false, false, (err, full_note) ->
                                            if err
                                                console.log err
                                                return
                                            guid = full_note.guid

                                            EvernotePost.new(
                                                guid
                                                (success)->
                                                    DB.PostHtml.new(
                                                        {
                                                            title: full_note.title
                                                            html: full_note.content
                                                        }
                                                        success:(post)->
                                                            success post
                                                            counter.increment('count')
                                                            counter.save()
                                                    )
                                            )
                                        )
                                    if to_update_count
                                        _(offset+limit)
                                    else
                                        EvernoteSync.new {
                                            oauth_id:params.oauth_id
                                            update_count:li.updateCount
                                            updated:updated
                                        }
                            )
                        _ 0
                    )

            query.first(
                success: _sync
                error:(err) ->
                    if err.code == 101
                        _sync()
                    else
                        console.log err
            )
        )
            
     @by_count: (params, options) ->
        query.get(params.sync_id, {
            success:(evernote_sync) ->
                date = new Date()
                if date - evernote_sync.updateded > 30 * 1000
                    if evernote_sync.count == count
                        evernote_sync.set('count', -1)
                        evernote_sync.save()
                    else
                        evernote_sync.set('count', count)
                        evernote_sync.set('updateded', date)
                        evernote_sync.save()
                options.success evernote.get('count')
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
                if not o.get('post')
                    post_new (post)->
                        o.set {post}
                        o.save()
        })
