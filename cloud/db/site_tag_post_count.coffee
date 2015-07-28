$ = require "underscore"
require "cloud/db/site"
DB = require "cloud/_db"

redis = require "cloud/_redis"
{R} = redis

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
        _pub(request)
        tag_post = request.object
        site = tag_post.get('site')
        site.fetch().done ->
            todo = []
            for tag in tag_post.get('tag_list')
                todo.push SiteTagPostCount.incr(site, tag,value)
            AV.Promise.when(todo).done ->
                site.increment('count', value)
                site.save()


_pub = (request) ->
    site_tag_post = request.object
    post = site_tag_post.get('post')
    post.fetch().done ->
        site = site_tag_post.get('site')
        site.fetch().done ->


            site_name = site.get('name')
            site_host = site.get('default_host')

            post_ID = post.get('ID')
            post_url = 'http://' + site_host + '/' + post_ID
            rss_url = 'http://' + site_host + '/rss/' + site_host

            msg = JSON.stringify(
                {
                    site_name
                    site_host
                    post_url
                    rss_url
                }
            )
            redis.publish 'ping', msg


AV.Cloud.afterSave 'SiteTagPost', _after(1)
#AV.Cloud.afterSave 'SiteTagPost', _pub
AV.Cloud.afterDelete 'SiteTagPost', _after(-1)
