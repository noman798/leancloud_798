###
{id_b65, b64_id, num_b64} = require 'cloud/_lib/b64'

console.log b64_id id_b64('55892bafe4b0416bdfc44c89')
console.log num_b64 1000

redis = require "cloud/_redis"
{R} = redis
R "PostStar"
setTimeout(
    ->
        console.log R.PostStar
        redis.smismember R.PostStar+'-'+"5554f671e4b076f1c3451b9b", [ 99289, 99286, 99285, 99284, 99283, 99281, 99280, 99278, 99277, 99276, 99272, 99269, 99268, 99267, 99266, 99261, 99253, 99251, 99250, 99249 ], (err, result)->
            console.log err, result
    1000
)

###
app = require 'app'
require 'cloud/db/sync'
require 'cloud/db/oauth'
qiniu_token = require 'cloud/db/qiniu_token'
qiniu = require 'qiniu'
enml = require 'enml-js'
Q = require "q"
Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote

main = ->
    qiniu_upload = (body, mime)  ->
        Q.Promise (resolve)->
            token = qiniu_token()
            extra = new qiniu.io.PutExtra()
            extra.mimeType = mime
            qiniu.io.put(
                token
                null
                body
                extra
                (err, ret) ->
                    resolve(ret)
            )

    client = new Client(
        token:"S=s1:U=90fbf:E=1556329e2aa:C=14e0b78b568:P=185:A=noman:V=2:H=24ade0617d86afd0634793770fd6ddc7"
        serviceHost:'sandbox.evernote.com'
    )
    store = client.getNoteStore()
    guid = "c8f8d8c0-ac9d-4a18-8ac0-00ac11d0c7c1"
    store.getNote(guid, true, true, true, false, (err, full_note) ->
        to_fetch = []
        for i,_ in full_note.resources
            to_fetch.push qiniu_upload(i.data.body,i.mime)

        Q.when(to_fetch).then (params...)->
            console.log params
    )
    


main()
