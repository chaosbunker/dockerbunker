
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "fireflyiii-service-dockerbunker" "fireflyiii-db-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" [${SERVICE_NAME}-data-vol-1]="/var/www/firefly-iii/storage/export" [${SERVICE_NAME}-data-vol-2]="/var/www/firefly-iii/storage/upload" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -a add_to_network=( "fireflyiii-service-dockerbunker" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="jc5x/firefly-iii:release-5.1.1" )

# service specific functions
# to setup save service specific docker-variables to environment file
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
	APP_DEBUG=true
	APP_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	APP_ENV=local
	APP_URL=${SERVICE_DOMAIN}

	DB_HOST=db
	DB_DATABASE=firefly
	DB_USERNAME=firefly
	DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	DB_CONNECTION=mysql
	TZ=Europe/Berlin
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
