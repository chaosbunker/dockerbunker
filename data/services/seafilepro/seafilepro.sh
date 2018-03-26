#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Seafile Pro"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=true
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-db-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a volumes=( "${SERVICE_NAME}-db-vol-1" "${SERVICE_NAME}-data-vol-1" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [db]="mariadb:10.2" [service]="dockerbunker/${SERVICE_NAME}" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}]="${DOCKERFILES}/${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

upgrade() {
	read -p "Please enter the Seafile Version number to upgrade to: " SF_VERSION

	pull_and_compare

	stop_containers
	remove_containers

	echo -en "\n\e[1mStarting up ${PROPER_NAME} upgrade container\e[0m" \
		&& seafilepro_setup_dockerbunker "upgrade $SF_VERSION" \
		&& exit_response

	docker_run_all
}

configure() {
	pre_configure_routine

	echo -e "# \e[4mSeafile Pro Settings\e[0m"
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
	
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}

	# ------------------------------
	# SQL database configuration
	# ------------------------------
	
	DBUSER=seafile
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	DBROOT=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
	DBPASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
	EOF
	
	if [[ $OSTYPE =~ "darwin" ]];then
		unset LC_ALL
	fi

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	[[ $keep_volumes ]] \
		&& echo -en "\n\e[1mStarting up ${PROPER_NAME} database container\e[0m" \
		&& seafilepro_db_dockerbunker \
		&& exit_response
	
	if [[ -z $keep_volumes ]];then
		echo "Starting interactive Seafile Pro setup"
		echo ""
		echo "MySQL Server:          db"
		echo "Port:                  3306"
		echo "MySQL User:            seafile"
		prompt_confirm "Display MySQL root and user passwords"
		[[ $? == 0 ]] && echo -e "MySQL root password:   ${DBROOT}\nMySQL user password:   ${DBPASS}" || echo -e "\e[33mPlease obtain the MySQL root password from ${SERVICE_ENV}\e[0m\n"
		echo ""
	
		echo -e "\n\e[1mStarting up ${PROPER_NAME} setup container\e[0m" \
			&& seafilepro_setup_dockerbunker setup \
			&& exit_response
	fi

	docker_run_all

	post_setup_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi
