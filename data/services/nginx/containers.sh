nginx_dockerbunker() {
	echo -en "\n\e[1mStarting up nginx container\e[0m"
	docker run -d \
		--name=${NGINX_CONTAINER} \
		--restart=always \
		--net=${NETWORK} --net-alias=nginx \
		-p 80:80 -p 443:443 \
		-v "${BASE_DIR}/data/web":/var/www/html:ro \
		-v "${SERVICES_DIR}/nginx/nginx.conf":/etc/nginx/nginx.conf:ro \
		-v "${CONF_DIR}/nginx/ssl":/etc/nginx/ssl \
		-v "${CONF_DIR}/nginx/conf.d":/etc/nginx/conf.d \
		-v "${SERVICES_DIR}/nginx/ssl/dhparam.pem":/etc/nginx/ssl/dhparam.pem:ro \
		-v "${SERVICES_DIR}/nginx/includes":/etc/nginx/includes \
	${IMAGES[service]} >/dev/null
	exit_response
}

