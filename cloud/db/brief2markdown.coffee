to_markdown = require('to-markdown')

module.exports = (html) ->
    regexp = """</p><p>\\s*===\\s*</p><p>"""
    split = new RegExp(regexp,"g")
    result = split.exec(html)
    if result
        r = result[0]
        brief = html.slice(0, split.lastIndex-r.length+4)
        body = html.slice(split.lastIndex-3)
        brief = to_markdown(brief, {
            converters:[
                {
                    filter:"span"
                    replacement:(innerHTML)->
                        return innerHTML
                }
                {
                    filter:"p"
                    replacement:(innerHTML)->
                        return "\n"+innerHTML+"\n"
                }
            ]
        })
    else
        brief = ''
        body = html
    return [brief , body]
