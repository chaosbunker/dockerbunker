nextcloud_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		-v nextcloud-db-vol-1:/var/lib/mysql \
		-v "${SERVICES_DIR}"/${SERVICE_NAME}/mysql/:/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null

	wait_for_db
}

nextcloud_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file="${SERVICE_ENV}" \
		-v nextcloud-data-vol-1:/var/www/html \
		-v nextcloud-data-vol-2:/var/www/html/custom_apps \
		-v nextcloud-data-vol-3:/var/www/html/config \
		-v nextcloud-data-vol-4:/var/www/html/data \
	${IMAGES[service]} >/dev/null
}



