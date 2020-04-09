sftpserver_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file "${SERVICE_ENV}" \
		-p 2222:22 \
		-v "${CONF_DIR}"/sftpserver/users.conf:/etc/sftp/users.conf:ro \
		-v "${CONF_DIR}"/sftpserver/ssh/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
		-v "${CONF_DIR}"/sftpserver/ssh/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
		-v "${SERVICES_DIR}"/sftpserver/run.sh:/etc/sftp.d/fix-permissions:ro \
		-v "${BASE_DIR}"/data/web/sftpserver:/home \
	${IMAGES[service]} >/dev/null
}

