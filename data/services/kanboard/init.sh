#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Kanboard"
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
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/var/www/app/data" [${SERVICE_NAME}-data-vol-2]="/var/www/app/plugins" )
declare -a networks=( )
declare -A IMAGES=( [service]="kanboard/kanboard:v1.2.1" )

[[ -z $1 ]] && options_menu

configure() {

	pre_configure_routine

	echo -e "# \e[4mKanboard Settings\e[0m"
	set_domain
	
	cat <<-EOF >> "${SERVICE_ENV}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

# i think this can/should go now... if it goes, change tests in letsencrypt function (\$1, \$2 \$* etc)
if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi
