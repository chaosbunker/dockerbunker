
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-db-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" [${SERVICE_NAME}-data-vol-1]="/var/www/html/wp-content" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="chaosbunker/${SERVICE_NAME}-docker" )


# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4m${PROPER_NAME} Settings\e[0m"

	set_domain

	prompt_confirm "Use Basic Authentication to protect /wp-admin?"
	if [[ $? == 0 ]];then
		BASIC_AUTH="yes"
		if [[ -z $HTUSER ]]; then
			while [[ -z ${HTUSER} ]];do
				read -p "Basic Auth Username: " -ei "" HTUSER
			done
		else
			read -p "Basic Auth Username: " -ei "${HTUSER}" HTUSER
		fi
		unset HTPASSWD
		while [[ "${#HTPASSWD}" -le 6 || "$HTPASSWD" != *[A-Z]* || "$HTPASSWD" != *[a-z]* || "$HTPASSWD" != *[0-9]* ]];do
			if [ $VALIDATE ];then
				echo -e "\n\e[31m  Password does not meet requirements\e[0m"
			fi
				stty_orig=$(stty -g)
				stty -echo
		  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6, Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" HTPASSWD
				stty "$stty_orig"
				echo ""
			VALIDATE=1
		done
		unset VALIDATE
		echo ""
	else
		AUTH_SWITCH="#"
		BASIC_AUTH="no"
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
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	LE_EMAIL=${LE_EMAIL}

	# ------------------------------
	# Security Settings
	# ------------------------------

	SSL_CHOICE=${SSL_CHOICE}
	BASIC_AUTH=${BASIC_AUTH}
	AUTH_SWITCH=${AUTH_SWITCH}
	HTUSER=${HTUSER}
	HTPASSWD=${HTPASSWD}

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	MYSQL_DATABASE=wpdb
	MYSQL_USER=wordpress

	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	EOF
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}
setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${AUTH_SWITCH}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}
