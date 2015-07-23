#!/usr/bin/env python
#coding=utf-8
from db import Q,DB,redis
import glob
import re
import leancloud
from lxml import etree
from collections import defaultdict
from distutils.dir_util import mkpath
from os.path import join, abspath, realpath, exists
from single_process import single_process

R_SITEMAP_SINCE = "SitemapSince"




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


def the_end(site_post):
    for site_id, li in site_post.iteritems():
        print site_id
        for i in li:
            print i

        continue
        mkpath(
            join(CONFIG.SITEMAP_PATH, site_name, "sitemap")
        )
        gen_sitemap(site_name, li)



def update(last_id,site_post,limit=500):
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

        post_list = Q.Post.contained_in("objectId",list(post_id_set)).select('ID').find()
        post_dict = dict((i.id,i.get('ID')) for i in post_list)

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


