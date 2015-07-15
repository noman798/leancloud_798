require "cloud/db/site"
DB = require "cloud/_db"

#USER_ID = "559bbcb4e4b023682f148e98"
USER_ID = "556eb0b8e4b0925e000409b9"

DB.Site._site_new(
    USER_ID
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
