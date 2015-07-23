from config import CONFIG

leancloud.init(ID, MASTER_KEY)    # leancloud config
Post = Object.extend('Post')
SiteTagPost = Object.extend('SiteTagPost')
Site = Object.extend('Site')
post_query = Query(Post)
site_query = Query(Site)
