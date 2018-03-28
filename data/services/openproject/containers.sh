openproject_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-pgdata-vol-1:${volumes[${SERVICE_NAME}-pgdata-vol-1]} \
		-v ${SERVICE_NAME}-logs-vol-1:${volumes[${SERVICE_NAME}-logs-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} >/dev/null
}
