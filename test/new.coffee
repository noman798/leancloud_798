URL_RSS = "http://rss.tech2ipo.com"
HOST = "tech2ipo.com"

_site_new = (url_rss, options)->
    AV.Cloud.run "Site.by_host", {host:HOST}, success:(site) ->
        if site
            options.success site
        else
            AV.Cloud.run "Site.new",{
                    name:"TECH2IPO"
                    slogo:"创新改变世界 , 我们见证未来"
                    logo:"//dn-xpure.qbox.me/iconfont-shandian.svg"
                },{
                success:(site)->
                    AV.Cloud.run "Site.rss_new", {
                        id:site.objectId
                        url:URL_RSS
                    },{
                        success:->
                            options.success site
                    }
                }

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
