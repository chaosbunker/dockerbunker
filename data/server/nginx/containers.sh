nginx_dockerbunker() {
	echo -en "\n\e[1mStarting up nginx container\e[0m"
	docker run -d \
		--name=${NGINX_CONTAINER} \
		--restart=always \
		--net=${NETWORK} --net-alias=nginx \
		-p 80:80 -p 443:443 \
		-v "${BASE_DIR}/build/web":/var/www/html:ro \
		-v "${SERVER_DIR}/nginx/nginx.conf":/etc/nginx/nginx.conf:ro \
		-v "${SERVER_DIR}/nginx/includes":/etc/nginx/includes \
		-v "${CONF_DIR}/nginx/ssl":/etc/nginx/ssl \
		-v "${CONF_DIR}/nginx/conf.d":/etc/nginx/conf.d \
	${IMAGES[service]} >/dev/null
	exit_response
}
