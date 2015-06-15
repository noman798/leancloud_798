$ = require "underscore"
require "cloud/db/site"
DB = require "cloud/_db"

DB class SiteTagPostCount
    constructor : (
        @site
        @tag
        @count
    )->
        super

    @incr : (site, tag, value=1) ->
        SiteTagPostCount.$.get_or_create({
            site
            tag
        }, {
            create:(o)->
                o.set('count',0)
            success:(o)->
                o.increment('count',value)
                o.save()
        })


    @decr : (site, tag) ->
        @incr site, tag, -1


_after = (value)->
    (request)->
        tag_post = request.object
        site = tag_post.get('site')
        site.fetch().done ->
            todo = []
            for tag in tag_post.get('tag_list')
                todo.push SiteTagPostCount.incr(site, tag,value)
            AV.Promise.when(todo).done ->
                site.increment('count', value)
                site.save()


AV.Cloud.afterSave 'SiteTagPost', _after(1)
AV.Cloud.afterDelete 'SiteTagPost', _after(-1)
