droneci_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file "${SERVICE_ENV}" \
		--detach=true \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} ${ID} >/dev/null
}
