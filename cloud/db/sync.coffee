require "cloud/db/oauth"
DB = require "cloud/_db"
Evernote = require('evernote').Evernote
{Thrift,NoteStoreClient, Client} = Evernote

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
            filter.words = 'tag:"tech2ipo" tag:"发布"'

            spec = new Evernote.NotesMetadataResultSpec()
            spec.includeUpdateSequenceNum = true
            spec.includeUpdated = true
            #spec.includeTitle = true

            store.findNotesMetadata(filter, 0, 100, spec,
                (err, li) ->
                    console.log li
                    for note in li.notes
                        console.log note.title
                    options.success ''
                )
        )
