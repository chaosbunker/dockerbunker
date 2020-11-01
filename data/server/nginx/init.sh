while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

SERVICE_NAME="$(basename $(dirname "$BASH_SOURCE") | tr -cd '[a-z|0-9|\-|\_]')" # tr delets all the other characters | tr -cd '[a-z|0-9|\-|\_]')" # tr delets all the other characters)"

declare -a environment=( "build/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -a containers=( "${SERVICE_NAME}-dockerbunker" )
declare -a networks=( "dockerbunker-network" )
declare -A IMAGES=( [service]="nginx:mainline-alpine" )

setup() {

	source "${ENV_DIR}"/dockerbunker.env

	echo -e "\n\e[3m\xe2\x86\x92 Setup nginx\e[0m"

	docker_pull

	[[ ! $(docker network ls -q --filter name=^${NETWORK}$) ]] \
		&& docker network create $NETWORK >/dev/null

	[[ ! -d "${CONF_DIR}"/nginx/ssl ]] \
		&& mkdir -p "${CONF_DIR}"/nginx/ssl

	[[ ! -f "${CONF_DIR}"/nginx/ssl/dhparam.pem ]] \
		&& cp "${SERVER_DIR}/nginx/ssl/dhparam.pem" "${CONF_DIR}"/nginx/ssl

	[[ ! -d "${BASE_DIR}"/build/web ]] \
		&& mkdir "${BASE_DIR}"/build/web

	docker_run nginx_dockerbunker
}

destroy_service() {
	stop_containers
	remove_containers
	remove_networks

	[[ -f "${ENV_DIR}"/mx.env ]] \
		&& rm "${ENV_DIR}"/mx.env

	[[ -f "${ENV_DIR}"/dockerbunker.env ]] \
		&& rm "${ENV_DIR}"/dockerbunker.env
}

$1
