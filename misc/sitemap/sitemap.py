#!/usr/bin/env python
# coding=utf-8

from db import Q, DB, redis
import io
import glob
import os
import re
import leancloud
from config import CONFIG
from lxml import etree
from collections import defaultdict
from distutils.dir_util import mkpath
from os.path import join, abspath, realpath, exists, getsize 
from single_process import single_process

R_SITEMAP_SINCE = "SitemapSince"

def generate_xml(filename, url_list):
    with open(filename,"w") as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">""")
        for i in url_list:
            f.write("""<url><loc>%s</loc></url>"""%i)
        f.write("""</urlset>""")


def append_xml(filename, url_list):
    with open(filename, 'r') as f:

        for each_line in f:
            d = re.findall('<loc>(http:\/\/.+)<\/loc>', each_line)
            url_list.extend(d)

        url_list.extend(old_url_list)
        generate_xml(filename, url_list)


def sitemap(path, host, li):
    filelist = [
        int(i.rsplit("/", 1)[-1][:-4])
        for i in glob.glob(join(path,"sitemap/*.xml"))
    ]
    filelist.sort()
    if filelist:
        id = filelist[0]
    else:
        id = 1

    filepath = join(path,"sitemap",str(id)+".xml")
    if exists(filepath) and getsize(filepath) > 8*5*1024:#*1024*8:
        func = append_xml
    else:
        func = generate_xml

    func(filepath, ["http://%s/%s"%(host,i) for i in li])



def generatr_xml_index(filename, sitemap_list, lastmod_list):
    """Generate sitemap index xml file."""
    root = etree.Element('sitemapindex',
                         xmlns="http://www.sitemaps.org/schemas/sitemap/0.9")
    for each_sitemap, each_lastmod in zip(sitemap_list, lastmod_list):
        sitemap = etree.Element('sitemap')
        loc = etree.Element('loc')
        loc.text = each_sitemap
        lastmod = etree.Element('lastmod')
        lastmod.text = each_lastmod
        sitemap.append(loc)
        sitemap.append(lastmod)
        root.append(sitemap)

    header = u'<?xml version="1.0" encoding="UTF-8"?>\n'
    s = etree.tostring(root, encoding='utf-8', pretty_print=True)
    with io.open(filename, 'w', encoding='utf-8') as f:
        f.write(unicode(header+s))


def the_end(site_post):
    for site_id, li in site_post.iteritems():
        for i in Q.SiteHost.equal_to("site", DB.Site.create_without_data(site_id)).find():
            host = i.get('host')
            path = join(CONFIG.SITEMAP_PATH, host) 
            mkpath(join(path, "sitemap"))
            sitemap(path, host, li)


def update(last_id, site_post, limit=500):
    query = Q.SiteTagPost
    query.ascending('ID')
    query.greater_than('ID', last_id)
    query.limit(limit)
    r = query.find()
    if r:
        post_id_set = set()
        for i in r:
            post_id = i.get('post').id
            print post_id
            post_id_set.add(post_id)

        post_list = Q.Post.contained_in("objectId",
                                        list(post_id_set)).select('ID').find()
        post_dict = dict((i.id, i.get('ID')) for i in post_list)

        for i in r:
            site_post[i.get('site').id].append(
                post_dict[i.get('post').id]
            )

        last_id = r[-1].get('ID')

        if len(r) >= limit and len(r)<1000000:
            update(last_id, site_post)
            return

    the_end(site_post)
    redis.set(R_SITEMAP_SINCE, last_id)


@single_process
def main():
    redis.delete(R_SITEMAP_SINCE) #TODO comment

    last_id = int(redis.get(R_SITEMAP_SINCE) or 0)
    update(
        last_id,
        defaultdict(list)
    )

if __name__ == '__main__':
    main()
