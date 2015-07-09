$ = require "underscore"
$.mixin(require("underscore.string").exports())

DB = require "cloud/_db"

DB class SiteRss
    constructor : (
        @url
    )->
        super

    @by_url : (url, options)->
        options.create = (rss)->
            acl = new AV.ACL()
            acl.setPublicReadAccess true
            acl.setPublicWriteAccess false
            rss.setACL acl

        SiteRss.$.get_or_create {
            url:url
        }, options

DB class SiteHost
    constructor : (
        @site
        @host
    )->
        super

DB class Site
    constructor : (
        @name
        @owner
        @slogo
        @logo
        @tag_list
        @name_cn
    )->
        super

    @tag_list_set: (params, options)->
        Site.$.get(params.id).done (site)->
            site.set('tag_list', params.tag_list)
            site.save success:options.success


    @new : (params, options) ->
        params.owner = AV.User.current()
        site = new Site()
        site.$set params
        site.$setACL()
        site.$save success:options.success
   
    @host_new : (params, options)->
        host = $.trim(params.host.toLowerCase())

        Site.by_host {host:host}, {
            success:(site)->
                if site
                    options.error(site)
                else
                    site = AV.Object.createWithoutData("Site", params.id)
                    site_host = DB.SiteHost {
                        site
                        host
                    }
                    site_host.$setACL()
                    site_host.$save success:options.success

        }

    @by_host:(params, options)->
        host = $.trim(params.host.toLowerCase())
        query = SiteHost.$
        query.equalTo({host:host})
        query.first {
            error : (_error)->
                if _error?.code == 101
                    options.success()
                else
                    console.log _error
                    if options.error
                        options.error _error
            success:(site_host)->
                if site_host
                    site = site_host.get('site')
                    site.fetch(
                        success:options.success
                    )
                else
                    options.success()
        }

        
    @by_rss:(params, options)->
        query = SiteRss.$
        query.equalTo(params)
        query.first {
            success:(rss)->
                if rss
                    query = rss.relation('site').query()
                    query.equalTo(owner:AV.User.current())
                    query.first {
                        success:options.success
                        error:(_error)->
                            if _error?.code == 101
                                options.success()
                            else
                                console.log _error
                                if options.error
                                    options.error _error
                    }
                else
                    options.success()
            error:->
                options.success()
        }

    @rss_new : (params, options)->
        Site.$.get(params.id).done (site)->
            SiteRss.by_url params.url, success:(rss)->
                relation = rss.relation('site')
                relation.add site
                rss.save().done ->
                    options.success rss

