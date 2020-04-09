
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/var/www/app/data" [${SERVICE_NAME}-data-vol-2]="/var/www/app/plugins" )
declare -a networks=( )
declare -A IMAGES=( [service]="kanboard/kanboard:v1.2.1" )


# service specific functions
# to setup save service specific docker-variables to environment file
configure() {

	pre_configure_routine

	echo -e "# \e[4mKanboard Settings\e[0m"
	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	# ------------------------------
	# General Settings
	# ------------------------------

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}
