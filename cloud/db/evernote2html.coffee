
config = require 'cloud/config'
replaceAll = require 'underscore.string/replaceAll'
strLeft = require 'underscore.string/strLeft'
strRight = require 'underscore.string/strRight'
strLeftBack = require 'underscore.string/strLeftBack'
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
        html = replaceAll(html, "<div","<p")
        html = replaceAll(html, "</div>","</p>")
       
        while 1
            _html = strLeftBack(html, '<p><br clear="none"/></p>')
            if _html == html
                break
            html = _html


        html = replaceAll('''</p><p><br clear="none"/></p>''',"</P>")
        html = replaceAll('''</p><p>''',"<br>")
        html = replaceAll('''<P>''',"</p>")

        #html = replaceAll(html,'<p><br clear="none"/></p>', '')


        callback html

    
