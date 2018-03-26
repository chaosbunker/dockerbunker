piwik_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}"\
		-v ${SERVICE_NAME}-db-vol-1:/var/lib/mysql \
		-v "${SERVICES_DIR}"/${SERVICE_NAME}/mysql/:/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null

	wait_for_db ${FUNCNAME[0]//_/-}
}

piwik_service_dockerbunker() {
	docker run -d \
		--name=${SERVICE_NAME}-service-dockerbunker \
		--restart=always \
		--network dockerbunker-piwik \
		-v ${SERVICE_NAME}-data-vol-1:/var/www/app/data \
		-v ${SERVICE_NAME}-data-vol-2:/var/www/app/plugins \
	${IMAGES[service]} >/dev/null
}
