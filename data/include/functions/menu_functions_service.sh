#######
# The options menu and all its associated functions
# Options are only shown if relevant in that moment (e.g. "setup" only if service is already configured, "configure" only if service has not yet been configured, "reconfigure" if service is already configured, "destroy" only if it has been configured or installed etc...)
# Services marked orange are configured but not installed.
# Services marked green are installed and running
# If containers of a service are currently stopped the services will say (stopped) behind the service name. This only works if the service has been stopped via the dockerbunker menu, because only then the service is marked as stopped in dockerbunker.env
#
# function: start_containers
# function: stop_containers
# function: restore_container
# function: remove_containers
# function: remove_volumes
# function: restart_containers
# function: remove_images
# function: remove_service_conf
# function: remove_environment_files
# function: destroy_service
#######

start_containers() {
	RUNNING=$(docker inspect --format="{{.State.Running}}" ${NGINX_CONTAINER} 2> /dev/null)
	[[ $RUNNING == "false" ]] || [[ -z $RUNNING ]] && bash -c "${SERVER_DIR}/nginx/init.sh" setup
	echo -e "\n\e[1m$PRINT_STARTING_CONTAINERS\e[0m"
	for container in "${containers[@]}";do
		[[ $(docker ps -q --filter "status=exited" --filter name=^/${container}$) ]] \
			&& echo -en "- $container" \
			&& docker start $container >/dev/null 2>&1 \
			&& exit_response
	done
	remove_from_STOPPED_SERVICES
	activate_nginx_conf
	[[ -z $prevent_nginx_restart ]] && restart_nginx
}

stop_containers() {
	deactivate_nginx_conf
	echo -e "\n\e[1m$PRINT_STOPING_CONTAINERS\e[0m"
	for container in "${containers[@]}";do
		[[ $(docker ps -q --filter name=^/${container}$) ]] \
			&& echo -en "- $container" \
			&& docker stop $container >/dev/null 2>&1 \
			&& exit_response \
			|| echo "- $container $PRINT_NOT_RUNNING_MESSAGE"
	done
}

restore_container() {
	docker_run ${container//-/_}
	echo -en "\n- $container"
	exit_response
	connect_containers_to_network $container
	restart_nginx
}

remove_containers() {
	for container in ${containers[@]};do
		[[ $(docker ps -a -q --filter name=^/${container}$) ]]  \
		&& containers_found+=( $container )
	done
	if [[ -z ${containers_found[0]} ]];then
		echo -e "\n\e[1m$PRINT_REMOVE_CONTAINERS\e[0m"
		for container in "${containers[@]}";do
			[[ $(docker ps -q --filter "status=exited" --filter name=^/${container}$) || $(docker ps -q --filter "status=restarting" --filter name=^/${container}$) ]] \
				&& echo -en "- $container" \
				&& docker rm -f $container >/dev/null 2>&1 \
				&& exit_response \
				|| echo "- $container $PRINT_NOT_FOUND_MESSAGE"
		done
	elif [[ ${#containers_found[@]} > 0 ]];then
		echo -e "\n\e[1m$PRINT_REMOVE_CONTAINERS\e[0m"
		for container in "${containers[@]}";do
			echo -en "- $container"
			docker rm -f $container >/dev/null 2>&1
			exit_response
		done
	else
		return
	fi
}

remove_volumes() {
	if [[ ${volumes[@]} && -z $keep_volumes ]] || [[ $destroy_all ]];then
		echo -e "\n\e[1m$PRINT_REMOVE_VOLUMES\e[0m"
		for volume in "${!volumes[@]}";do
			[[ $(docker volume ls -q --filter name=^${volume}$) ]] \
				&& echo -en "- ${volume}" \
				&& docker volume rm ${volume} >/dev/null \
				&& exit_response \
				|| echo "- ${volume} $PRINT_NOT_FOUND_MESSAGE"
		done
	fi
}

restart_containers() {
	echo -e "\n\e[1m$PRINT_RESTARTING_CONTAINERS\e[0m"
	[[ $(docker ps -a -q --filter name=^/${NGINX_CONTAINER}$ 2> /dev/null) ]] \
		|| bash -c "${SERVER_DIR}/nginx/init.sh" setup
	for container in "${containers[@]}";do
		if [[ $(docker ps -q --filter name=^/${container}$) ]];then
			echo -en "- $container";docker restart $container >/dev/null 2>&1
			exit_response
		fi
	done
	[[ -z $prevent_nginx_restart ]] && restart_nginx
}

remove_images() {
	if [[ ${IMAGES[0]} ]];then
		prompt_confirm "$PRINT_REMOVE_ALL_IMAGES"
		if [[ $? == 0 ]];then
			echo -e "\n\e[1m$PRINT_REMOVING_IMAGES\e[0m"
			for image in "${IMAGES[@]}";do
				if ! [[ $(docker container ls | awk '{print $2}' | grep "\<${image}\>") ]];then
					echo -en "- $image"
					docker rmi $image >/dev/null
					exit_response
				fi
			done
		fi
	fi
}

remove_service_conf() {
	[[ -d "${CONF_DIR}/${SERVICE_NAME}" ]] \
		&& echo -en "\n\e[1m$PRINT_REMOVING ${CONF_DIR}/${SERVICE_NAME}\e[0m" \
		&& rm -r "${CONF_DIR}/${SERVICE_NAME}"
}

remove_environment_files() {
	[[ -f "${ENV_DIR}"/${SERVICE_NAME}.env ]] \
		&& echo -en "\n\e[1m$PRINT_REMOVING ${SERVICE_NAME}.env\e[0m" \
		&& rm "${ENV_DIR}"/${SERVICE_NAME}.env \
		&& exit_response

	[[ ${SERVICE_SPECIFIC_MX} ]] \
		&& [[ -f "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ]] \
		&& rm "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env

	[[ ${STATIC} \
		&& -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env ]] \
		&& echo -en "\n\e[1m$PRINT_REMOVING ${SERVICE_DOMAIN[0]}.env\e[0m" \
		&& rm "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env \
		&& exit_response
}

destroy_service() {
	if [[ -z ${STATIC} ]];then
		disconnect_from_dockerbunker_network
		stop_containers
		remove_containers
		remove_volumes
		remove_networks
		remove_images

		echo -en "\n\e[1m$PRINT_REMOVING ${SERVICE_NAME} from dockerbunker.env\e[0m"
		remove_from_WEB_SERVICES
		remove_from_CONFIGURED_SERVICES
		remove_from_INSTALLED_SERVICES
		remove_from_STOPPED_SERVICES
		remove_from_CONTAINERS_IN_DOCKERBUNKER_NETWORK
	else
		[[ -d ${STATIC_HOME} ]] \
			&& prompt_confirm "$PRINT_REMVEHTML_DIRECTORY [${STATIC_HOME}]" \
			&& echo -en "\n\e[1m$PRINT_REMOVING ${STATIC_HOME}\e[0m" \
			&& rm -r ${STATIC_HOME} >/dev/null \
			&& exit_response
		echo -en "\n\e[1m$PRINT_REMOVING "${SERVICE_DOMAIN[0]}" from dockerbunker.env\e[0m"
		remove_from_STATIC_SITES
	fi
	exit_response

	remove_nginx_conf
	remove_environment_files
	remove_service_conf
	remove_ssl_certificate

	[[ -z $destroy_all ]] \
		&& [[ -z ${INSTALLED_SERVICES[@]} ]] \
		&& [[ $(docker ps -q --filter name=^/${NGINX_CONTAINER}) ]] \
		&& [[ -z $restoring ]] \
		&& echo -e "\nNo remaining services running.\n" \
		&& prompt_confirm  "Destroy nginx as well and completely reset dockerbunker?" \
		&& bash "${SERVER_DIR}/nginx/init.sh" destroy_service \
		&& return

	[[ -z $prevent_nginx_restart ]] \
		&& [[ ${SERVICE_NAME} != "nginx" ]] \
		&& restart_nginx
}
