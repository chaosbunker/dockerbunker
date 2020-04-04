#######
#
# function: restart_nginx
# function: start_nginx
# function: stop_nginx
# function: deactivate_nginx_conf
# function: activate_nginx_conf
# function: remove_nginx_conf
# function: remove_networks
# function: disconnect_from_dockerbunker_network
#######

# start/stop/restart nginx container
restart_nginx() {
	echo -en "\n\e[1mRestarting nginx container\e[0m"
	docker exec -it nginx-dockerbunker nginx -t >/dev/null \
		&& docker restart ${NGINX_CONTAINER} >/dev/null
	exit_response
	if [[ $? == 1 ]];then
		echo ""
		docker exec -it nginx-dockerbunker nginx -t
		echo -e "\n\e[3m\xe2\x86\x92 \e[3m\`nginx -t\` failed. Trying to add missing containers to dockerbunker-network.\e[0m"
		for container in ${CONTAINERS_IN_DOCKERBUNKER_NETWORK[@]};do
			connect_containers_to_network ${container}
		done
		echo -en "\n\e[1mRestarting nginx container\e[0m"
		docker exec -it nginx-dockerbunker nginx -t >/dev/null \
			&& docker restart ${NGINX_CONTAINER} >/dev/null
		exit_response
		if [[ $? == 1 ]];then
			echo ""
			docker exec -it nginx-dockerbunker nginx -t
			echo -e "\n\`nginx -t\` failed again. Please resolve issue and try again."
		fi
	fi
}

start_nginx() {
	echo -en "\n\e[1mStarting nginx container\e[0m"
	docker start ${NGINX_CONTAINER} >/dev/null
	exit_response
}

stop_nginx() {
	echo -en "\n\e[1mStopping nginx container\e[0m"
	docker stop ${NGINX_CONTAINER} >/dev/null
	exit_response
}


# all functions starting/stopping/restarting containers of individual services. This is offered in every service specific menu.
deactivate_nginx_conf() {
	if [[ ${SERVICE_NAME} == "nginx" ]] \
	|| [[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
	|| elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}" \
	|| [[ ${FUNCNAME[2]} == "destroy_service" ]];then \
		return
	fi

	! [[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& [[ -z $reconfigure ]] \
		&& echo -e "\n\e[31mNginx configuration for ${SERVICE_NAME} is not active or missing.\nPlease make sure ${SERVICE_NAME} is properly configured.\e[0m\n" \
		&& return

	! [[ -d "${CONF_DIR}"/nginx/conf.inactive.d ]] \
		&& mkdir "${CONF_DIR}"/nginx/conf.inactive.d

	if [[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]];then
	echo -en "\n\e[1mDeactivating nginx configuration\e[0m"
		[[ -d "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]} ]] \
			&& mv "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/conf.inactive.d/
		mv "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/conf.inactive.d/
		exit_response
	fi

	if ! elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}";then
		STOPPED_SERVICES+=( "${SERVICE_NAME}" )
		sed -i '/STOPPED_SERVICES/d' "${ENV_DIR}"/dockerbunker.env
		declare -p STOPPED_SERVICES >> "${ENV_DIR}"/dockerbunker.env
	fi

	[[ -z $prevent_nginx_restart ]] && restart_nginx
}

activate_nginx_conf() {
	[[ ${SERVICE_NAME} == "nginx" ]] && return
	[[ ${FUNCNAME[1]} != "setup" ]] \
		&& elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}" \
		&& ! [[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& echo -e "\n\e[31mNginx configuration for ${SERVICE_NAME} is not inactive or missing. Please make sure ${SERVICE_NAME} is properly configured.\e[0m\n" \
		&& return
	# activate nginx config
	[[ -d "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} ]] \
		&& mv "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/conf.d/
	[[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& mv "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/conf.d/
}

remove_nginx_conf() {
	if [[ ${SERVICE_DOMAIN[0]} ]];then
		if [[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf || -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]];then
			echo -en "\n\e[1mRemoving nginx configuration\e[0m"
			[[ -d "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} ]] \
				&& rm -r "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} \
				|| true
			[[ -d "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]} ]] \
				&& rm -r "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]} \
				|| true
			[[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]] \
				&& rm "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf \
				|| true
			[[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
				&& rm "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf \
				|| true
			exit_response
		fi
	fi
}

remove_networks() {
	if [[ ${networks[0]} ]];then
		echo -e "\n\e[1mRemoving networks\e[0m"
		for network in "${networks[@]}";do
			[[ $(docker network ls -q --filter name=^${network}$) ]] \
				&& echo -en "- $network" \
				&& docker network rm $network >/dev/null \
				&& exit_response \
				|| echo "- $network (not found)"
		done
	fi
}

disconnect_from_dockerbunker_network() {
	for container in ${add_to_network[@]};do
		[[ $container && $(docker ps -q --filter name=^/${container}$) ]] \
			&&  docker network disconnect --force ${NETWORK} $container >/dev/null
	done
}
