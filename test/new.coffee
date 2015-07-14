require "cloud/db/site"
require "cloud/db/custom_css"
DB = require "cloud/_db"

USER_ID = "559bbcb4e4b023682f148e98"

owner = AV.Object.createWithoutData('User', USER_ID)
_site_new = (host, options, css)->
    console.log "new site "+host
    DB.Site.by_host {host:host}, success:(site) ->
        if site
            options.owner = owner
            site.set options
            site.save()
            DB.CustomCss._set(site.id, css)
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
                    id:site.id
                } ,{
                    success:(site_host)->
                        console.log "site_host set", host
                }
                DB.CustomCss._set(site.id, css)

_site_new(
    "coder.angelcrunch.com"
    {
        name:"AngelCrunch"
        name_cn:"天使汇 · 程序部"
        slogo:"「 天使汇 · 程序部 」"
        logo:"//dn-noman.qbox.me/ac_logo.svg"
        link_list: [
            [ "email" , "TECH2IPO@PE.VC"],
            [ "twitter" , "http://twitter.com/TECH2IPO"],
            [ "weibo" , "http://weibo.com/tech2ipo"],
            [ "weixin" , "//dn-acac.qbox.me/tech2ipoqrcode.jpg"],
        ]
        tag_list:["系列教程", "招人启事"]
    }
    """
#BODY .Rbar > .bg {
background-image: url(//dn-noman.qbox.me/ewbgss);
}
#BODY > .Rbar .Rbody .scrollbar-macosx .body .profile .logo .bg {
background: -webkit-gradient(linear, left top, left bottom, color-stop(0, #F00), color-stop(50%, #d00), to(#a00));
background: -webkit-linear-gradient(top, #F00 0, #d00 50%, #a00 100%);
background: linear-gradient(top, #F00 0, #d00 50%, #a00 100%);
}
#BODY > .Rbar .cover0 {
background: RGBA(0, 0, 0, 0.3) !important;
}
#BODY > .Rbar .Rbody .scrollbar-macosx .body .profile .logo .bg .svg {
left: 0;
}
    """
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
        tag_list:["每日资讯","深度观点","人物特写","公司行业","产品快报"]
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
