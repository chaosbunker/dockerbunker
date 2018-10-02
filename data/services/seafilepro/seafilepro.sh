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
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/seafile" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="chaosbunker/seafile-pro-docker" )
current_version="6.3.4"

[[ -z $1 ]] && options_menu

upgrade() {
	pull_and_compare

	stop_containers
	remove_containers

	docker_run seafilepro_db_dockerbunker

	seafilepro_setup_dockerbunker "upgrade ${current_version}"

	docker_run_all

	[[ -z ${FILE_COMMENT_MIGRATED} ]] \
		&& echo -e "\n\e[1mMigrate database table for file comments\e[0m" \
		&& docker exec -it seafilepro-service-dockerbunker ./seahub.sh python-env seahub/manage.py migrate_file_comment \
		&& exit_response \
		&& echo "FILE_COMMENT_MIGRATED=1" >> "${ENV_DIR}"/${SERVICE_NAME}.env

	echo -e "\n\e[1mRunning mysql_upgrade on all databases\e[0m"
	docker exec -it seafilepro-db-dockerbunker mysql_upgrade -u root -p${DBROOT}
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
			&& docker_run seafilepro_db_dockerbunker \
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
