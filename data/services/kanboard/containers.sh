kanboard_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
	${IMAGES[service]} >/dev/null
}
