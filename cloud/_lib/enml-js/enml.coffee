do ->
  XMLWriter = undefined
  SaxParser = undefined
  #Node JS
  # Convert Uint8Array to base64 string
  #  https://gist.github.com/jonleighton/958841

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
      # 258048   = (2^6 - 1) << 12
      c = (chunk & 4032) >> 6
      # 4032     = (2^6 - 1) << 6
      d = chunk & 63
      # 63       = 2^6 - 1
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
      # 3   = 2^2 - 1
      base64 += encodings[a] + encodings[b] + '=='
    else if byteRemainder == 2
      chunk = bytes[mainLength] << 8 | bytes[mainLength + 1]
      a = (chunk & 64512) >> 10
      # 64512 = (2^6 - 1) << 10
      b = (chunk & 1008) >> 4
      # 1008  = (2^6 - 1) << 4
      # Set the 2 least significant bits to zero
      c = (chunk & 15) << 2
      # 15    = 2^4 - 1
      base64 += encodings[a] + encodings[b] + encodings[c] + '='
    base64

  ###*
  * ENMLOfPlainText
  * @param  { string } text (Plain)
  * @return string - ENML
  ###

  ENMLOfPlainText = (text) ->
    writer = new XMLWriter
    writer.startDocument = writer.startDocument or writer.writeStartDocument
    writer.endDocument = writer.endDocument or writer.writeEndDocument
    writer.startDocument = writer.startElement or writer.writeStartElement
    writer.startDocument = writer.endElement or writer.writeEndElement
    writer.startDocument '1.0', 'UTF-8', false
    writer.write '<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">'
    writer.write '\n'
    writer.startElement 'en-note'
    writer.writeAttribute 'style', 'word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;'
    lines = text.match(/^.*((\r\n|\n|\r)|$)/gm)
    lines.forEach (line) ->
      writer.text '\n'
      writer.startElement 'div'
      writer.text line.replace(/(\r\n|\n|\r)/, '')
      writer.endElement()
      return
    writer.text '\n'
    writer.endElement()
    writer.endDocument()
    writer.toString()

  ###*
  * PlainTextOfENML
  * @param  { string } text (ENML)
  * @return string - text
  ###

  PlainTextOfENML = (enml) ->
    text = enml or ''
    text = text.replace(/(\r\n|\n|\r)/gm, ' ')
    text = text.replace(/(<\/(div|ui|li|p|table|tr|dl)>)/ig, '\n')
    text = text.replace(/^\s/gm, '')
    text = text.replace(/(<(li)>)/ig, ' - ')
    text = text.replace(/(<([^>]+)>)/ig, '')
    text = text.trim()
    text

  ###*
  * HTMLOfENML
  * Convert ENML into HTML for showing in web browsers.
  *
  * @param { string } text (ENML)
  * @param  { Map <string (hash), url (string) || { url: (string), title: (string) } >, Optional } resources
  * @return string - HTML
  ###

  HTMLOfENML = (text, resources) ->
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
      cb.onStartElementNS (elem, attrs, prefix, uri, namespaces) ->
        if elem == 'en-note'
          writer.startElement 'html'
          writer.startElement 'head'
          writer.startElement 'meta'
          writer.writeAttribute 'http-equiv', 'Content-Type'
          writer.writeAttribute 'content', 'text/html; charset=UTF-8'
          writer.endElement()
          writer.endElement()
          writer.startElement 'body'
          if !(attrs and attrs[0] and attrs[0][0] and attrs[0][0] == 'style')
            writer.writeAttribute 'style', 'word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;'
        else if elem == 'en-todo'
          writer.startElement 'input'
          writer.writeAttribute 'type', 'checkbox'
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
            writer.text 'Your browser does not support the audio tag.'
            writer.startElement 'source'
            mediaTagStarted = true
          else if type.match('video')
            writer.writeElement 'p', resourceTitle
            writer.startElement 'video'
            writer.writeAttribute 'controls', ''
            writer.text 'Your browser does not support the video tag.'
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
          writer.endElement()
          #body
          writer.endElement()
          #html
        else if elem == 'en-todo'
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
        writer.text chars
        return
      return
)
    parser.parseString text
    writer.toString()

  ###*
  * TodosOfENML
  * Extract data of all TODO(s) in ENML text.
  *
  * @param { string } text (ENML)
  * @return { Array [ { text: (string), done: (bool) } ] } -
  ###

  TodosOfENML = (text) ->
    todos = []
    parser = new SaxParser((cb) ->
      `var text`
      onTodo = false
      text = null
      checked = false
      cb.onStartElementNS (elem, attrs, prefix, uri, namespaces) ->
        m = elem.match(/b|u|i|font|strong/)
        if m and elem == m[0]
        else if elem == 'en-todo'
          checked = false
          text = ''
          onTodo = true
          if attrs
            attrs.forEach (attr) ->
              if attr[0] == 'checked' and attr[1] == 'true'
                checked = true
              return
        else
          if onTodo
            todos.push
              text: text
              checked: checked
          onTodo = false
        return
      cb.onEndElementNS (elem, prefix, uri) ->
      cb.onCharacters (chars) ->
        if onTodo
          text += chars
        return
      cb.onEndDocument ->
        if onTodo
          todos.push
            text: text
            checked: checked
        return
      return
)
    parser.parseString text
    todos

  ###*
  * CheckTodoInENML
  * Rewrite ENML content by changing check/uncheck value of the TODO in given position.
  *
  * @param { string } text (ENML)
  * @param { int }  index
  * @param { bool } check
  * @return string - ENML (the new content)
  ###

  CheckTodoInENML = (text, index, check) ->
    todo_cout = 0
    writer = new XMLWriter
    parser = new SaxParser((cb) ->
      cb.onStartElementNS (elem, attrs, prefix, uri, namespaces) ->
        writer.startElement elem
        if elem == 'en-todo' and index == todo_cout++
          if attrs
            attrs.forEach (attr) ->
              if attr[0] == 'checked'
                return
              writer.writeAttribute attr[0], attr[1]
              return
          if check
            writer.writeAttribute 'checked', 'true'
        else
          if attrs
            attrs.forEach (attr) ->
              writer.writeAttribute attr[0], attr[1]
              return
        return
      cb.onEndElementNS (elem, prefix, uri) ->
        writer.endElement()
        return
      cb.onCharacters (chars) ->
        writer.text chars
        return
      return
)
    parser.parseString text
    writer.toString()

  XMLWriter = require('./lib/xml-writer')
  SaxParser = require('./lib/xml-parser').SaxParser
  exports.ENMLOfPlainText = ENMLOfPlainText
  exports.HTMLOfENML = HTMLOfENML
  exports.PlainTextOfENML = PlainTextOfENML
  exports.TodosOfENML = TodosOfENML
  exports.CheckTodoInENML = CheckTodoInENML
  return
