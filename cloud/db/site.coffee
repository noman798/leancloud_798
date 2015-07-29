$ = require "underscore"
$.mixin(require("underscore.string").exports())

require "cloud/db/custom_css"

SITE_USER_LEVEL = require "cloud/db/site_user_level"
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
        @link_list
        @favicon
        @description
        @default_host
        @baidu_code
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

    @_site_new : (owner_id, host, options, css)->
        console.log "new site "+host
        owner = AV.Object.createWithoutData('User', owner_id)

        _callback = (site)->
            DB.CustomCss._set(site.id, css)
            DB.SiteUserLevel._set owner_id, site.id, SITE_USER_LEVEL.ROOT

        DB.Site.by_host {host:host}, success:(site) ->
            if site
                options.owner = owner
                site.set options
                site.save()
                _callback site
            else
                DB.Site.new {
                    name:options.name
                    owner:owner
                    slogo:options.slogo
                    logo:options.logo
                    tag_list:options.tag_list
                    name_cn:options.name_cn
                    favicon:options.favicon
                    link_list:options.link_list
                }, success:(site)->
                    DB.Site.host_new {
                        host
                        id:site.id
                    } ,{
                        success:(site_host)->
                            _callback site
                    }
