gitea_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		--env-file="${SERVICE_ENV}" \
		--env MYSQL_ROOT_PASSWORD=${GITEA_DBROOT} \
		--env MYSQL_DATABASE=${GITEA_DBNAME} \
		--env MYSQL_USER=${GITEA_DBUSER} \
		--env MYSQL_PASSWORD=${GITEA_DBPASS} \
		-v gitea-db-vol-1:/var/lib/mysql \
		-v "${SERVICES_DIR}"/${SERVICE_NAME}/mysql/:/etc/mysql/conf.d/:ro \
		--health-cmd="mysqladmin ping --host localhost --silent" --health-interval=10s --health-retries=5 --health-timeout=30s \
	${IMAGES[db]} >/dev/null
}

gitea_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file "${SERVICE_ENV}" \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env RUN_CROND=true \
		-v gitea-data-vol-1:/data \
	${IMAGES[service]} >/dev/null
}
