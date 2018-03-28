#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Open Project"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

declare -A WEB_SERVICES
declare -a containers=( "openproject-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-pgdata-vol-1]="/hastebin/data" [${SERVICE_NAME}-data-vol-1]="/var/db/openproject" [${SERVICE_NAME}-logs-vol-1]="/var/log/supervisor" )
declare -a add_to_network=( "openproject-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="openproject/community" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mOpen Project Settings\e[0m"

	set_domain

	configure_mx

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME="${SERVICE_NAME}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	SERVICE_SPECIFIC_MX=${SERVICE_SPECIFIC_MX}
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	
	# ------------------------------
	# Open Project Settings
	# ------------------------------
	
	SECRET_KEY_BASE=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
	
	# ------------------------------
	# E-Mail Server Settings
	# ------------------------------
	
	EMAIL_DELIVERY_METHOD=smtp
	SMTP_AUTHENTICATION=login
	SMTP_PORT=587
	SMTP_ENABLE_STARTTLS_AUTO=true
	SMTP_ADDRESS=${MX_DOMAIN}
	SMTP_USER_NAME=${MX_EMAIL}
	SMTP_PASSWORD=${MX_PASSWORD}
	SMTP_DOMAIN=${MX_DOMAIN}
	EOF

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi



