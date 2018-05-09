wekan_db_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=db \
		-p=27017 \
		--env-file="${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-1]} \
		-v ${SERVICE_NAME}-db-vol-1:${volumes[${SERVICE_NAME}-db-vol-2]} \
	${IMAGES[db]} mongod --smallfiles --oplogSize 128 >/dev/null
}

wekan_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file="${SERVICE_ENV}" \
	${IMAGES[service]} >/dev/null
}



