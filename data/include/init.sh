# On first run, generate the basic environment file. This file will collect and hold all information regarding dockerbunker.
# It keeps track of which web-apps are configured, installed, which services' containers are stopped etc.
init_dockerbunker() {
	if [[ ! -f "${BASE_DIR}/build/env/dockerbunker.env" ]];then
		! [[ -d "${BASE_DIR}/build/env/" ]] && mkdir -p "${BASE_DIR}/build/env/"
		! [[ -d "${BASE_DIR}"/build/env/static ]] && mkdir -p "${BASE_DIR}"/build/env/static
		! [[ -d "${BASE_DIR}"/build/conf/nginx/conf.d ]] && mkdir -p "${BASE_DIR}"/build/conf/nginx/conf.d
		cat <<-EOF >> "${BASE_DIR}/build/env/dockerbunker.env"
			BASE_DIR="${BASE_DIR}"
			SERVICES_DIR="${BASE_DIR}/data/services"
			SERVER_DIR="${BASE_DIR}/data/server"
			CONF_DIR="${BASE_DIR}/build/conf"
			ENV_DIR="${BASE_DIR}/build/env"
			BACKUP_DIR="${BASE_DIR}/build/backup"
			WEB_DIR="${BASE_DIR}/build/web"

			SERVICE_DIR="\${SERVICES_DIR}/\${SERVICE_NAME}"
			SERVICE_ENV="\${ENV_DIR}/\${SERVICE_NAME}.env"
      CONTAINERS=\${SERVICE_DIR}/containers.sh
			SERVER_CONTAINER=\${SERVER_DIR}/nginx/containers.sh

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

# load dockerbunker environment variables or initialize it via init_dockerbunker functionality
[[ -f "${BASE_DIR}"/build/env/dockerbunker.env ]] \
&& source "${BASE_DIR}"/build/env/dockerbunker.env  || init_dockerbunker

# load dockerbunker functions
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
    [[ -f ${SERVER_CONTAINER} ]] \
			&& source ${SERVER_CONTAINER}
		[[ -f "${ENV_DIR}"/mx.env ]] \
			&& source "${ENV_DIR}"/mx.env
		[[ -f "${ENV_DIR}"/${SERVICE_NAME}_mx.env ]] \
			&& source "${ENV_DIR}"/${SERVICE_NAME}_mx.env
	fi
fi

# load service-names dynamically
# via loop through folder-names at depth 1 within ./data/services, e.g. data/services/service-name
while IFS= read -r servicename; do
	declare -a ALL_SERVICES+=( $(basename "$servicename") )
done < <(find "${BASE_DIR}/data/services/" -mindepth 1 -maxdepth 1 -type d)

# sort services
IFS=$'\n' sorted=($(printf '%s\n' "${ALL_SERVICES[@]}"|sort));

# unset variables to work with it clean later
unset AVAILABLE_SERVICES count
