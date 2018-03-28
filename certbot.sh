#!/usr/bin/env bash

# Find base dir
while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

source "${BASE_DIR}"/data/include/init.sh

docker run \
	--rm -it --name=certbot \
	--network dockerbunker-network \
	-v "${CONF_DIR}"/nginx/ssl/letsencrypt:/etc/letsencrypt \
	-v "${BASE_DIR}"/data/web:/var/www/html:rw \
	certbot/certbot renew
