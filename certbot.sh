#!/bin/bash

# example cron job to renew all certs due for renewal every sunday at 10:09pm

# 9 22 * * 0 /bin/bash -c "cd /path/to/dockerbunker && ./certbot.sh"

/bin/date | /usr/bin/tee -a /var/log/certbot.log

# Find base dir
while true;do /bin/ls | /bin/grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

. "${BASE_DIR}"/data/include/init.sh

/usr/bin/docker run \
	--rm --name=certbot \
	--network dockerbunker-network \
	-v "${CONF_DIR}"/nginx/ssl/letsencrypt:/etc/letsencrypt \
	-v "${BASE_DIR}"/build/web:/var/www/html:rw \
	certbot/certbot renew | /usr/bin/tee -a /var/log/certbot.log

if /usr/bin/docker exec -t nginx-dockerbunker nginx -t | grep -q 'test is successful';then
	/usr/bin/docker restart nginx-dockerbunker >/dev/null
	[[ $? == 0 ]] \
		&& echo "Successfully restarted nginx-dockerbunker" | /usr/bin/tee -a /var/log/certbot.log \
		|| echo "Restart of nginx-dockerbunker failed" | /usr/bin/tee -a /var/log/certbot.log
fi

