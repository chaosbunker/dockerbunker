
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/root/.local/share/Mailpile" [${SERVICE_NAME}-data-vol-2]="/root/.gnupg" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="chaosbunker/mailpile-docker" )


# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mMailpile Settings\e[0m"

	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	PROMPT_SSL=${PROMPT_SSL}
	COMMAND="${COMMAND}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL="${LE_EMAIL}"

	# ------------------------------
	# General Settings
	# ------------------------------

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}
