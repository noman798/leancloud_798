
config = require 'cloud/config'
replaceAll = require 'underscore.string/replaceAll'
strLeft = require 'underscore.string/strLeft'
strRight = require 'underscore.string/strRight'
qiniu_token = require 'cloud/db/qiniu_token'
qiniu = require 'qiniu'
enml = require 'enml-js'

Q = require "q"
Evernote = require('evernote').Evernote
{Thrift, NoteStoreClient, Client} = Evernote
qiniu_upload = (i)  ->
    Q.Promise (resolve)->
        token = qiniu_token()
        extra = new qiniu.io.PutExtra()
        extra.mimeType = i.mime
        qiniu.io.put(
            token
            null
            i.data.body
            extra
            (err, ret) ->
                i.key = ret.key
                resolve(i)
        )

module.exports = (full_note, callback)->
    to_fetch = []
    for i,_ in (full_note.resources or [])
        to_fetch.push qiniu_upload(i)
    content = full_note.content

    Q.all(to_fetch).then (params)->
        for i in params
            hash = new Buffer(i.data.bodyHash).toString('hex')
            from_str = """<en-media hash="#{hash}" type="#{i.mime}"></en-media>"""
            to_str = """<img src="#{config.QINIU.HTTP}#{i.key}">"""
            content = replaceAll(content, from_str, to_str)
        html = enml.HTMLOfENML content, full_note.resources
        html = strLeft(html,"</body>")
        html = strRight(strRight(html,"<body"),">")
        callback html

    
