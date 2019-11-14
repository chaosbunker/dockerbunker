#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Firefly III"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -cd '[:alnum:]')"
PROMPT_SSL=1

declare -a environment=( "data/include/init.sh" "data/env/dockerbunker.env" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "fireflyiii-service-dockerbunker" "fireflyiii-db-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" [${SERVICE_NAME}-data-vol-1]="/var/www/firefly-iii/storage/export" [${SERVICE_NAME}-data-vol-2]="/var/www/firefly-iii/storage/upload" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -a add_to_network=( "fireflyiii-service-dockerbunker" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="jc5x/firefly-iii" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mFirefly III Settings\e[0m"

	set_domain
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}

	LOG_CHANNEL=daily
	APP_LOG_LEVEL=notice

	FF_DB_HOST=db
	FF_DB_NAME=firefly
	FF_DB_USER=firefly
	FF_DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	FF_APP_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	FF_APP_ENV=local
	FF_DB_CONNECTION=mysql
	FF_TZ=Europe/Berlin
	FF_APP_LOG_LEVEL=debug
	USE_PROXIES=127.0.0.1
	TRUSTED_PROXIES=**
	
	# ------------------------------
	# database configuration
	# ------------------------------

	MYSQL_DATABASE=firefly
	MYSQL_USER=firefly
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	echo -en "\n\e[1mStarting Firefly III database container\e[0m"
	docker_run fireflyiii_db_dockerbunker
	exit_response

	# wait for fireflyiii db to be available
	if ! docker exec fireflyiii-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;then
		echo -e "\n\e[3mWaiting for fireflyiii-db-dockerbunker to be ready...\e[0m"
		while ! docker exec fireflyiii-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;do
			sleep 3
		done
	fi

	echo -en "\n\e[1mStarting Firefly III service container\e[0m"
	docker_run fireflyiii_service_dockerbunker
	exit_response

	sleep 2

	post_setup_routine

	docker exec -it fireflyiii-service-dockerbunker bash -c "php artisan migrate --seed \
		&& php artisan firefly:upgrade-database \
		&& php artisan firefly:verify \
		&& php artisan cache:clear"

}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi