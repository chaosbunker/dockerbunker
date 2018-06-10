#!/bin/sh

set -eu

/seafile/seafile-server-latest/seahub.sh start-fastcgi >> /var/log/service-seahub.log

while [ 1 ]; do
  sleep 10
done
