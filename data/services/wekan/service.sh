
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-db-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="quay.io/wekan/wekan" [db]="mongo:3.2.12" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/data/db" [${SERVICE_NAME}-db-vol-2]="/dump" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mWekan Settings\e[0m"

	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME=${PROPER_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	MONGO_URL=mongodb://db:27017/wekan
	ROOT_URL=https://${SERVICE_DOMAIN}

	EOF

	post_configure_routine
}
