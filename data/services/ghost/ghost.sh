#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Ghost"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/var/lib/ghost/content" )
declare -a networks=( )
declare -A IMAGES=( [service]="ghost:1-alpine" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mGhost Settings\e[0m"

	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME=${PROPER_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	
	# ------------------------------
	# Ghost Settings
	# ------------------------------
	
	url=https://${SERVICE_DOMAIN}
	NODE_ENV=production
	EOF

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi


