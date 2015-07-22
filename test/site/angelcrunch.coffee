require "cloud/db/site"
DB = require "cloud/_db"

#USER_ID = "559bbcb4e4b023682f148e98"
USER_ID = "556eb0b8e4b0925e000409b9"


DB.Site._site_new(
    USER_ID
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
        tag_list:["招聘" ,"教程", "转载",]
    }
"""
#BODY .Rbar > .bg { background-image: url(//dn-noman.qbox.me/ewbgss); }
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
