
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "bitbucket-postgres-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker"  )
declare -A IMAGES=( [service]="dockerbunker/${SERVICE_NAME}" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/var/lib/postgresql/data" [${SERVICE_NAME}-data-vol-1]="/var/atlassian/application-data/bitbucket" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [postgres]="postgres" [service]="atlassian/bitbucket-server:5" )

# service specific functions
# to setup save service specific docker-variables to environment file
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
