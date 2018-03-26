openproject_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env-file "${SERVICE_ENV}" \
		-v openproject-pgdata-vol-1:/var/lib/postgresql/9.4/main \
		-v openproject-logs-vol-1:/var/log/supervisor \
		-v openproject-data-vol-1:/var/db/openproject \
	${IMAGES[service]} >/dev/null
}
