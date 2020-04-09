wordpress_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		-v "${BASE_DIR}/data/services/${SERVICE_NAME}/mysql/":/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null
}

wordpress_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file="${SERVICE_ENV}" \
		--env WORDPRESS_DB_NAME=wpdb \
		--env WORDPRESS_TABLE_PREFIX=wp_ \
		--env WORDPRESS_DB_HOST=db:3306 \
		--env WORDPRESS_DB_USER=${MYSQL_USER} \
		--env WORDPRESS_DB_PASSWORD=${MYSQL_PASSWORD} \
		-v "${BASE_DIR}/data/services/${SERVICE_NAME}/php/uploads.ini":/usr/local/etc/php/conf.d/uploads.ini \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} >/dev/null
}


