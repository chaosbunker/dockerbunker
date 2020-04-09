seafilepro_db_dockerbunker() {
	docker run  -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--net-alias=db \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		--env MYSQL_ROOT_PASSWORD=${DBROOT} \
		--env MYSQL_USER=${DBUSER} \
		--env MYSQL_PASSWORD=${DBPASS} \
	${IMAGES[db]} >/dev/null

	if [[ -z $keep_volumes ]];then
		if ! docker exec seafilepro-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;then
			echo -en "\n\e[3m\xe2\x86\x92 Waiting for Seafile DB to be ready...\n\n"
			while ! docker exec seafilepro-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;do
				sleep 3
			done
		fi
	fi
}

seafilepro_setup_dockerbunker() {
	docker run -it --rm \
		--name=${FUNCNAME[0]//_/-} \
		--network=dockerbunker-${SERVICE_NAME} \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} $1
}

seafilepro_memcached_dockerbunker() {
	docker run --entrypoint memcached -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--net-alias=memcached \
		--network dockerbunker-seafilepro \
	${IMAGES[memcached]} -m 256 >/dev/null
}

seafilepro_elasticsearch_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--net-alias=elasticsearch \
		--network dockerbunker-seafilepro \
		-e discovery.type=single-node \
		-e bootstrap.memory_lock=true \
		-e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
		--ulimit memlock=-1:-1 \
		-m 2g \
		-v ${SERVICE_NAME}-elasticsearch-vol-1:${volumes[${SERVICE_NAME}-elasticsearch-vol-1]} \
	${IMAGES[elasticsearch]} >/dev/null
}

seafilepro_service_dockerbunker() {
	docker run -e TZ=Europe/Amsterdam -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--network dockerbunker-seafilepro \
		--env-file "${SERVICE_ENV}" \
		-e DB_ROOT_PASSWD=${DBROOT} \
		-e SEAFILE_SERVER_HOSTNAME=${SERVICE_DOMAIN} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
	${IMAGES[service]} >/dev/null
}
