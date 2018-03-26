mailpile_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		-v mailpile-data-vol-1:/mailpile-data \
		-p ${PORT}:${PORT} \
	${IMAGES[service]} ${COMMAND} >/dev/null
}
