from config import CONFIG
from leancloud import Object, Query , init

CLASS = "Post SitePostTag Site"


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
    print name
    cls = Object.extend(name)
    setattr(DB, name, cls)
    setattr(_Q,name, _query_property(cls))



if __name__ == "__main__":
    print DB.Post
    print Q.Post.find()
