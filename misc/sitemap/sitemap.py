#!/usr/bin/env python
#coding=utf-8

import glob
import re
import redis
import leancloud
from lxml import etree
from leancloud import Object, Query
from collections import defaultdict
from distutils.dir_util import mkpath
from os.path import join, abspath, realpath, exist
from single_process import single_process
from config import CONFIG

LIMIT = 500
R_SITEMAP_SINCE = "SitemapSince"
SITE_POST = defaultdict(list)

redis_client = redis.Redis(
    host=CONFIG.REDIS.HOST,
    port=CONFIG.REDIS.PORT
)
LAST_ID = redis_client.get(R_SITEMAP_SINCE)



def generate_xml(filename, url_list):                                            
    """Generate sitemap.xml file."""
    root = etree.Element('urlset',                                               
                         xmlns="http://www.sitemaps.org/schemas/sitemap/0.9")    
    for each in url_list:                                                        
        url = etree.Element('url')                                               
        loc = etree.Element('loc')                                               
        loc.text = each                                                          
        url.append(loc)                                                          
        root.append(url)                                                         
                                                                                 
    header = u'<?xml version="1.0" encoding="UTF-8"?>\n'                         
    s = etree.tostring(root, encoding='utf-8', pretty_print=True)                
    with io.open(filename, 'w', encoding='utf-8') as f:                          
        f.write(unicode(header+s)) 


def append_xml(filename, url_list):                        
    """Add new url_list to origin sitemap.xml file."""    
    f = open(filename, 'r')    
    lines = [i.strip() for i in f.readlines()]                             
    f.close()                                                              
    old_url_list = []                                                      

    for each_line in lines:    
        d = re.findall('<loc>(http:\/\/.+)<\/loc>', each_line)             
        old_url_list += d                                                  

    url_list += old_url_list                                               
    generate_xml(filename, url_list)  


def gen_sitemap(site_name, li):
    path = join(SITEMAP, "_sitemap", site_name)
    filelist = [
            int(i.rsplit("/", 1)[-1][:-4])
            for i in glob.glob(path+"/*.xml")
            ]
    filelist.sort()
    if filelist:
        id = filelist[0]
        if os.path.getsize(path) > 500*1024*8:
            filename = id+1
        else:
            filename = id
    else:
        filename = 1

    if filename in filelist:
        append_xml(filename, li)
    else:
        generate_xml(filename, li)


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


def the_end():
    for site_name, li in SITE_POST.iteritems():
        mkpath(
            join(CONFIG.SITEMAP_PATH, site_name, "sitemap")
        )
        gen_sitemap(site_name, li)




def update():
    global LAST_ID, SITE_POST
    query = Query(SiteTagPost)
    query.ascending('ID')
    query.greater_than('ID', LAST_ID)
    query.limit(LIMIT)
    r = query.find()
    if r:
        for i in r:
            site_id = i.get('site').id
            post_id = i.get('post').id
            site_obj = site_query.get(site_id)
            post_obj = post_query.get(post_id)
            SITE_POST[site_obj.get('name')].append(post_obj.get('ID'))
        LAST_ID = r[-1].get('ID')

    if len(r) >= LIMIT:
        update()

    else:
        the_end()
        redis_client.set('R_SITEMAP_SINCE', LAST_ID)

@single_process
def main():
    return

if __name__ == '__main__':
    main()
