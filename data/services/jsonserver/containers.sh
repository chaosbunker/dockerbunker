jsonserver_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${CONF_DIR}/jsonserver/db.json:/data/db.json \
		-v ${CONF_DIR}/jsonserver/auth.js:/data/auth.js \
	${IMAGES[service]} ${MIDDLEWARE} >/dev/null
}
