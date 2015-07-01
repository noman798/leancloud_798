app = require 'app'

brief2markdown = require "cloud/db/brief2markdown"
console.log brief2markdown(
    """<div>天问我</div><div>===   </div><div>张沈鹏</div>"""
)


