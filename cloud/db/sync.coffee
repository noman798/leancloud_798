require "cloud/db/oauth"
require "cloud/db/post"
DB = require "cloud/_db"
Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote

_oauth_get = (params, callback)->
    DB.Oauth.$.get(params.id, {
        success: (oauth) ->
            client = new Client(
                token:oauth.get('token')
                serviceHost:'sandbox.evernote.com'
            )
            store = client.getNoteStore()
            callback store
    })



DB class EvernoteSync
    constructor : (
        @oauth_id
        @update_count
        @updated
        @count
    ) ->
        super

    @new: (params) ->
        EvernoteSync.$.get_or_create({
            oauth_id:params.id
        }, {
            create:(o) ->
                o.set('oauth_id', params.id)
                o.set('update_count', 0)
                o.set('updated', 0)
                o.set('count', 0)
            success:(o) ->
                o.set('update_count', params.update_count)
                o.set('updated', params.updated)
                o.save()
        })

    @sync:(params, options) ->
        _oauth_get(params, (store)->
            #标签 SITE.NAME 不区分大小写
            store.listNotebooks(
                (error, li) ->
                    console.log li
                    for i in li
                        console.log i
                    options.success li
            )
        )

    @by_tag:(params, options) ->
        site_id = params.site_id
        delete params.site_id
        _oauth_get(params, (store)->
            filter = new Evernote.NoteFilter()
            filter.words = """tag:"tech2ipo" tag:"发布" updated:#{xxxx.updated-1}"""
            #filter.words = 'tag:"tech2ipo" tag:"发布" '
            filter.order = Evernote.NoteSortOrder.UPDATE_SEQUENCE_NUMBER

            spec = new Evernote.NotesMetadataResultSpec()
            spec.includeUpdateSequenceNum = true
            spec.includeUpdated = true
            spec.includeDeleted = true
            spec.includeTitle = true
            store.findNotesMetadata(filter, 0, 100, spec,
                (err, li) ->
                    console.log err, li
                    for note in li.notes
                        console.log note.title

                    options.success ''
                )
        )

    @update: (params, options) ->
        site_id = params.site_id
        delete params.site_id
        _oauth_get(params, (store)->
            query = EvernoteSync.$
            query.equalTo('oauth_id', params.id)

            query.first({
                success:(evernote_sync) ->
                    if evernote_sync
                        #words = """updated:#{evernote_sync.get('updated') - 1}"""
                        words = """"""
                        update_count = evernote_sync.get('update_count')
                        console.log 'everid', evernote_sync.id
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
                    limit = 100
                    _ = (offset)->
                        store.findNotesMetadata(filter, offset, limit, spec, (err, li) ->
                            to_update_count = 0
                            if err
                                console.log err
                                return
                            for note in li.notes
                                if note.updateSequenceNum > update_count
                                    to_update_count += 1
                                    store.getNote(note.guid, true, true, false, false, (err, full_note) ->
                                        if err
                                            console.log err
                                            return
                                        else
                                            guid = full_note.guid
                                            console.log guid
                                            post = new DB.PostHtml()
                                            post.$set('title', full_note.title)
                                            post.$set('html', full_note.content)
                                            post.$save()
                                            EvernotePost.new(guid, post)
                                            evernote_sync.increment('count')
                                            evernote_sync.save()
                                    )
                            if to_update_count
                                _(offset+limit)
                            else
                                console.log 'todo!!'
                                #todo
                                #EvernoteSync.new(params)
                            )
                    _ 0

            error:(err) ->
                console.log 'EvernoteSync'
                EvernoteSync.new(params)
            })
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

    @new: (guid, post) ->
        EvernotePost.$.get_or_create({
            guid
            post
        }, {
            create: (o) ->
                console.log 'create'
                o.set('guid', guid)
                o.set('post', post)
            success: (o) ->
                o.get('post').fetch({
                    success: (p) ->
                        p.set('title', post.title)
                        p.set('html', post.html)
                })
                o.save()
        })
