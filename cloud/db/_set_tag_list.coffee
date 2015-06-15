
require "cloud/db/post"
DB = require "cloud/_db"

module.exports = (site, post_list, success)->
    post_dict = {}
    to_fetch = []
    for post in post_list
        post_dict[post.id] = post
        query = DB.SiteTagPost.$
        query.equalTo(
            {site, post}
        )
        to_fetch.push query.first()

    AV.Promise.when(to_fetch).done (site_tag_list...)->
        for i in site_tag_list
            post_dict[i.get('post').id].set('tag_list',i.get('tag_list'))
        success post_list
