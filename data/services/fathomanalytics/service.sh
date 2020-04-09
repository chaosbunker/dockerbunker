
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-db-dockerbunker")
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -A IMAGES=( [db]="mariadb:10.2" [service]="usefathom/fathom" )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mFathom Analytics Settings\e[0m"

	set_domain

	if [ "${FATHOM_ADMIN_EMAIL}" ]; then
	  read -p "Admin E-Mail: " -ei "${FATHOM_ADMIN_EMAIL}" FATHOM_ADMIN_EMAIL
	else
	  read -p "Admin E-Mail: " FATHOM_ADMIN_EMAIL
	fi

	unset FATHOM_ADMIN_PASSWORD
	while [[ "${#FATHOM_ADMIN_PASSWORD}" -le 6 || "${FATHOM_ADMIN_PASSWORD}" != *[A-Z]* || "${FATHOM_ADMIN_PASSWORD}" != *[a-z]* || "${FATHOM_ADMIN_PASSWORD}" != *[0-9]* ]];do
		if [ ${VALIDATE} ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig="$(stty -g)"
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" FATHOM_ADMIN_PASSWORD
			stty "${stty_orig}"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""

	echo ""

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
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	# ------------------------------
	# General Settings
	# ------------------------------

	FATHOM_ADMIN_EMAIL=${FATHOM_ADMIN_EMAIL}
	FATHOM_ADMIN_PASSWORD=${FATHOM_ADMIN_PASSWORD}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	FATHOM_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 64)

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	MYSQL_DATABASE=fathomanalytics
	MYSQL_USER=fathomanalytics

	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)

	## ------------------------------
	SERVICE_SPECIFIC_MX=${SERVICE_SPECIFIC_MX}
	EOF
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine

	echo -en "\n\e[1mCreating Admin user\e[0m"
	docker exec -t fathomanalytics-service-dockerbunker bash -c "./fathom user add --email=${FATHOM_ADMIN_EMAIL} --password=${FATHOM_ADMIN_PASSWORD}" >/dev/null
	exit_response
}
