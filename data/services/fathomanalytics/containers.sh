fathomanalytics_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		--env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
		--env MYSQL_DATABASE=${MYSQL_DATABASE} \
		--env MYSQL_USER=${MYSQL_USER} \
		--env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		-v "${SERVICES_DIR}"/${SERVICE_NAME}/mysql/:/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null

	wait_for_db
}

fathomanalytics_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file "${SERVICE_ENV}" \
		--env FATHOM_SERVER_ADDR=":8080" \
		--env FATHOM_DEBUG=false \
		--env FATHOM_DATABASE_DRIVER="mysql" \
		--env FATHOM_DATABASE_NAME="fathomanalytics" \
		--env FATHOM_DATABASE_USER="fathomanalytics" \
		--env FATHOM_DATABASE_PASSWORD="${MYSQL_PASSWORD}" \
		--env FATHOM_DATABASE_HOST="db:3306" \
		--env FATHOM_SECRET="${FATHOM_SECRET}" \
	${IMAGES[service]} >/dev/null
}
