
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="chaosbunker/firefox-sync-server-docker" )
declare -a networks=( )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mFirefox Sync Settings\e[0m"

	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	URL=https://${SERVICE_DOMAIN}
	FORCE_WSGI_ENVIRON=false

	EOF

	post_configure_routine
}
