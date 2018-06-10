# All functions used during configuration of a service

# only relevant if the menu shows "Configure service", although the service has already been configured or installed. This should only happen if things are messed up.
pre_configure_routine() {
	if [[ "${CONFIGURED_SERVICES[@]}" =~ ${PROPER_NAME} ]] || [[ -f "${ENV_DIR}/${SERVICE_NAME}" ]]|| [[ "${INSTALLED_SERVICES[@]}" =~ ${PROPER_NAME} ]];then
		prompt_confirm  "Existing configuration found. Destroy containers and reconfigure?" && destroy || echo "Exiting..";exit
	fi

	[[ ${repoURL} ]] && add_submodule
}

# Ask the user what fqdn to use for the service
set_domain() {
	echo ""
	[[ $INVALID ]] && echo -e "\nPlease enter a valid domain!\n"
	INVALID=
	while [[ -z $fqdn_is_valid ]];do
		if [[ -z "${SERVICE_DOMAIN[0]}" ]]; then
		  read -p "${PROPER_NAME} Service Domain (FQDN): " SERVICE_DOMAIN
		else
		  previous_domain=${SERVICE_DOMAIN[0]}
		  unset SERVICE_DOMAIN
		  read -p "${PROPER_NAME} Service Domain (FQDN): " -ei "${previous_domain}" SERVICE_DOMAIN
		fi
		validate_fqdn ${SERVICE_DOMAIN[0]}
	done
	INVALID=1
	echo ""
	
	if [[ $PROMPT_SSL ]];then
		configure_ssl
	fi
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

# Services that need to be connected to a fqdn will have the variable $PROMPT_SSL set. In that case this function asks if the user wants to get an SSL certificate from Let's Encrypt or keep using the self signed certificate that will be generated during configuration
configure_ssl() {
	prompt_confirm "Use Letsencrypt instead of a self-signed certificate?"
	if [[ $? == 0 ]];then
		SSL_CHOICE="le"
		if [[ $LE_EMAIL ]]; then
			prompt_confirm "Use ${LE_EMAIL} for Let's Encrypt?"
			if [[ $? == 1 ]];then
				read -p "Enter E-mail Adress for Let's Encrypt: " LE_EMAIL
				if ! [[ $(grep ${LE_EMAIL} "${ENV_DIR}"/dockerbunker.env) ]];then
					prompt_confirm "Use this address globally for every future service configured to obtain a Let's Encrypt certificate?"
					if [[ $? == 0 && ! $(grep ${LE_EMAIL} "${ENV_DIR}"/dockerbunker.env) ]];then
						sed -i "s/LE_EMAIL=.*/LE_EMAIL="${LE_EMAIL}"/" "${ENV_DIR}"/dockerbunker.env
					fi
				fi
			fi
		else
			get_le_email
		fi
	else
		SSL_CHOICE="ss"
	fi
}

# Ask what email to use for Let's Encrypt
get_le_email() {
	echo ""
	read -p "Existing E-mail Adress for letsencrypt: " -ei "" LE_EMAIL
	[[ -f ${SERVICE_ENV} ]] && sed -i "s/LE_EMAIL=.*/LE_EMAIL=${LE_EMAIL}/" ${SERVICE_ENV}
}

# Update dockerbunker.env to let dockerbunker know that the service is now configured, then offer a menu to choose further steps (setup/reconfigure/destroy)
post_configure_routine() {
	if [[ ${STATIC} ]];then
		if ! [[ "${STATIC_SITES[@]}" =~ "${SERVICE_DOMAIN[0]}" ]];then
			STATIC_SITES+=( "${SERVICE_DOMAIN[0]}" )
			sed -i '/STATIC_SITES/d' "${ENV_DIR}/dockerbunker.env"
			declare -p STATIC_SITES >> "${ENV_DIR}/dockerbunker.env"
		fi
	else
		[[ ${SERVICE_DOMAIN[0]} ]] && ! elementInArray "${PROPER_NAME}" "${!WEB_SERVICES[@]}" && WEB_SERVICES+=( [${PROPER_NAME}]="${SERVICE_DOMAIN[0]}" )
		! elementInArray "${PROPER_NAME}" "${CONFIGURED_SERVICES[@]}" && CONFIGURED_SERVICES+=( "${PROPER_NAME}" )
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
			bash "${BASE_DIR}/data/services/${SERVICE_NAME}/${SERVICE_NAME}.sh"
		fi
	fi
}


