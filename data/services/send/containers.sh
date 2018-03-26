send_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:/send/data \
	${IMAGES[service]} >/dev/null
}
