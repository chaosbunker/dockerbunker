nextcloud_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
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
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
		-v ${SERVICE_NAME}-data-vol-3:${volumes[${SERVICE_NAME}-data-vol-3]} \
	${IMAGES[service]} >/dev/null
}



