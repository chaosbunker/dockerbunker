#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Mailpile"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/root/.local/share/Mailpile" [${SERVICE_NAME}-data-vol-2]="/root/.gnupg" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="chaosbunker/mailpile-docker" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mMailpile Settings\e[0m"
	
	set_domain
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	PROMPT_SSL=${PROMPT_SSL}
	COMMAND="${COMMAND}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL="${LE_EMAIL}"
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi