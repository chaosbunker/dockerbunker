#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Commento"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "commento-postgres-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "commento-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/postgresql/data" )
declare -a networks=( "dockerbunker-commento" )
declare -A IMAGES=( [postgres]="postgres" [service]="registry.gitlab.com/commento/commento" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mCommento Settings\e[0m"

	set_domain

	configure_mx

	prompt_confirm "Set up Github OAuth"
	if [[ $? == 0 ]];then
		read -p "Client ID: " -ei "" COMMENTO_GITHUB_KEY
		read -p "Client Secret: " -ei "" COMMENTO_GITHUB_SECRET
	fi

	prompt_confirm "Set up Gitlab OAuth"
	if [[ $? == 0 ]];then
		read -p "Client ID: " -ei "" COMMENTO_GITLAB_KEY
		read -p "Client Secret: " -ei "" COMMENTO_GITLAB_SECRET
	fi

	prompt_confirm "Set up Google OAuth"
	if [[ $? == 0 ]];then
		read -p "Client ID: " -ei "" COMMENTO_GOOGLE_KEY
		read -p "Client Secret: " -ei "" COMMENTO_GOOGLE_SECRET
	fi

	prompt_confirm "Set up Twitter OAuth"
	if [[ $? == 0 ]];then
		read -p "Client ID: " -ei "" COMMENTO_TWITTER_KEY
		read -p "Client Secret: " -ei "" COMMENTO_TWITTER_SECRET
	fi

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
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	
	SERVICE_SPECIFIC_MX=${SERVICE_SPECIFIC_MX}
	COMMENTO_FORBID_NEW_OWNERS=false

	COMMENTO_ORIGIN=https://${SERVICE_DOMAIN}

	COMMENTO_GITHUB_KEY=${COMMENTO_GITHUB_KEY}
	COMMENTO_GITHUB_SECRET=${COMMENTO_GITHUB_SECRET}

	COMMENTO_GITLAB_KEY=${COMMENTO_GITLAB_KEY}
	COMMENTO_GITLAB_SECRET=${COMMENTO_GITLAB_SECRET}

	COMMENTO_GOOGLE_KEY=${COMMENTO_GOOGLE_KEY}
	COMMENTO_GOOGLE_SECRET=${COMMENTO_GOOGLE_SECRET}

	COMMENTO_TWITTER_KEY=${COMMENTO_TWITTER_KEY}
	COMMENTO_TWITTER_SECRET=${COMMENTO_TWITTER_SECRET}

	COMMENTO_CONFIG_FILE=/etc/commento.env

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	DBUSER=commento
	
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

