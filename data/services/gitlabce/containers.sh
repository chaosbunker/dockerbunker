gitlabce_service_dockerbunker() {
	echo -en "Starting up '${PROPER_NAME}' container"
	docker run -d \
		--hostname ${SERVICE_DOMAIN} \
		--sysctl net.core.somaxconn=1024 \
		--ulimit sigpending=62793 \
		--ulimit nproc=131072 \
		--ulimit nofile=60000 \
		--ulimit core=0 \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file ${SERVICE_ENV} \
		-v ${SERVICE_NAME}-conf-vol-1:/etc/gitlab \
		-v ${SERVICE_NAME}-data-vol-1:/etc/opt/gitlab \
		-v ${SERVICE_NAME}-log-vol-1:/var/log/gitlab \
	${IMAGES[service]} >/dev/null
	exit_response
}
