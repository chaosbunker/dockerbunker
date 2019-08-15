commento_postgres_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network=dockerbunker-${SERVICE_NAME} --net-alias=db \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		--env-file=${SERVICE_ENV} \
		-e POSTGRES_PASSWORD=${DBPASS} \
		-e POSTGRES_USER=${DBUSER} \
	${IMAGES[postgres]} >/dev/null
}

commento_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network=dockerbunker-${SERVICE_NAME} \
		-v ${CONF_DIR}/commento/commento.env:/etc/commento.env:ro \
		-e COMMENTO_SMTP_HOST=${MX_HOSTNAME} \
		-e COMMENTO_SMTP_PORT=587 \
		-e COMMENTO_SMTP_USERNAME=${MX_EMAIL} \
		-e COMMENTO_SMTP_PASSWORD=${MX_PASSWORD} \
		-e COMMENTO_SMTP_FROM_ADDRESS=${MX_EMAIL} \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env-file=${SERVICE_ENV} \
		-e COMMENTO_POSTGRES=postgres://${DBUSER}:${DBPASS}@db:5432/commento?sslmode=disable \
	${IMAGES[service]} >/dev/null
}
