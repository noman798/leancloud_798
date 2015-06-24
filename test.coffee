app = require 'app'
require 'cloud/db/sync'
require 'cloud/db/oauth'
qiniu_token = require 'cloud/db/qiniu_token'
qiniu = require 'qiniu'
enml = require 'enml-js'
Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote

main = ->
    uploadBuf = (body, key, uptoken)  ->
        extra = new qiniu.io.PutExtra()
        extra.mimeType = 'image/png'
        qiniu.io.put(uptoken, key, body, extra, (err, ret) ->
            if !err
                console.log ret.key, ret.hash
            else
                console.log err
        )
    client = new Client(
        token:"S=s1:U=90fbf:E=1556329e2aa:C=14e0b78b568:P=185:A=noman:V=2:H=24ade0617d86afd0634793770fd6ddc7"
        serviceHost:'sandbox.evernote.com'
    )
    store = client.getNoteStore()
    guid = "c8f8d8c0-ac9d-4a18-8ac0-00ac11d0c7c1"
    store.getNote(guid, true, true, true, false, (err, full_note) ->
        img = full_note.resources[0].data.body
        console.log qiniu.conf.ACCESS_KEY
        uploadBuf(img, qiniu.conf.ACCESS_KEY, qiniu_token())
        console.log qiniu_token()
    )
    

    #console.log enml.HTMLOfENML html

main()
