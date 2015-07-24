#!/usr/bin/env python
# coding=utf-8

from db import Q, DB, redis
import io
import glob
import os
import re
import time
import gzip
import leancloud
from config import CONFIG
from lxml import etree
from collections import defaultdict
from distutils.dir_util import mkpath
from os.path import join, abspath, realpath, exists, getsize, dirname 
from single_process import single_process

R_SITEMAP_SINCE = "SitemapSince"

def generate_xml(filename, url_list):
    with gzip.open(filename,"w") as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n""")
        for i in url_list:
            f.write("""<url><loc>%s</loc></url>\n"""%i)
        f.write("""</urlset>""")


def append_xml(filename, url_list):
    with gzip.open(filename, 'r') as f:
        for each_line in f:
            d = re.findall('<loc>(http:\/\/.+)<\/loc>', each_line)
            url_list.extend(d)

        generate_xml(filename, set(url_list))

def modify_time(filename):
    time_stamp = os.path.getmtime(filename)
    t = time.localtime(time_stamp)
    return time.strftime('%Y-%m-%dT%H:%M:%S:%SZ', t)

def new_xml(filename, url_list):
    generate_xml(filename, url_list)
    root = dirname(filename)

    with open(join(dirname(root), "sitemap.xml"),"w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n')
        for i in glob.glob(join(root,"*.xml.gz")):
            lastmod = modify_time(i)
            i = i[len(CONFIG.SITEMAP_PATH):]
            f.write("<sitemap>\n<loc>http:/%s</loc>\n"%i)
            f.write("<lastmod>%s</lastmod>\n</sitemap>\n"%lastmod)
        f.write('</sitemapindex>')

def sitemap(path, host, li):
    filelist = [
        int(i.rsplit("/", 1)[-1][:-7])
        for i in glob.glob(join(path,"sitemap/*.xml.gz"))
    ]
    filelist.sort()
    if filelist:
        id = filelist[0]
    else:
        id = 1

    filepath = join(path,"sitemap",str(id)+".xml.gz")
    if exists(filepath) and getsize(filepath) < 5*1024*1024:
        func = append_xml
    else:
        id += 1
        func = new_xml 

    filepath = join(path,"sitemap",str(id)+".xml.gz")

    func(filepath, ["http://%s/%s"%(host,i) for i in li])



def the_end(site_post):
    for site_id, li in site_post.iteritems():
        for i in Q.SiteHost.equal_to("site", DB.Site.create_without_data(site_id)).find():
            host = i.get('host')
            path = join(CONFIG.SITEMAP_PATH, host) 
            mkpath(join(path, "sitemap"))
            sitemap(path, host, li)


def update(last_id, site_post, limit=100):
    query = Q.SiteTagPost
    query.ascending('ID')
    query.greater_than('ID', last_id)
    query.limit(limit)
    r = query.find()
    if r:
        post_id_set = set()
        for i in r:
            post_id = i.get('post').id
            post_id_set.add(post_id)

        post_list = Q.Post.contained_in("objectId",
                                        list(post_id_set)).select('ID').find()
        post_dict = dict((i.id, i.get('ID')) for i in post_list)

        for i in r:
            site_post[i.get('site').id].append(
                post_dict[i.get('post').id]
            )

        last_id = r[-1].get('ID')
        print sum(len(i) for i in site_post.itervalues())
        if len(r) >= limit and sum(len(i) for i in site_post.itervalues())<1000000:
            update(last_id, site_post)
            return

    the_end(site_post)
    redis.set(R_SITEMAP_SINCE, last_id)


@single_process
def main():
    #redis.delete(R_SITEMAP_SINCE) #TODO comment
    #return

    last_id = int(redis.get(R_SITEMAP_SINCE) or 0)
    print "last_id",last_id
    update(
        last_id,
        defaultdict(list)
    )

if __name__ == '__main__':
    main()
