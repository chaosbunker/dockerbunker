fireflyiii_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
		-e MYSQL_PASSWORD=${FF_DB_PASSWORD} \
	${IMAGES[db]} >/dev/null
}

fireflyiii_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
		--env-file=${SERVICE_ENV} \
	${IMAGES[service]} >/dev/null
}
