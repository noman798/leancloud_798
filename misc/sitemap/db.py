from config import CONFIG
from leancloud import Object, Query , init
from redis import Redis 
redis = Redis(
    host=CONFIG.REDIS.HOST,
    port=CONFIG.REDIS.PORT,
    password=CONFIG.REDIS.PASSWORD
)

CLASS = "Post SiteTagPost Site SiteHost"


init(
    CONFIG.LEANCLOUD.ID, 
    master_key=CONFIG.LEANCLOUD.MASTER_KEY
)


class DB(Object):
    pass

class _Q(object):
    pass

Q = _Q()

def _query_property(cls):
    return property(lambda self:Query(cls))

for name in CLASS.split():
    cls = Object.extend(name)
    setattr(DB, name, cls)
    setattr(_Q,name, _query_property(cls))



if __name__ == "__main__":
    for i in Q.Site.find():
        print Q.Site.get(i.id)
    
