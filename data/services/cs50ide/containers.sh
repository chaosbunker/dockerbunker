cs50ide_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file ${SERVICE_ENV}\
		--cap-add=SYS_PTRACE \
		-p 5050:5050 \
		-e "OFFLINE_PORT=5050" \
		-e "OFFLINE_IP=127.0.0.1" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} >/dev/null
}
