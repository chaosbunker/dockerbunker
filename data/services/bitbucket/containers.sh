bitbucket_postgres_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network=dockerbunker-${SERVICE_NAME} --net-alias=db \
		-v ${SERVICE_NAME}-db-vol-1:/var/lib/postgresql/data \
		--env-file=${SERVICE_ENV} \
		-e POSTGRES_PASSWORD=${DBPASS} \
		-e POSTGRES_USER=${DBUSER} \
	${IMAGES[postgres]}
}

bitbucket_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network=${NETWORK} \
		--network=dockerbunker-${SERVICE_NAME} \
		-v ${SERVICE_NAME}-data-vol-1:/var/atlassian/application-data/bitbucket \
		--env-file=${SERVICE_ENV} \
	${IMAGES[service]}
}
