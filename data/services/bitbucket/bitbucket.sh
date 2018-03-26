#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Bitbucket"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "bitbucket-postgres-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "bitbucket-service-dockerbunker"  )
declare -a networks=( )
declare -A IMAGES=( [service]="dockerbunker/${SERVICE_NAME}" )
declare -a volumes=( "${SERVICE_NAME}-data-vol-1" "${SERVICE_NAME}-db-vol-1" )
declare -a networks=( "dockerbunker-bitbucket" )
declare -A IMAGES=( [postgres]="postgres" [service]="atlassian/bitbucket-server:5" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mBitbucket Settings\e[0m"

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
	cat <<-EOF >> "${SERVICE_ENV}"
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVER_SECURE=true
	SERVER_SCHEME=https
	SERVER_PROXY_PORT=443
	SERVER_PROXY_NAME=${SERVICE_DOMAIN}
	SERVICE_DOMAIN=${SERVICE_DOMAIN}

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	DBUSER=bitbucket
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	DBPASS=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	EOF

	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi

