require "cloud/db/oauth"
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

DB class SyncEvernote
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
            filter.words = 'tag:"tech2ipo" tag:"发布" updated:1434437899001'
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
            filter = new Evernote.NoteFilter()
            # filter.words = 'tag:"tech2ipo" tag:"发布" updated:1434437899001'
            filter.words = 'tag:"tech2ipo" tag:"发布" '
            filter.order = Evernote.NoteSortOrder.UPDATE_SEQUENCE_NUMBER

            spec = new Evernote.NotesMetadataResultSpec()
            spec.includeUpdateSequenceNum = true
            spec.includeUpdated = true
            spec.includeDeleted = true
            spec.includeTitle = true
            store.findNotesMetadata(filter, 0, 100, spec,
                (err, li) ->
                    console.log err, li
                    #console.log li.notes.length
                    for note in li.notes
                        store.getNote(note.guid, true, true, false, false, (err, full_note) ->
                            post = AV.Object.createWithoutData('Post')
                            params = {
                                guid: full_note.guid
                                post: post
                                site: 'tech2ipo'
                                tag_list: full_note.tagNames
                                updated: full_note.updated
                                updatedSequenceNum: full_note.updatedSequenceNum
                            }
                            console.log params.guid
                            PostEvernote.new(params)
                        )
                        options.success 'updateded'
                )
        )

DB class PostEvernote
    constructor : (
        @guid
        @post
        @site
        @tag_list
        @updated
        @updatedSequenceNum
    ) ->
        super

    @new: (params) ->
        PostEvernote.$.get_or_create({
            params
        }, {
            create: (o) ->
                o.set({params})
            success: (o) ->
                o.set('post', params.post)
                o.set('tag_list', params.tag_list)
                o.set('updated', params.updated)
                o.set('updatedSequenceNum', params.updatedSequenceNum)

                o.save()
        })
