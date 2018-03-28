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
			echo -en "Waiting for Seafile DB to be ready..."
			while ! docker exec seafilepro-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;do
				sleep 3
			done
			if [ $? != 1 ];then
				echo -e " \e[32m\xE2\x9C\x94\e[0m"
			else
				echo  -e " \e[31mfailed\e[0m"
			fi
		fi
	fi
}

seafilepro_setup_dockerbunker() {
	docker run -it --rm \
		--name=${FUNCNAME[0]//_/-} \
		--network=dockerbunker-${SERVICE_NAME} \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v "${BASE_DIR}"/data/services/seafilepro/seafile-license.txt \
	${IMAGES[service]} $1
}

seafilepro_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--network dockerbunker-seafilepro \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v "${BASE_DIR}"/data/services/seafilepro/seafile-license.txt \
	${IMAGES[service]} >/dev/null
}
