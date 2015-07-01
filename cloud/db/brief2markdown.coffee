to_markdown = require('to-markdown')

module.exports = (html) ->
    regexp = """</div><div>\\s*===\\s*</div><div>"""
    split = new RegExp(regexp,"g")
    result = split.exec(html)
    if result
        r = result[0]
        brief = html.slice(0, split.lastIndex-r.length+6)
        body = html.slice(split.lastIndex-5)
        brief = to_markdown(brief, {
            converters:[
                {
                    filter:"div"
                    replacement:(innerHTML)->
                        return "\n"+innerHTML+"\n"
                }
            ]
        })
    else
        brief = ''
        body = html
    return [brief , body]



