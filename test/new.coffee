require "cloud/db/site"
DB = require "cloud/_db"

owner = AV.Object.createWithoutData('User', "556eb0b8e4b0925e000409b9")

_site_new = (host, options)->
    DB.Site.by_host {host:host}, success:(site) ->
        if site
            site.set options
            site.save()
        else
            DB.Site.new {
                name:options.name
                owner:owner
                slogo:options.slogo
                logo:options.logo
                tag_list:options.tag_list
                name_cn:options.name_cn
                link_list:options.link_list
            }, success:(site)->
                DB.Site.host_new {
                    host
                    site:site.id
                } ,{
                    success:(site_host)->
                        console.log site_host
                }

_site_new(
    "coder.angelcrunch.com"
    {
        name:"AngelCrunch"
        name_cn:"天使汇 · 程序部"
        slogo:"「 天使汇 · 程序部 」"
        logo:"//dn-acac.qbox.me/tech2ipoTECH2IPOIcon.svg"
        link_list: [
            [ "email" , "TECH2IPO@PE.VC"],
            [ "twitter" , "http://twitter.com/TECH2IPO"],
            [ "weibo" , "http://weibo.com/tech2ipo"],
            [ "weixin" , "//dn-acac.qbox.me/tech2ipoqrcode.jpg"],
        ]
    }
)

_site_new(
    "tech2ipo.com"
    {
        name:"TECH2IPO"
        name_cn:"创见"
        slogo:"「 创造 & 见证 」"
        logo:"//dn-acac.qbox.me/tech2ipoTECH2IPOIcon.svg"
        link_list: [
            [ "email" , "TECH2IPO@PE.VC"],
            [ "twitter" , "http://twitter.com/TECH2IPO"],
            [ "weibo" , "http://weibo.com/tech2ipo"],
            [ "weixin" , "//dn-acac.qbox.me/tech2ipoqrcode.jpg"],
        ]
    }
)


#$.SETUP.tech2ipo = ->
#    _site_new URL_RSS, success:(site)->
#        console.log site
#        
#        for host in [
#            "tech2ipo.com"
#            "alpha.tech2ipo.com"
#            "tech2ipo.798.space"
#            "797.space"
#            "798.space"
#            "tech2ipo.797.space"
#            "r.io"
#            "majia.space"
#        ]
#            AV.Cloud.run "Site.host_new" , {
#                id:site.objectId
#                host
#            },{
#                success:(site)->
#                    console.log "host_new success", site.host_list
#                error:(site)->
#                    console.log "host_new error", site
#            }
#        AV.Cloud.run "Site.tag_list_set", {
#            id:site.id
