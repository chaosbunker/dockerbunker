#######
# All functions used during configuration of a service
#
# function: initial_setup_routine
# function: post_setup_routine
# function: pre_configure_routine
# function: set_domain
# function: set_IP_PORT
# function: configure_mx
# function: get_le_email
# function: post_configure_routine
#######

# Build image if necessary, set up nginx container if necessary,
# create or use existing volumes, create networks if necessary, pull images if necessary
initial_setup_routine() {
	[[ ${STATIC} ]] && return

	setup_nginx

	for container in "${containers[@]}";do
		[[ ( $(docker inspect $container 2> /dev/null) &&  $? == 0 ) ]] && docker rm -f $container
	done

	docker_pull

	create_volumes

	create_networks
}

post_setup_routine() {

	remove_from_CONFIGURED_SERVICES

	! elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}" && INSTALLED_SERVICES+=( "${SERVICE_NAME}" )
	for container in ${add_to_network[@]};do
		! elementInArray "${container}" "${CONTAINERS_IN_DOCKERBUNKER_NETWORK[@]}" && CONTAINERS_IN_DOCKERBUNKER_NETWORK+=( "${container}" )
	done

	[[ -f "${ENV_DIR}/dockerbunker.env" ]] && ( sed -i '/CONFIGURED_SERVICES/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/WEB_SERVICES/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/CONTAINERS_IN_DOCKERBUNKER_NETWORK/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/INSTALLED_SERVICES/d' "${ENV_DIR}/dockerbunker.env" )
	declare -p CONFIGURED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p INSTALLED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p WEB_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p CONTAINERS_IN_DOCKERBUNKER_NETWORK >> "${ENV_DIR}/dockerbunker.env" 2>/dev/null

	if elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}";then
		remove_from_STOPPED_SERVICES
	fi

	connect_containers_to_network

	activate_nginx_conf

	if [[ $SSL_CHOICE == "le" ]] && [[ ! -d "${CONF_DIR}"/nginx/ssl/letsencrypt/${SERVICE_DOMAIN[0]} ]];then
		letsencrypt issue
	else
		restart_nginx
	fi
}

# only relevant if the menu shows "Configure service", although the service has already been configured or installed. This should only happen if things are messed up.
pre_configure_routine() {
	if [[ "${CONFIGURED_SERVICES[@]}" =~ ${SERVICE_NAME} ]] || [[ -f "${ENV_DIR}/${SERVICE_NAME}" ]]|| [[ "${INSTALLED_SERVICES[@]}" =~ ${SERVICE_NAME} ]];then
		prompt_confirm  "Existing configuration found. Destroy containers and reconfigure?" && destroy || echo "Exiting..";exit
	fi
}

# Ask the user what fqdn to use for the service
set_domain() {
	echo ""
	[[ $INVALID ]] && echo -e "\nPlease enter a valid domain!\n"
	INVALID=
	while [[ -z $fqdn_is_valid ]];do
		if [[ -z "${SERVICE_DOMAIN[0]}" ]]; then
		  read -p "${SERVICE_NAME} Service Domain (FQDN): " SERVICE_DOMAIN
		else
		  previous_domain=${SERVICE_DOMAIN[0]}
		  unset SERVICE_DOMAIN
		  read -p "${SERVICE_NAME} Service Domain (FQDN): " -ei "${previous_domain}" SERVICE_DOMAIN
		fi
		validate_fqdn ${SERVICE_DOMAIN[0]}
	done
	INVALID=1
	echo ""

	if [[ $PROMPT_SSL ]];then
		configure_ssl
	fi
}

#  Ask which IP and PORT should be used for the service
set_IP_PORT() {
	while [[ -z $ip_is_valid ]];do
		if [[ -z "${SERVICE_IP}" ]]; then
		  read -p "${SERVICE_NAME} IPv4-Adress: " SERVICE_IP
		else
		  previous_ip=${SERVICE_IP}
		  unset SERVICE_IP
		  read -p "${SERVICE_NAME} IPv4-Adress: " -ei "${previous_ip}" SERVICE_IP
		fi

		if is_ip_valid ${SERVICE_IP}; then
			ip_is_valid=1
		else
			echo -e "\n\e[31m Invlaid IP: ${SERVICE_IP}\e[0m"
		fi
	done

	read -p "${SERVICE_NAME} Port: " -ei "${SERVICE_PORT}" SERVICE_PORT
}

# Ask user for mx info. User has the option to set for the service that is being configured global mx environment variables or service specific. This creates mx.env (if it does not exist yet) or ${SERVICE_NAME}_mx.env respectively
configure_mx() {
	echo ""
	prompt_confirm "Use global SMTP Settings?"
	if [[ $? == 1 ]];then
		SERVICE_SPECIFIC_MX="${SERVICE_NAME}_"
	else
		unset SERVICE_SPECIFIC_MX
	fi
	if [[ ( $SERVICE_SPECIFIC_MX && ! -f "${ENV_DIR}/${SERVICE_SPECIFIC_MX}mx.env" ) || (  -z $SERVICE_SPECIFIC_MX && ! -f "${ENV_DIR}/mx.env" ) ]];then
		echo -e "# \n# \e[4mSMTP Settings\e[0m"

		if [ "$MX_EMAIL" ]; then
		  read -p "SMTP User: " -ei "$MX_EMAIL" MX_EMAIL
		else
		  read -p "SMTP User: " -ei "" MX_EMAIL
		fi

		unset MX_PASSWORD
		while [[ -z ${MX_PASSWORD} ]];do
			if [ $VALIDATE ];then
				echo -e "\n\e[31m  Password cannot be empty.\e[0m"
			fi
			stty_orig=`stty -g`
			stty -echo
			read -p "SMTP Password: " -ei "" MX_PASSWORD
			stty $stty_orig
			echo ""
			VALIDATE=1
		done
		unset VALIDATE

		invalid_mx=1
		while [[ $invalid_mx ]];do
			if [ -z "$MX_HOSTNAME" ]; then
			  read -p "MX Hostname for email delivery (FQDN): " -ei "smtp.example.com" MX_HOSTNAME
			else
			  read -p "MX Hostname for email delivery (FQDN): " -ei "$MX_HOSTNAME" MX_HOSTNAME
			fi
			# only verify mx hostname if `host` found
			if dpkg -l host &>/dev/null;then
				host -t mx ${MX_EMAIL#*@} | grep ${MX_HOSTNAME} >/dev/null \
				&& unset invalid_mx \
				|| echo -e "\n\e[31m${MX_HOSTNAME} not a valid mx entry for ${MX_EMAIL#*@}.\e[0m\n"
			else
				unset invalid_mx
			fi
		done
		cat <<-EOF >> "${ENV_DIR}/${SERVICE_SPECIFIC_MX}mx.env"
		#MX
		## ------------------------------

		MX_HOSTNAME=${MX_HOSTNAME}
		MX_EMAIL=${MX_EMAIL}
		MX_PASSWORD="${MX_PASSWORD}"

		## ------------------------------
		#/MX
		EOF
	fi
}

# Ask what email to use for Let's Encrypt
get_le_email() {
	echo ""
	read -p "Existing E-mail Adress for letsencrypt: " -ei "" LE_EMAIL
	[[ -f ${SERVICE_ENV} ]] && sed -i "s/LE_EMAIL=.*/LE_EMAIL=${LE_EMAIL}/" ${SERVICE_ENV}
}

# Update dockerbunker.env to let dockerbunker know that the service is now configured,
# then offer a menu to choose further steps (setup/reconfigure/destroy)
post_configure_routine() {
	if [[ ${STATIC} ]];then
		# configuration for static HTML sites
		if ! [[ "${STATIC_SITES[@]}" =~ "${SERVICE_DOMAIN[0]}" ]];then
			STATIC_SITES+=( "${SERVICE_DOMAIN[0]}" )
			sed -i '/STATIC_SITES/d' "${ENV_DIR}/dockerbunker.env"
			declare -p STATIC_SITES >> "${ENV_DIR}/dockerbunker.env"
		fi
	else
		# configuration for docker services
		[[ ${SERVICE_DOMAIN[0]} ]] && ! elementInArray "${SERVICE_NAME}" "${!WEB_SERVICES[@]}" && WEB_SERVICES+=( [${SERVICE_NAME}]="${SERVICE_DOMAIN[0]}" )
		! elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" && CONFIGURED_SERVICES+=( "${SERVICE_NAME}" )

		for containers in ${add_to_network[@]};do
			[[ ( $container && ! "${CONTAINERS_IN_DOCKERBUNKER_NETWORK[@]}" =~ "${container}" ) ]] && CONTAINERS_IN_DOCKERBUNKER_NETWORK+=( "${container}" )
		done

		if [[ -f "${ENV_DIR}/dockerbunker.env" ]];then
			sed -i '/CONFIGURED_SERVICES/d' "${ENV_DIR}/dockerbunker.env"
			sed -i '/WEB_SERVICES/d' "${ENV_DIR}/dockerbunker.env"
			sed -i '/CONTAINERS_IN_DOCKERBUNKER_NETWORK/d' "${ENV_DIR}/dockerbunker.env"
			sed -i '/INSTALLED_SERVICES/d' "${ENV_DIR}/dockerbunker.env"
			declare -p CONFIGURED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
			declare -p INSTALLED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
			declare -p WEB_SERVICES >> "${ENV_DIR}/dockerbunker.env"
			declare -p CONTAINERS_IN_DOCKERBUNKER_NETWORK >> "${ENV_DIR}/dockerbunker.env" 2>/dev/null
			echo ""
			echo "Please run \"Setup service\" next."
			bash "${BASE_DIR}/data/services/${SERVICE_NAME}/init.sh"
		fi
	fi
}
