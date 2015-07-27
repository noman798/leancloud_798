SaxParser = require('./lib/xml-parser').SaxParser
XMLWriter = require('./lib/xml-writer')

trim = require("underscore.string/trim")
rtrim = require("underscore.string/rtrim")
replaceAll = require("underscore.string/replaceAll")
startsWith = require("underscore.string/startsWith")
WHITESPACE = "\r\n\t 　 "

blockquote = (line_list)->
    line_list.push ""
    line_list.push "."
    r = ['<p>']
    pre_is_blockquote = 0
    pre_is_empty = 0

    for i in line_list
        #console.log ">",i
        if not trim(i,WHITESPACE).length
            pre_is_empty = 1
            continue
        if pre_is_empty
            r.push "</p>"
        else if r.length > 1
            r.push "<br>"

        if startsWith(i,"    ")
            i = i.slice(4)
            if not pre_is_blockquote
                r.push '<blockquote>'
                pre_is_blockquote = 1
        else
            if pre_is_blockquote
                pre_is_blockquote = 0
                r.push "</blockquote>"

        if pre_is_empty
            r.push "<p>"
            pre_is_empty = 0
        r.push i
        #if i.length
        #    r.push "<br>\n"
        #    pre_is_empty = 0
        #else
        #    pre_is_empty = 1
    r.pop()
    r.pop()

    r.join ''

base64ArrayBuffer = (bytes) ->
    base64 = ''
    encodings = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    byteLength = bytes.byteLength
    byteRemainder = byteLength % 3
    mainLength = byteLength - byteRemainder
    a = undefined
    b = undefined
    c = undefined
    d = undefined
    chunk = undefined
    # Main loop deals with bytes in chunks of 3
    i = 0
    while i < mainLength
        # Combine the three bytes into a single integer
        chunk = bytes[i] << 16 | bytes[i + 1] << 8 | bytes[i + 2]
        # Use bitmasks to extract 6-bit segments from the triplet
        a = (chunk & 16515072) >> 18
        # 16515072 = (2^6 - 1) << 18
        b = (chunk & 258048) >> 12
        # 258048     = (2^6 - 1) << 12
        c = (chunk & 4032) >> 6
        # 4032         = (2^6 - 1) << 6
        d = chunk & 63
        # 63             = 2^6 - 1
        # Convert the raw binary segments to the appropriate ASCII encoding
        base64 += encodings[a] + encodings[b] + encodings[c] + encodings[d]
        i = i + 3
    # Deal with the remaining bytes and padding
    if byteRemainder == 1
        chunk = bytes[mainLength]
        a = (chunk & 252) >> 2
        # 252 = (2^6 - 1) << 2
        # Set the 4 least significant bits to zero
        b = (chunk & 3) << 4
        # 3     = 2^2 - 1
        base64 += encodings[a] + encodings[b] + '=='
    else if byteRemainder == 2
        chunk = bytes[mainLength] << 8 | bytes[mainLength + 1]
        a = (chunk & 64512) >> 10
        # 64512 = (2^6 - 1) << 10
        b = (chunk & 1008) >> 4
        # 1008    = (2^6 - 1) << 4
        # Set the 2 least significant bits to zero
        c = (chunk & 15) << 2
        # 15        = 2^4 - 1
        base64 += encodings[a] + encodings[b] + encodings[c] + '='
    base64


enml2html = (text, resources) ->
    resources = resources or []
    resource_map = {}
    resources.forEach (resource) ->
        hex = [].map.call(resource.data.bodyHash, (v) ->
            str = v.toString(16)
            if str.length < 2 then '0' + str else str
        ).join('')
        resource_map[hex] = resource
        return

    writer = new XMLWriter

    parser = new SaxParser((cb) ->
        mediaTagStarted = false
        linkTagStarted = false
        linkTitle = undefined

        in_blockquote = 0
        blockquote_depth = 0

        cb.onStartElementNS (elem, attrs, prefix, uri, namespaces) ->
            if elem == 'en-note'
                0
            else if (elem == "div") or (elem == 'pre')
                writer.startElement 'div'
                if attrs.length
                    for [k,v] in attrs
                        if k == 'style'
                            v = v.split(";")
                            for i in v
                                [css,value] = i.split(':')
                                if css == "padding-left"
                                    in_blockquote = 1
                    attrs = []
                if in_blockquote
                    blockquote_depth+=1
            else if elem == "br"
                attrs = []
                writer.startElement elem
            else if elem == 'en-media'
            
                type = null
                hash = null
                width = 0
                height = 0
                if attrs
                    attrs.forEach (attr) ->
                        if attr[0] == 'type'
                            type = attr[1]
                        if attr[0] == 'hash'
                            hash = attr[1]
                        if attr[0] == 'width'
                            width = attr[1]
                        if attr[0] == 'height'
                            height = attr[1]
                        return
                resource = resource_map[hash]
                if !resource
                    return
                resourceTitle = resource.title or ''
                if type.match('image')
                    writer.startElement 'img'
                    writer.writeAttribute 'title', resourceTitle
                else if type.match('audio')
                    writer.writeElement 'p', resourceTitle
                    writer.startElement 'audio'
                    writer.writeAttribute 'controls', ''
                    writer.startElement 'source'
                    mediaTagStarted = true
                else if type.match('video')
                    writer.writeElement 'p', resourceTitle
                    writer.startElement 'video'
                    writer.writeAttribute 'controls', ''
                    writer.startElement 'source'
                    mediaTagStarted = true
                else
                    writer.startElement 'a'
                    linkTagStarted = true
                    linkTitle = resourceTitle
                if resource.data.body
                    b64encoded = base64ArrayBuffer(resource.data.body)
                    src = 'data:' + type + ';base64,' + b64encoded
                    writer.writeAttribute 'src', src
                if width
                    writer.writeAttribute 'width', width
                if height
                    writer.writeAttribute 'height', height
            else
                writer.startElement elem
            if attrs
                attrs.forEach (attr) ->
                    writer.writeAttribute attr[0], attr[1]
                    return
            return
        cb.onEndElementNS (elem, prefix, uri) ->
            if elem == 'en-note'
                0
            else if (elem == "div") or (elem == "pre")
                if in_blockquote
                    blockquote_depth-=1
                    if not blockquote_depth
                        in_blockquote = 0
                writer.endElement()
            #else if elem == "br"
            #    writer.text "\n"
            else if elem == 'en-media'
                if mediaTagStarted
                    writer.endElement()
                    # source
                    writer.endElement()
                    # audio or video
                    writer.writeElement 'br', ''
                    mediaTagStarted = false
                else if linkTagStarted
                    writer.text linkTitle
                    writer.endElement()
                    # a
                    linkTagStarted = false
                else
                    writer.endElement()
            else
                writer.endElement()
            return
        cb.onCharacters (chars) ->
            if in_blockquote
                writer.text "    "
            chars = rtrim(chars,"\r\n\t 　")
            if chars.length
                writer.text chars
            return
        return
    )
    parser.parseString text
    html = writer.toString()
    html = replaceAll( html ,"<div>", "")
    html = replaceAll( html ,"</div>", "\n")
    html = replaceAll( html ,"<p>", "")
    html = replaceAll( html ,"</p>", "\n\n")
    html = replaceAll( html ,"<br/>", "\n")
    html = trim(html,"\r\n\t 　")
    html = html.split("\n")
    r = []
    pre = null
    for i in html
        i = rtrim(i,WHITESPACE)
        if pre == "" and i == ""
            continue
        else
            r.push i
            pre = i

    blockquote(r)

#    r = ["<p>"]
#    pre = null
#    for i in html
#        i = trim(i,"\r\n\t 　")
#        if pre == '' and i == ''
#            r.push "</p>\n<p>"
#        else
#            if pre
#                r.push "<br>"
#            r.push i
#        pre = i
#
#    r.join('')+"</p>"

module.exports = enml2html







