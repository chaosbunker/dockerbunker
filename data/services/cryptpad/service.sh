
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="chaosbunker/${SERVICE_NAME}-docker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/cryptpad/customize" [${SERVICE_NAME}-data-vol-2]="/cryptpad/datastore" )
declare -a networks=( )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mCryptpad Settings\e[0m"

	set_domain

	cat <<-EOF >> ${SERVICE_ENV}
	PROPER_NAME=${PROPER_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	USE_SSL=true
	STORAGE='./storage/file'
	LOG_TO_STDOUT=true

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}
