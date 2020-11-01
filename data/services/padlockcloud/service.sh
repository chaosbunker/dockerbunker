
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/padlock/db"  )
declare -A IMAGES=( [service]="chaosbunker/padlock-cloud" )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mPadlock Cloud Settings\e[0m"

	set_domain

	echo ""

	configure_mx

	[[ -f ${CONF_DIR}/padlockcloud/whitelist ]] && rm ${CONF_DIR}/padlockcloud/whitelist
	! [[ -d ${CONF_DIR}/padlockcloud ]] && mkdir ${CONF_DIR}/padlockcloud
	read -p "Enter E-Mail addresses to whitelist (separated by spaces): " whitelist
	whitelist=( ${whitelist} )
	for email in ${whitelist[@]};do
		echo $email >> ${CONF_DIR}/padlockcloud/whitelist
	done

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

	SERVICE_DOMAIN=${SERVICE_DOMAIN}

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
}
