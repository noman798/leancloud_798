require "cloud/db/post"
require "cloud/db/oauth"
require "cloud/db/post_star"
require "cloud/db/user_read"
require "cloud/db/sync"
require "cloud/db/site_user_level"
require "cloud/db/post_inbox"
DB = require "cloud/_db"

View = require "cloud/_view"

View.Logined DB.PostHtml.VIEW
View.Logined DB.PostChat.VIEW
View.Logined DB.PostStar.VIEW
View.Logined DB.PostTxt.VIEW
View.Logined DB.EvernoteSync.VIEW
View.Logined DB.UserRead.VIEW
View.Logined DB.Oauth.VIEW
View.Logined DB.SiteUserLevel.VIEW
View.Logined DB.PostInbox.VIEW
View DB.PostTxt.VIEW
View DB.SiteTagPost.VIEW
View DB.Post.VIEW
View DB.Post.VIEW
