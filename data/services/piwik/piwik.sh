#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Piwik"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-db-dockerbunker" )
declare -a volumes=( "${SERVICE_NAME}-data-vol-1" "${SERVICE_NAME}-data-vol-2" "${SERVICE_NAME}-db-vol-1" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [service]="piwik" [db]="mariadb:10.2" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mPiwik Settings\e[0m"
	set_domain
	
	# avoid tr illegal byte sequence in macOS when generating random strings
	if [[ $OSTYPE =~ "darwin" ]];then
		if [[ $LC_ALL ]];then
			oldLC_ALL=$LC_ALL
			export LC_ALL=C
		else
			export LC_ALL=C
		fi
	fi
	cat <<-EOF >> ${SERVICE_ENV}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	
	# ------------------------------
	# Piwik SQL database configuration
	# ------------------------------
	
	MYSQL_DATABASE=piwik
	MYSQL_USER=piwik
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	EOF
	
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}

# i think this can/should go now... if it goes, change tests in letsencrypt function (\$1, \$2 \$* etc)
if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi

