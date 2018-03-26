ghost_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--env-file ${SERVICE_ENV} \
		--env NODE_ENV=production \
		--env url=https://${SERVICE_DOMAIN[0]} \
		-v ${SERVICE_NAME}-data-vol-1:/var/lib/ghost/content \
		${IMAGES[service]} >/dev/null
}
