# On first run, generate the basic environment file. This file will collect and hold all information regarding dockerbunker.
# It keeps track of which web-apps are configured, installed, which services' containers are stopped etc.
init_dockerbunker() {
	! [[ -d ${BASE_DIR}/data/conf/nginx/conf.d ]] && mkdir -p ${BASE_DIR}/data/conf/nginx/conf.d
	! [[ -d ${BASE_DIR}/data/env/static ]] && mkdir ${BASE_DIR}/data/env/static

	if [[ ! -f "${BASE_DIR}/data/env/dockerbunker.env" ]];then
		[[ ! -d "${BASE_DIR}/data/env/" ]] && mkdir -p "${BASE_DIR}/data/env/"
		cat <<-EOF >> "${BASE_DIR}/data/env/dockerbunker.env"
			BASE_DIR="${BASE_DIR}"
			SERVICES_DIR="${BASE_DIR}/data/services"
			SERVICE_DIR="\${SERVICES_DIR}/\${SERVICE_NAME}"
			CONF_DIR="${BASE_DIR}/data/conf"
			ENV_DIR="${BASE_DIR}/data/env"
			SERVICE_ENV="\${ENV_DIR}/\${SERVICE_NAME}.env"
			DOCKERFILES="${BASE_DIR}/data/Dockerfiles"
			CONTAINERS=\${SERVICE_DIR}/containers.sh

			LE_EMAIL=

			NETWORK=dockerbunker-network
			NGINX_CONTAINER=( "nginx-dockerbunker" )

			declare -A WEB_SERVICES=()
			declare -a CONFIGURED_SERVICES=()
			declare -a INSTALLED_SERVICES=()
			declare -a STATIC_SITES=()
		EOF
	fi
}

[[ -f "${BASE_DIR}"/data/env/dockerbunker.env ]] && source "${BASE_DIR}"/data/env/dockerbunker.env

for file in "${BASE_DIR}"/data/include/functions/*; do
  source $file
done

if [[ ${STATIC} && ${SERVICE_DOMAIN[0]} ]];then
	[[ -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env ]] \
	&& source "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
else
	if [[ ${SERVICE_NAME} ]];then
		[[ -f ${SERVICE_ENV} ]] \
			&& source ${SERVICE_ENV}
		[[ -f ${CONTAINERS} ]] \
			&& source ${CONTAINERS}
		[[ -f "${ENV_DIR}"/mx.env ]] \
			&& source "${ENV_DIR}"/mx.env
		[[ -f "${ENV_DIR}"/${SERVICE_NAME}_mx.env ]] \
			&& source "${ENV_DIR}"/${SERVICE_NAME}_mx.env
	fi
fi

