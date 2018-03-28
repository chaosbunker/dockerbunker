gogs_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		--env MYSQL_ROOT_PASSWORD=${GOGS_DBROOT} \
		--env MYSQL_DATABASE=${GOGS_DBNAME} \
		--env MYSQL_USER=${GOGS_DBUSER} \
		--env MYSQL_PASSWORD=${GOGS_DBPASS} \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		-v "${SERVICES_DIR}"/${SERVICE_NAME}/mysql/:/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null
}

gogs_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file "${SERVICE_ENV}" \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env RUN_CROND=true \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} >/dev/null
}
