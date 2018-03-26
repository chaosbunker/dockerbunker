kanboard_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		-v ${SERVICE_NAME}-db-vol-1:/var/www/app/data \
		-v ${SERVICE_NAME}-data-vol-1:/var/www/app/plugins \
	${IMAGES[service]} >/dev/null
}
