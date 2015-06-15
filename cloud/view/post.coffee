require "cloud/db/post"
require "cloud/db/post_star"
require "cloud/db/user_read"
require "cloud/db/sync"
DB = require "cloud/_db"

View = require "cloud/_view"

View.Logined DB.PostHtml.VIEW
View.Logined DB.PostChat.VIEW
View.Logined DB.PostStar.VIEW
View.Logined DB.PostTxt.VIEW
View.Logined DB.SyncEvernote.VIEW
View.Logined DB.UserRead.VIEW
View DB.PostTxt.VIEW
View DB.SiteTagPost.VIEW
View DB.Post.VIEW
