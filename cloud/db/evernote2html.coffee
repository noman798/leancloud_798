
config = require 'cloud/config'
replaceAll = require 'underscore.string/replaceAll'
strLeft = require 'underscore.string/strLeft'
strLeftBack = require 'underscore.string/strLeftBack'
strRight = require 'underscore.string/strRight'
endsWith = require 'underscore.string/endsWith'
startsWith = require 'underscore.string/startsWith'
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
        console.log content
        for i in params
            hash = new Buffer(i.data.bodyHash).toString('hex')
            from_str = """<en-media hash="#{hash}" type="#{i.mime}"></en-media>"""
            to_str = """<img src="#{config.QINIU.HTTP}#{i.key}"/>"""
            content = replaceAll(content, from_str, to_str)

        html = enml.HTMLOfENML content, full_note.resources
        html = strLeft(html,"</body>")
        html = strRight(strRight(html,"<body"),">")

        html = replaceAll(html, "<div","<p")
        html = replaceAll(html, "</div>","</p>")
        br = '<p><br clear="none"/></p>'
        while 1
            _html = html
            _html = replaceAll(_html, '''<p><p>''',"<p>")
            _html = replaceAll(_html, '''</p></p>''',"</p>")
            if endsWith(_html, '<p></p>')
                _html = strRight(_html, '<p></p>')
            if startsWith(_html, br)
                _html = strRight(_html, br)
            if endsWith(_html, br)
                _html = strLeftBack(_html, br)
            if _html == html
                break
            html = _html

        html = replaceAll(html, '''</p><p><br clear="none"/></p>''',"</P>")
        html = replaceAll(html, '''<br clear="none"><br>''',"<br>")
        html = replaceAll(html, '''</p><p>''',"<br>")
        html = replaceAll(html, '''</P>''',"</p>")


        callback html

    
