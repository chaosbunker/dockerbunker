
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-db-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/var/www/html/config" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [service]="matomo" [db]="mariadb:10.2" )


# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mMatomo Settings\e[0m"
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
	# Matomo SQL database configuration
	# ------------------------------

	MYSQL_DATABASE=matomo
	MYSQL_USER=matomo

	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	EOF

	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}
