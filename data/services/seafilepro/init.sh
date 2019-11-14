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
declare -a containers=( "${SERVICE_NAME}-db-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-elasticsearch-dockerbunker" "${SERVICE_NAME}-memcached-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-3]="/opt/seafile" [${SERVICE_NAME}-data-vol-2]="/shared" [${SERVICE_NAME}-elasticsearch-vol-1]="/usr/share/elasticsearch/data" [${SERVICE_NAME}-data-vol-1]="/seafile" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="chaosbunker/seafile-pro" [memcached]="memcached:1.5.6" [elasticsearch]="seafileltd/elasticsearch-with-ik:5.6.16" )
previous_version="6.3.14"
current_version="7.0.7"

[[ -z $1 ]] && options_menu

upgrade() {
	echo ""
	prompt_confirm "Migrate from Seafile Pro 6.x.x to 7.x.x?"

	if [[ $? == 0 ]];then
		if [[ -z ${SEAFILE_ADMIN_EMAIL} ]] || [[ -z ${SEAFILE_ADMIN_PASSWORD} ]];then
			! grep -q SEAFILE_ADMIN_EMAIL ${SERVICE_ENV} \
				&& echo SEAFILE_ADMIN_EMAIL= >> ${SERVICE_ENV}
			! grep -q SEAFILE_ADMIN_PASSWORD ${SERVICE_ENV} \
				&& echo SEAFILE_ADMIN_PASSWORD= >> ${SERVICE_ENV}
			echo -e "\nPlease enter your Admin Email and Password in ${SERVICE_ENV} before upgrading"
			exit 0
		fi

		if [ -z "${TIME_ZONE}" ]; then
		  read -p "Time Zone: " TIME_ZONE
		  echo "TIME_ZONE=${TIME_ZONE}" >> ${SERVICE_ENV}
		fi
	
		stop_containers

		if [[ -f /var/lib/docker/volumes/seafilepro-data-vol-1/_data/ccnet/seafile.ini ]] && ! grep -q "/shared/seafile/seafile-data" /var/lib/docker/volumes/seafilepro-data-vol-1/_data/ccnet/seafile.ini;then
			echo -e "\n------------------------"
			echo -e "\nSet the new path for seafile-data dir by executing\n"
			echo -e "\techo \"/shared/seafile/seafile-data\" > /var/lib/docker/volumes/seafilepro-data-vol-1/_data/ccnet/seafile.ini"
			exit=1
		fi

		if [[ -f /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf ]] && ! grep -q "es_host = elasticsearch" /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf;then
			echo -e "\n------------------------"
			echo -e "\nopen /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf and add the following configuration in the [INDEX FILES] section:\n"
			echo -e "\texternal_es_server = true"
			echo -e "\tes_host = elasticsearch"
			echo -e "\tes_port = 9200"
			exit=1
		fi

		if [[ -f /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf ]] && ! grep -q "path = /opt/seafile/pro-data/seafevents.db" /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf;then
			echo -e "\n------------------------"
			echo -e "\nopen /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seafevents.conf and change the 'path' value in the [DATABASE] configuration to:\n"
			echo -e "\tpath = /opt/seafile/pro-data/seafevents.db\n"
			exit=1
		fi

		if [[ -f /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seahub_settings.py ]] && ! grep -q "'LOCATION': 'memcached:11211'" /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seahub_settings.py;then
			echo -e "\n------------------------"
			echo -e "\nopen /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf/seahub_settings.py and change the 'LOCATION' value to 'memcached:11211' in the CACHES dict:\n"
			echo -e "CACHES = {
    'default': {
        'BACKEND': 'django_pylibmc.memcached.PyLibMCCache',
        'LOCATION': 'memcached:11211',
    },
    'locmem': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    },
}
COMPRESS_CACHE_BACKEND = 'locmem'"
			exit=1
		fi

		[[ $exit ]] && echo -e "\n------------------------" && echo -e "\n\033[1;32mPlease take care of the above and re-run upgrade\033[0m" && exit 0

		create_volumes

		echo

		! [[ -d /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile ]] && \
			mkdir /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile

		! [[ -d /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile/seafile-data ]] && \
			echo "Moving seafile-data dir into seafilepro-data-vol-2:/shared/seafile/seafile-data" && \
			mv /var/lib/docker/volumes/seafilepro-data-vol-1/_data/seafile-data /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile

		! [[ -d /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile/seahub-data ]] && \
			echo "Moving seahub-data dir into seafilepro-data-vol-2:/shared/seafile/seahub-data" && \
			mv /var/lib/docker/volumes/seafilepro-data-vol-1/_data/seahub-data /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile

		! [[ -d /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile/conf ]] && \
			echo "Moving conf dir into seafilepro-data-vol-2:/shared/seafile/conf" && \
			mv /var/lib/docker/volumes/seafilepro-data-vol-1/_data/conf /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile

		! [[ -d /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile/ccnet ]] && \
			echo "Movingccnet dir into seafilepro-data-vol-2:/shared/seafile/ccnet" && \
			mv /var/lib/docker/volumes/seafilepro-data-vol-1/_data/ccnet /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile

		! [[ -d /var/lib/docker/volumes/seafilepro-elasticsearch-vol-1/_data/nodes ]] && \
			echo "Moving elasticsearch data into seafilepro-elasticsearch-vol-1:/usr/share/elasticsearch/data" && \
			mv /var/lib/docker/volumes/seafilepro-data-vol-1/_data/pro-data/search/data/elasticsearch/nodes /var/lib/docker/volumes/seafilepro-elasticsearch-vol-1/_data

		echo ${previous_version} > /var/lib/docker/volumes/seafilepro-data-vol-2/_data/seafile/seafile-data/current_version

		echo SEAFILE_SERVER_HOSTNAME=${SERVICE_DOMAIN} >> ${SERVICE_ENV}

		pull_and_compare

		remove_containers

		docker_run seafilepro_db_dockerbunker

		docker exec -it seafilepro-db-dockerbunker /usr/bin/mysql -u root -p${DBROOT} -e "grant all on *.* to 'root'@'%.%.%.%' identified by '${DBROOT}';"

		for database in {ccnet_db,seafile_db,seahub_db}; do sudo docker exec -it seafilepro-db-dockerbunker /usr/bin/mysql -u root -p${DBROOT} -e "grant all on ${database}.* to 'seafile'@'%.%.%.%' identified by '${DBPASS}';"; done

		docker exec -it seafilepro-db-dockerbunker mysql_upgrade -u root -p${DBROOT}

		docker_run_all

		docker exec -it seafilepro-service-dockerbunker /scripts/upgrade.py

		remove_from_STOPPED_SERVICES

		delete_old_images

		activate_nginx_conf

		restart_nginx
	else
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
	fi
}

configure() {
	pre_configure_routine

	echo -e "# \e[4mSeafile Pro Settings\e[0m"
	set_domain

	if [ "${SEAFILE_ADMIN_EMAIL}" ]; then
	  read -p "Admin E-Mail: " -ei "${SEAFILE_ADMIN_EMAIL}" SEAFILE_ADMIN_EMAIL
	else
	  read -p "Admin E-Mail: " SEAFILE_ADMIN_EMAIL
	fi
	
	unset SEAFILE_ADMIN_PASSWORD
	while [[ "${#SEAFILE_ADMIN_PASSWORD}" -le 6 || "${SEAFILE_ADMIN_PASSWORD}" != *[A-Z]* || "${SEAFILE_ADMIN_PASSWORD}" != *[a-z]* || "${SEAFILE_ADMIN_PASSWORD}" != *[0-9]* ]];do
		if [ ${VALIDATE} ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig="$(stty -g)"
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" SEAFILE_ADMIN_PASSWORD
			stty "${stty_orig}"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""

	if [ "${TIME_ZONE}" ]; then
	  read -p "Time Zone: " -ei "${TIME_ZONE}" TIME_ZONE
	else
	  read -p "Time Zone: " TIME_ZONE
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
	TIME_ZONE=${TIME_ZONE}

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	# Please use long, random alphanumeric strings (A-Za-z0-9)
	DBROOT=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
	DBPASS=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)
	
	DB_HOST=db
	
	DBUSER=seafile
	
	SEAFILE_ADMIN_EMAIL=${SEAFILE_ADMIN_EMAIL}
	SEAFILE_ADMIN_PASSWORD=${SEAFILE_ADMIN_PASSWORD}
	
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
