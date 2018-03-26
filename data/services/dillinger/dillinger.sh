#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Dillinger"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a volumes=( "${SERVICE_NAME}-data-vol-1")
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="dockerbunker/dillinger" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}]="${DOCKERFILES}/${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	! [[ -d "${BASE_DIR}"/data/Dockerfiles/dillinger ]] \
	&& echo -n "Cloning Dillinger repository into data/Dockerfiles/dillinger" \
	&& git submodule add -f https://github.com/joemccann/dillinger.git data/Dockerfiles/dillinger >/dev/null \
	&& exit_response
	
	echo -e "# \e[4mDillinger Settings\e[0m"

	set_domain
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME=${PROPER_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi