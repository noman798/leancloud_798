#!/usr/bin/env python
# -*- coding:utf-8 -*-

import json
import xmlrpclib
from db import redis
from single_process import single_process


def ping(ping_url, *args, **kwds):
    """args: site_name, site_host, post_url, rss_url."""
    rpc_server = xmlrpclib.ServerProxy(ping_url)
    result = rpc_server.weblogUpdates.extendedPing(*args)
    print result


def ping_all(*args, **kwds):
    ping_url_list = [
        'http://ping.baidu.com/ping/RPC2',
        'http://rpc.pingomatic.com/',
        'http://blogsearch.google.com/ping/RPC2',
    ]
    for url in ping_url_list:
        ping(url, *args, **kwds)


@single_process
def main():
    client = redis.pubsub()
    client.subscribe(['ping'])
    while True:
        for item in client.listen():
            if item['type'] == 'message':
                msg = item['data']
                if msg:
                    post = json.loads(msg)
                    print post
                    ping_all(post.get('site_name'), post.get('site_host'),
                             post.get('post_url'), post.get('rss_url'))


def test():
    site_name = "tech2ipo"
    site_host = "http://alpha.tech2ipo.com"
    post_url = 'http://alpha.tech2ipo.com/100855'
    rss_url = "http://alpha.tech2ipo.com/rss/alpha.tech2ipo.com"
    ping_all(site_name, site_host, post_url, rss_url)


if __name__ == '__main__':
    #test()
    main()
