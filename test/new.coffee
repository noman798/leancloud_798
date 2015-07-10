
_site_new = (host, options)->
    Site.by_host {host:host}, success:(site) ->
        if site
            site.set options
            site.save()
        else
            Site.new {
                name:options.name
                owner:""
                slogo:""
                logo:""
                tag_list:""
                name_cn:"天使汇 · 程序部"
            }
            Site.host_new {
                options
            } ,{
                success:(site)->
                    console.log site
            }

_site_new(
    "tech2ipo.com"
    {
        name:"TECH2IPO"
        slogo:"「 创造 & 见证 」"
        logo:"//dn-acac.qbox.me/tech2ipoTECH2IPOIcon.svg"

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
