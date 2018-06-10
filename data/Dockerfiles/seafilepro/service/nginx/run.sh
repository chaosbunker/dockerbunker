#!/bin/sh

/usr/sbin/nginx -g 'daemon off;'  >> /var/log/nginx.log 2>&1
