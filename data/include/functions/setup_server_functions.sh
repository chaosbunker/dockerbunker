#######
#
# function: setup_nginx
# function: create_networks
# function: set_nginx_config
# function: basic_nginx
# function: connect_containers_to_network
#######

setup_nginx() {
	[[ ! $(docker ps -q --filter name=^/${NGINX_CONTAINER}$) ]] && bash "${SERVER_DIR}/nginx/init.sh" setup
}

create_networks() {
	for network in "${networks[@]}";do
		[[ $(docker network ls -q --filter name=^${network}$) ]] \
			&& docker network rm $network >/dev/null
		[[ ! $(docker network ls -q --filter name=^${network}$) ]] \
			&& docker network create $network >/dev/null
	done
}

# set nginx service.config
set_nginx_config() {
	prompt_confirm "Use default Service Nginx.Config File?: ${SERVICE_SERVER_CONFIG}" && custom_server_config=1;

	if [[ -z $custom_server_config ]];then
		SERVICE_SERVER_CONFIG+="notexists"

		# loop if file not exists
		while [[ true ]];do
			if [[ -f "${SERVICE_SERVER_CONFIG}" ]]; then
				echo -e "\e[32m[Path is valid]\e[0m";
				break;
			else
				echo -e "\e[31m[Invalid Path]\e[0m";

				read -p "Set new Service Config Path: " -ei "/nginx/service.conf" CUSTOM_SERVICE_SERVER_CONFIG
				SERVICE_SERVER_CONFIG="${SERVICES_DIR}/${SERVICE_NAME}${CUSTOM_SERVICE_SERVER_CONFIG}"
			fi
		done

	fi
}

# this generates the nginx configuration for the service that is being set up
# and puts it into data/services/ngix/conf.d
basic_nginx() {
	if [[ -z $reinstall ]];then
		[[ ! -d "${CONF_DIR}"/nginx/ssl ]] \
			&& mkdir -p "${CONF_DIR}"/nginx/ssl
		[[ ! -f "${CONF_DIR}"/nginx/ssl/dhparam.pem ]] \
			&& cp "${SERVER_DIR}/nginx/ssl/dhparam.pem" "${CONF_DIR}"/nginx/ssl
		[[ ! -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ]] && \
			mkdir -p "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}

		if [[ ! -f "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
			generate_certificate
		fi

		[[ ! -d "${CONF_DIR}"/nginx/conf.d ]] && \
			mkdir -p "${CONF_DIR}"/nginx/conf.d
		if [[ ! -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]];then
			# set path fallback and use default service.config path
			if [[ -z "$SERVICE_SERVER_CONFIG" ]]; then
				SERVICE_SERVER_CONFIG="${SERVICES_DIR}/${SERVICE_NAME}/nginx/service.conf"
			fi

			cp $SERVICE_SERVER_CONFIG "${SERVICES_DIR}"/${SERVICE_NAME}/nginx/${SERVICE_DOMAIN[0]}.conf
			for variable in "${SUBSTITUTE[@]}";do
				subst="\\${variable}"
				variable=`eval echo "$variable"`
				sed -i "s@${subst}@${variable}@g;" \
				"${SERVICES_DIR}"/${SERVICE_NAME}/nginx/${SERVICE_DOMAIN[0]}.conf
			done
		fi

		echo -en "\n\e[1mMoving nginx configuration in place\e[0m"
		if [[ -f "${SERVICES_DIR}"/${SERVICE_NAME}/nginx/${SERVICE_DOMAIN[0]}.conf ]];then
			mv "${SERVICES_DIR}"/${SERVICE_NAME}/nginx/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/conf.d
			# add basic_auth
			if [[ ${BASIC_AUTH} == "yes" ]];then
				[[ ! -d "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN} ]] && \
					mkdir -p "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN}
				SALT="$(openssl rand 3)"
				SHA1="$(printf "%s%s" "${HTPASSWD}" "$SALT" | openssl dgst -binary -sha1)"
				printf "${HTUSER}:{SSHA}%s\n" "$(printf "%s%s" "$SHA1" "$SALT" | base64)" > "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN}/.htpasswd

				cp "${SERVER_DIR}/nginx/basic_auth.conf" \
					"${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN}/basic_auth.conf
				for variable in "${SUBSTITUTE[@]}";do
					subst="\\${variable}"
					variable=`eval echo "$variable"`
					sed -i "s@${subst}@${variable}@g;" \
					"${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN}/basic_auth.conf
				done
			fi
			exit_response

		else
			! [[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]] && echo "Nginx configuration file could not be found. Exiting." && exit 1
		fi
	fi
}

# called in docker_run_all if container is found in ${add_to_network}
connect_containers_to_network() {
	[[ $1 ]] \
		&& [[ $(docker ps -q --filter name=^/"${1}"$) ]] \
		&& ! [[ $(docker network inspect dockerbunker-network | grep $1) ]] \
		&& docker network connect ${NETWORK} ${1} >/dev/null \
		&& return
	for container in ${add_to_network[@]};do
		[[ $(docker ps -q --filter name=^/"${container}"$) ]] \
			&& ! [[ $(docker network inspect dockerbunker-network | grep ${container}) ]] \
			&& docker network connect ${NETWORK} ${container} >/dev/null
	done
}
