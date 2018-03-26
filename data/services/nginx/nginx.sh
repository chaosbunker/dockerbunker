while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Nginx"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -a containers=( "${SERVICE_NAME}-dockerbunker" )
declare -a networks=( "dockerbunker-network" )
declare -A IMAGES=( [service]="nginx:mainline-alpine" )

setup() {
	source "${ENV_DIR}"/dockerbunker.env

	echo -e "\n\e[1mNo nginx container found\e[0m"
	echo -e "\n\e[3m\xe2\x86\x92 Setup nginx\e[0m"
	docker_pull

	[[ ! $(docker network ls -q --filter name=^${NETWORK}$) ]] \
		&& docker network create $NETWORK >/dev/null \

	[[ ! -d "${BASE_DIR}"/data/web ]] && mkdir "${BASE_DIR}"/data/web

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


