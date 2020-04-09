padlockcloud_service_dockerbunker() {
	docker run -d \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--env-file "${SERVICE_ENV}" \
		--env-file "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env \
		--env BASE_URL=https://${SERVICE_DOMAIN} \
		--env EMAIL_SERVER=${MX_HOSTNAME} \
		--env EMAIL_USER=${MX_EMAIL} \
		--env EMAIL_PASSWORD=${MX_PASSWORD} \
		--env EMAIL_FROM="${MX_EMAIL}" \
		-v ${CONF_DIR}/padlockcloud/whitelist:/padlock/whitelist \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
	${IMAGES[service]} >/dev/null
}
