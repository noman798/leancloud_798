require "cloud/db/oauth"
DB = require "cloud/_db"
Evernote = require('evernote').Evernote
{Thrift,NoteStoreClient} = Evernote

_oauth_get = (params, callback)->
    DB.Oauth.$.get(params.id, {
        success: (oauth) ->
            meta = oauth.get('meta')
            transport = new Thrift.NodeBinaryHttpTransport(meta.store_url)
            protocol = new Thrift.BinaryProtocol(transport)
            store = new NoteStoreClient(protocol)
            callback(oauth.get('token'), store)
    })

DB class SyncEvernote
    @sync:(params, options) ->
        _oauth_get(params, (token, store)->
            #标签 SITE.NAME 不区分大小写
            store.listNotebooks(
                token
                (error, li) ->
                    console.log li
                    for i in li
                        console.log i
                    options.success li
            )
        )

    @search:(params, options) ->
        _oauth_get(params, (token, store)->
            console.log '1'
            filter = new Evernote.NoteFilter()
            filter.words = 'tag:"test 1"'

            console.log '2'
            spec = new Evernote.NotesMetadataResultSpec()
            spec.includeTitle = true

            console.log '3'
            store.findNotesMetadata(token, filter, 0, 100, spec,
                (err, li) ->
                    console.log err
                    console.log li
                    for note in li.notes
                        console.log note.title
                    options.success ''
                )
        )
