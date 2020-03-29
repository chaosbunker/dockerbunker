
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/etc/opt/gitlab" [${SERVICE_NAME}-conf-vol-1]="/etc/gitlab" [${SERVICE_NAME}-log-vol-1]="/var/log/gitlab" )
declare -a networks=( )
declare -A IMAGES=( [service]="gitlab/gitlab-ce:latest" )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4m'${PROPER_NAME}' Settings\e[0m"

	set_domain

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}
setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	#/proc/sys/fs/file-max #this is shared with the host:
	GITLAB_FILEMAX=1000000
	[[ $(cat /proc/sys/fs/file-max) -lt ${GITLAB_FILEMAX} ]] && echo $GITLAB_FILEMAX > /proc/sys/fs/file-max

	docker_run_all

	post_setup_routine
}
