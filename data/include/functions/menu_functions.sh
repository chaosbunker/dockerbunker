# The options menu and all its associated functions
# Options are only shown if relevant in that moment (e.g. "setup" only if service is already configured, "configure" only if service has not yet been configured, "reconfigure" if service is already configured, "destroy" only if it has been configured or installed etc...)
# Services marked orange are configured but not installed.
# Services marked green are installed and running
# If containers of a service are currently stopped the services will say (stopped) behind the service name. This only works if the service has been stopped via the dockerbunker menu, because only then the service is marked as stopped in dockerbunker.env
options_menu() {
	COLUMNS=12
	exitmenu=$(printf "\e[1;4;33mExit\e[0m")
	returntopreviousmenu=$(printf "\e[1;4;33mReturn to previous menu\e[0m")
	
	container_check=1

	# if service is marked as installed, make sure all containers exist and offer to run them if necessary
	if elementInArray "${PROPER_NAME}" "${INSTALLED_SERVICES[@]}";then
		for container in "${containers[@]}";do
			RUNNING=$(docker ps -a -q --filter name=^/${container}$)
			if [[ -z ${RUNNING} ]];then
				echo -e "\n\e[3m$container container missing\e[0m\n"
				missingContainers=( "$container" )
				prompt_confirm "Restore $container?"
				if [[ $? == 0 ]];then
					restore_container
				fi
			fi
			RUNNING=$(docker ps -a -q --filter name=^/${container}$)
			[[ ${RUNNING} ]] && missingContainers=( "${missingContainers[@]}/$container" )
		done
	fi
	if [[ $RUNNING ]];then
		menu=( "Reconfigure service" "Reinstall service" "Backup Service" "Upgrade Image(s)" "Destroy \"${PROPER_NAME}\"" "${returntopreviousmenu}" "$exitmenu" )
		add_ssl_menuentry menu 2
		if elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}";then
			insert menu "Start container(s)" 3
		else
			insert menu "Restart container(s)" 3
			insert menu "Stop container(s)" 4
		fi
		[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
			&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
			&& insert menu "Restore Service" 6
	elif [[ ${missingContainers[@]} ]];then
			echo -e "\n\n\e[3m\xe2\x86\x92 \e[3mThe following containers are missing\e[0m"
			for container in "${missingContainers[@]}";do echo -e "\n    - $container";done
			menu=( "Restore missing containers" "Reconfigure service" "Start container(s)" "Stop container(s)" "Reinstall service" "Backup Service" "Restore Service" "Upgrade Image(s)" "Destroy \"${PROPER_NAME}\"" "$exitmenu" )
	elif [[ $RUNNING = false ]];then
		menu=( "Reconfigure service" "Reinstall service" "Backup Service" "Start container(s)" "Destroy \"${PROPER_NAME}\"" "$exitmenu" )
		add_ssl_menuentry menu 2
		[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
			&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
			&& insert menu "Restore Service" 3
	else
		if ! elementInArray "${PROPER_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${PROPER_NAME}" "${INSTALLED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			[[ ${STATIC} \
				&& $(ls -A "${ENV_DIR}"/static) ]] \
				&& menu=( "Configure Site" "Manage Sites" "$exitmenu" ) \
				|| menu=( "Configure Service" "$exitmenu" )
			[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
				&& [[ "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
				&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 1
		elif ! elementInArray "${PROPER_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${PROPER_NAME}" "${INSTALLED_SERVICES[@]}";then
			menu=( "Destroy \"${PROPER_NAME}\"" "$exitmenu" )
			[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
				&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 1
			error="Environment file found but ${PROPER_NAME} is not marked as configured or installed. Please destroy first!"
		elif elementInArray "${PROPER_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
				error="Service marked as configured, but configuration file is missing. Please destroy first."
				menu=( "Destroy \"${PROPER_NAME}\"" "$exitmenu" )
				[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
					&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
					&& insert menu "Restore Service" 1
		elif elementInArray "${PROPER_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			menu=( "Reconfigure service" "Setup service" "Destroy \"${PROPER_NAME}\"" "$exitmenu" )
			[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
				&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 2
		fi
	fi

	echo ""
	echo -e "\e[4m${PROPER_NAME}\e[0m"
	if [[ $error ]];then
		echo -e "\n\e[3m$error\e[0m\n"
	fi
	select choice in "${menu[@]}"
	do
		case $choice in
			"Configure Site")
				echo -e "\n\e[3m\xe2\x86\x92 Configure ${PROPER_NAME}\e[0m\n"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh configure
				say_done
				sleep 0.2
				break
				;;
			"Configure Service")
				echo -e "\n\e[3m\xe2\x86\x92 Configure ${PROPER_NAME}\e[0m\n"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh configure
				sleep 0.2
				break
				;;
			"Manage Sites")
				echo -e "\n\e[3m\xe2\x86\x92 Manage sites\e[0m"
				static_menu
				sleep 0.2
				break
				;;
			"Reconfigure service")
				echo -e "\n\e[3m\xe2\x86\x92 Reconfigure ${PROPER_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh reconfigure
				break
				;;
			"Setup service")
				# Set up nginx container if not yet present
				setup_nginx
				echo -e "\n\e[3m\xe2\x86\x92 Setup ${PROPER_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh setup
				sleep 0.2
				break
			;;
			"Reinstall service")
				echo -e "\n\e[3m\xe2\x86\x92 Reinstall ${PROPER_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh reinstall
				say_done
				sleep 0.2
				break
			;;
			"Restore missing containers")
				echo -e "\n\e[3m\xe2\x86\x92 Restoring containers\e[0m"
				for container in ${missingContainers[@]};do
					restore_container
				done
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh
				;;
			"Upgrade Image(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Upgrade ${PROPER_NAME} images\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh upgrade
				say_done
				sleep 0.2
				break
			;;
			"Backup Service")
				echo -e "\n\e[3m\xe2\x86\x92 Backup Service\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh backup
				say_done
				sleep 0.2
				break
			;;
			"Restore Service")
				echo -e "\n\e[3m\xe2\x86\x92 Restore Service\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh restore
				say_done
				sleep 0.2
				break
			;;
			"Generate self-signed certificate")
				generate_certificate
				restart_nginx
				say_done
				sleep 0.2
				break
			;;
			"Obtain Let's Encrypt certificate")
				get_le_cert
				say_done
				sleep 0.2
				exit
			;;
			"Renew Let's Encrypt certificate")
				get_le_cert renew
				say_done
				sleep 0.2
				exit
			;;
			"Restart container(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Restart ${PROPER_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh restart_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh
				break
			;;
			"Start container(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Start ${PROPER_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh start_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh
				break
			;;
			"Stop container(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Stop ${PROPER_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh stop_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/${SERVICE_NAME}.sh
				break
			;;
			"Destroy \"${PROPER_NAME}\"")
				echo -e "\n\e[3m\xe2\x86\x92 Destroy ${PROPER_NAME}\e[0m"
				echo ""
				echo "The following will be removed:"
				echo ""

				for container in ${containers[@]};do
					[[ $(docker ps -a -q --filter name=^/${container}$) ]]  \
					&& containers_found+=( $container )
				done

				[[ ${containers_found[0]} ]] \
					&& echo "- ${PROPER_NAME} container(s)"

				for volume in ${volumes[@]};do
					[[ $(docker volume ls -q --filter name=^${volume}$) ]] \
						&& volumes_found+=( $volume )
				done

				[[ ${volumes_found[0]} ]] \
					&& echo "- ${PROPER_NAME} volume(s)"

				[[ -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env \
					|| -f "${ENV_DIR}"/${SERVICE_NAME}.env ]] \
					&& echo "- ${PROPER_NAME} environment file(s)"

				[[ -d "${CONF_DIR}"/${SERVICE_NAME} ]] \
					&& echo "- ${PROPER_NAME} config file(s)"

				[[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf \
					|| -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
					&& echo "- nginx configuration of ${SERVICE_DOMAIN[0]}"

				[[ ${SERVICE_DOMAIN[0]} \
					&& -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ]] \
					&& echo "- self-signed certificate for ${SERVICE_DOMAIN[0]}"

				echo ""

				prompt_confirm "Continue?" \
					&& prompt_confirm "Are you sure?" \
					&& . "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh destroy_service

				say_done
				sleep 0.2
				exec ${BASE_DIR}/dockerbunker.sh
			;;
			"$returntopreviousmenu")
				exec ./dockerbunker.sh
			;;
			"$exitmenu")
				exit 0
			;;
			*)
				echo "Invalid option."
				;;
		esac
	done
}

get_le_cert() {
	if ! [[ $1 == "renew" ]];then
		echo -e "\n\e[3m\xe2\x86\x92 Obtain Let's Encrypt certificate\e[0m"
		[[ -z ${LE_EMAIL} ]] && get_le_email
		if [[ ${STATIC} ]];then
			sed -i "s/SSL_CHOICE=.*/SSL_CHOICE=le/" "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
			sed -i "s/LE_EMAIL=.*/LE_EMAIL="${LE_EMAIL}"/" "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
		else
			sed -i "s/SSL_CHOICE=.*/SSL_CHOICE=le/" "${SERVICE_ENV}"
			sed -i "s/LE_EMAIL=.*/LE_EMAIL="${LE_EMAIL}"/" "${SERVICE_ENV}"
		fi
		elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}" \
			&& "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh start_containers
		if [[ ${SERVICE_DOMAIN[0]} && -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} \
			&& ! -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
			# Back up self-signed certificate
			mv "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.{pem,pem.backup}
			mv "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.{pem,pem.backup}
			# Symlink letsencrypt certificate
			ln -sf "/etc/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]}/fullchain.pem" "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem
			ln -sf "/etc/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]}/privkey.pem" "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem
		fi
		letsencrypt issue
	else
		echo -e "\n\e[3m\xe2\x86\x92 Renew Let's Encrypt certificate\e[0m"
		export prevent_nginx_restart=1
		bash "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh letsencrypt issue
	fi
}

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
	|| elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}" \
	|| [[ ${FUNCNAME[2]} == "destroy_service" ]];then \
		return
	fi

	! [[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& [[ -z $reconfigure ]] \
		&& echo -e "\n\e[31mNginx configuration for ${PROPER_NAME} is not active or missing.\nPlease make sure ${PROPER_NAME} is properly configured.\e[0m\n" \
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
	
	if ! elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}";then
		STOPPED_SERVICES+=( "${PROPER_NAME}" )
		sed -i '/STOPPED_SERVICES/d' "${ENV_DIR}"/dockerbunker.env
		declare -p STOPPED_SERVICES >> "${ENV_DIR}"/dockerbunker.env
	fi
	
	[[ -z $prevent_nginx_restart ]] && restart_nginx
}

activate_nginx_conf() {
	[[ ${SERVICE_NAME} == "nginx" ]] && return
	[[ ${FUNCNAME[1]} != "setup" ]] \
		&& elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}" \
		&& ! [[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& echo -e "\n\e[31mNginx configuration for ${PROPER_NAME} is not inactive or missing. Please make sure ${PROPER_NAME} is properly configured.\e[0m\n" \
		&& return
	# activate nginx config
	[[ -d "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} ]] \
		&& mv "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/conf.d/
	[[ -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
		&& mv "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/conf.d/
}

start_containers() {
	RUNNING=$(docker inspect --format="{{.State.Running}}" ${NGINX_CONTAINER} 2> /dev/null)
	[[ $RUNNING == "false" ]] || [[ -z $RUNNING ]] && bash -c "${SERVICES_DIR}"/nginx/nginx.sh setup
	echo -e "\n\e[1mStarting containers\e[0m"
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
	echo -e "\n\e[1mStopping containers\e[0m"
	for container in "${containers[@]}";do
		[[ $(docker ps -q --filter name=^/${container}$) ]] \
			&& echo -en "- $container" \
			&& docker stop $container >/dev/null 2>&1 \
			&& exit_response \
			|| echo "- $container (not running)"
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
		echo -e "\n\e[1mRemoving containers\e[0m"
		for container in "${containers[@]}";do
			[[ $(docker ps -q --filter "status=exited" --filter name=^/${container}$) || $(docker ps -q --filter "status=restarting" --filter name=^/${container}$) ]] \
				&& echo -en "- $container" \
				&& docker rm -f $container >/dev/null 2>&1 \
				&& exit_response \
				|| echo "- $container (not found)"
		done
	elif [[ ${#containers_found[@]} > 0 ]];then
		echo -e "\n\e[1mRemoving containers\e[0m"
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
		echo -e "\n\e[1mRemoving volumes\e[0m"
		for volume in "${!volumes[@]}";do
			[[ $(docker volume ls -q --filter name=^${volume}$) ]] \
				&& echo -en "- ${volume}" \
				&& docker volume rm ${volume} >/dev/null \
				&& exit_response \
				|| echo "- ${volume} (not found)"
		done
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

restart_containers() {
	echo -e "\n\e[1mRestarting containers\e[0m"
	[[ $(docker ps -a -q --filter name=^/${NGINX_CONTAINER}$ 2> /dev/null) ]] \
		|| bash -c "${SERVICES_DIR}"/nginx/nginx.sh setup
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
		prompt_confirm "Remove all images?"
		if [[ $? == 0 ]];then
			echo -e "\n\e[1mRemoving images\e[0m"
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
		&& echo -en "\n\e[1mRemoving ${CONF_DIR}/${SERVICE_NAME}\e[0m" \
		&& rm -r "${CONF_DIR}/${SERVICE_NAME}" \

}

remove_environment_files() {
	[[ -f "${ENV_DIR}"/${SERVICE_NAME}.env ]] \
		&& echo -en "\n\e[1mRemoving ${SERVICE_NAME}.env\e[0m" \
		&& rm "${ENV_DIR}"/${SERVICE_NAME}.env \
		&& exit_response

	[[ ${SERVICE_SPECIFIC_MX} ]] \
		&& [[ -f "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ]] \
		&& rm "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env

	[[ ${STATIC} \
		&& -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env ]] \
		&& echo -en "\n\e[1mRemoving ${SERVICE_DOMAIN[0]}.env\e[0m" \
		&& rm "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env \
		&& exit_response
}

remove_ssl_certificate() {
	if [[ ${SERVICE_DOMAIN[0]} ]] \
		&& [[ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ]];then
		echo -en "\n\e[1mRemoving SSL Certificate\e[0m"
		rm -r "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}
		exit_response
	fi
}

destroy_service() {
	if [[ -z ${STATIC} ]];then
		disconnect_from_dockerbunker_network
		stop_containers
		remove_containers
		remove_volumes
		remove_networks
		remove_images

		echo -en "\n\e[1mRemoving ${PROPER_NAME} from dockerbunker.env\e[0m"
		remove_from_WEB_SERVICES
		remove_from_CONFIGURED_SERVICES
		remove_from_INSTALLED_SERVICES
		remove_from_STOPPED_SERVICES
		remove_from_CONTAINERS_IN_DOCKERBUNKER_NETWORK
	else
		[[ -d ${STATIC_HOME} ]] \
			&& prompt_confirm "Remove HTML directory [${STATIC_HOME}]" \
			&& echo -en "\n\e[1mRemoving ${STATIC_HOME}\e[0m" \
			&& rm -r ${STATIC_HOME} >/dev/null \
			&& exit_response
		echo -en "\n\e[1mRemoving "${SERVICE_DOMAIN[0]}" from dockerbunker.env\e[0m"
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
		&& bash "${SERVICES_DIR}"/nginx/nginx.sh destroy_service \
		&& return

	[[ -z $prevent_nginx_restart ]] \
		&& [[ ${SERVICE_NAME} != "nginx" ]] \
		&& restart_nginx
}


# minimal setup routine. if more is needed add custom setup() in data/services/${SERVICE_NAME}/${SERVICE_NAME}.sh
setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

# minimal upgrade routine. if more is needed add custom upgrade() in data/services/${SERVICE_NAME}/${SERVICE_NAME}.sh
upgrade() {
	pull_and_compare

	stop_containers
	remove_containers

	docker_run_all

	delete_old_images
}

reinstall() {
	echo ""
	prompt_confirm "Keep volumes?" && export keep_volumes=1

	disconnect_from_dockerbunker_network

	stop_containers
	remove_containers
	remove_volumes
	remove_networks

	export reinstall=1
	setup
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

disconnect_from_dockerbunker_network() {
	for container in ${add_to_network[@]};do
		[[ $container && $(docker ps -q --filter name=^/${container}$) ]] \
			&&  docker network disconnect ${NETWORK} $container >/dev/null
	done
}

reconfigure() {
	reconfigure=1
	if [[ $safe_to_keep_volumes_when_reconfiguring ]];then
		echo ""
		prompt_confirm "Keep volumes?" && keep_volumes=1
	else
		echo ""
		prompt_confirm "All volumes will be removed. Continue?" || exit 0
	fi

	disconnect_from_dockerbunker_network

	stop_containers
	remove_containers
	remove_volumes
	remove_networks

	remove_nginx_conf
	remove_ssl_certificate

	remove_environment_files
	remove_service_conf

	[[ $(grep "${PROPER_NAME}" "${ENV_DIR}"/dockerbunker.env) ]] && echo -en "\n\e[1mRemoving ${PROPER_NAME} from dockerbunker.env\e[0m"
	remove_from_WEB_SERVICES
	remove_from_CONFIGURED_SERVICES
	remove_from_INSTALLED_SERVICES
	remove_from_STOPPED_SERVICES
	remove_from_CONTAINERS_IN_DOCKERBUNKER_NETWORK

	exit_response
	echo ""
	configure
}

# all functions that manipulate all containers
start_all() {
	start_nginx
	for PROPER_NAME in "${STOPPED_SERVICES[@]}";do
		SERVICE_NAME="$(echo -e "${service,,}" | tr -cd '[:alnum:]')"
		source "${ENV_DIR}"/${SERVICE_NAME}.env
		source "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh start_containers
	done
	restart_nginx
}

restart_all() {
	for service in "${INSTALLED_SERVICES[@]}";do
		service="$(echo -e "${service,,}" | tr -cd '[:alnum:]')"
		source "${ENV_DIR}/${service}.env"
		source "${SERVICES_DIR}"/${service}/${service}.sh restart_containers
	done
	restart_nginx
}
stop_all() {
	for service in "${INSTALLED_SERVICES[@]}";do
		service="$(echo -e "${service,,}" | tr -cd '[:alnum:]')"
		if ! elementInArray "$service" "${STOPPED_SERVICES[@]}";then
			source "${SERVICE_ENV}"
			source "${SERVICES_DIR}"/${service}/${service}.sh stop_containers
		fi
	done
	stop_nginx
	export prevent_nginx_restart=1
}

destroy_all() {
	# destroy_service() is calling restart_nginx, we don't want this happening after each service is destroyed
	export prevent_nginx_restart=1
	export destroy_all=1
	all_services=( "${INSTALLED_SERVICES[@]}" "${CONFIGURED_SERVICES[@]}" )
	[[ $(docker ps -q --filter name=^/nginx-dockerbunker$) ]] && all_services+=( "nginx" )
	if [[ ${all_services[0]} ]];then
			printf "\nThe following Services will be removed: \
$(for i in "${all_services[@]}";do \
if [[ "$i" == ${all_services[-1]} ]];then \
(printf "\"\e[33m%s\e[0m\" " "$i" )
			else
(printf "\"\e[33m%s\e[0m\", " "$i" )
			fi
		done) \n\n"
	fi
	prompt_confirm "Continue?"
	[[ $? == 1 ]] && echo "Exiting..." && exit 0
	for service in "${all_services[@]}";do
		SERVICE_NAME="$(echo -e "${service,,}" | tr -cd '[:alnum:]')"
		echo -e "\n\e[3m\xe2\x86\x92 Destroying $service\e[0m"
		[[ -f "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh ]] \
			&& "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh destroy_service
	done

	[[ -d "${CONF_DIR}"/nginx/conf.inactive.d ]] \
		&& [[ $(ls -A "${CONF_DIR}"/nginx/conf.inactive.d) ]] \
		&& rm -r "${CONF_DIR}"/nginx/conf.inactive.d/*
	[[ -d "${CONF_DIR}"/nginx/conf.d ]] \
		&& [[ $(ls -A "${CONF_DIR}"/nginx/conf.d) ]] \
		&& rm -r "${CONF_DIR}"/nginx/conf.d/*

	for cert_dir in $(ls "${CONF_DIR}"/nginx/ssl/);do
		[[ $cert_dir != "letsencrypt" ]] \
			&& rm -r "${CONF_DIR}"/nginx/ssl/$cert_dir
	done
	
	[[ -d "${ENV_DIR}"/static ]] \
		&& [[ $(ls -A "${ENV_DIR}"/static) ]] \
		&& rm "${ENV_DIR}"/static/*
}

add_ssl_menuentry() {
	if [[ $SSL_CHOICE == "le" ]] && [[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]];then
		# in this case le cert has been obtained previously and everything is as expected
		insert $1 "Renew Let's Encrypt certificate" $2
	elif ! [[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] && [[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
		# in this case neither a self-signed nor a le cert could be found. nginx container will refuse to restart until it can find a certificate in /etc/nginx/ssl/${SERVICE_DOMAIN} - so offer to put one there either via LE or generate new self-signed
		insert $1 "Generate self-signed certificate" $2
		insert $1 "Obtain Let's Encrypt certificate" $2
	elif [[ -f "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
		# in this case only a self-signed cert is found and a previous cert for the domain might be present in the le directories (if so it will be used and linked to)
		insert $1 "Obtain Let's Encrypt certificate" $2
	else
		# not sure when this should be the case, but if it does happen, bot options are available
		insert $1 "Generate self-signed certificate" $2
		insert $1 "Obtain Let's Encrypt certificate" $2
	fi
}

static_menu() {
	! [[ ${STATIC_SITES[@]} ]] \
		&& echo -e "\n\e[1mNo existing sites found\e[0m" \
		&& exec "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh

	# Display all static sites in a menu
	
	# Option menu from directory listing, based on terdon's answer in https://askubuntu.com/a/682146
	## Collect all sites in the array $staticsites
	staticsites=( "${BASE_DIR}"/data/env/static/* )
	# strip path from directory names
	staticsites=( "${staticsites[@]##*/}" )
	staticsites=( "${staticsites[@]%.*}" )
	## Enable extended globbing. This lets us use @(foo|bar) to
	## match either 'foo' or 'bar'.
	shopt -s extglob
	
	## Start building the string to match against.
	string="@(${staticsites[0]}"
	## Add the rest of the site names to the string
	for((i=1;i<${#staticsites[@]};i++))
	do
	    string+="|${staticsites[$i]}"
	done
	## Close the parenthesis. $string is now @(site1|site2|...|siteN)
	string+=")"
	echo ""
	
	## Show the menu. This will list all Static Sites that have an active environment file
	select static in "${staticsites[@]}" "$returntopreviousmenu"
	do
	    case $static in
	    $string)
			if [[ -f "${BASE_DIR}"/data/env/static/${static}.env ]];then
				source "${BASE_DIR}"/data/env/static/${static}.env
			else
				echo "No environment file found for $static. Exiting."
				exit 1
			fi
			echo ""
			static_choices=( "Remove site" "$returntopreviousmenu" )
			add_ssl_menuentry static_choices 1
			select static_choice in "${static_choices[@]}"
				do
					case $static_choice in
						"Remove site")
							echo -e "\n\e[4mRemove site\e[0m"
							prompt_confirm "Remove $static" && prompt_confirm "Are you sure?" && destroy_service
							say_done
							sleep 0.2
							break
							;;
						"Generate self-signed certificate")
							generate_certificate
							restart_nginx
							say_done
							sleep 0.2
							break
						;;
						"Obtain Let's Encrypt certificate")
							get_le_cert
							say_done
							sleep 0.2
							break
						;;
						"Renew Let's Encrypt certificate")
							get_le_cert renew
							say_done
							sleep 0.2
							break
						;;
						"$returntopreviousmenu")
							static_menu
						;;
						*)
							echo "Invalid option."
							;;
					esac
				done

			break;
			;;
	
		"$returntopreviousmenu")
			exec "${SERVICES_DIR}"/statichtmlsite/statichtmlsite.sh options_menu;;
		*)
			static=""
			echo "Please choose a number from 1 to $((${#staticsites[@]}+1))";;
		esac
	done
}

backup() {
	! [[ -d ${BASE_DIR}/data/backup/${SERVICE_NAME} ]] && mkdir -p ${BASE_DIR}/data/backup/${SERVICE_NAME}
	NOW=$(date -d "today" +"%Y%m%d_%H%M")

	# compressing volumes
	echo -e "\n\e[1mCompressing volumes\e[0m"
	for volume in ${!volumes[@]};do
		docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BASE_DIR}/data/backup/${SERVICE_NAME}/${NOW}:/backup debian:jessie tar cvfz /backup/${volume}.tar.gz /${volumes[$volume]##*/} 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
		echo -en "- $volume"
		exit_response
	done

	if [ -d "${CONF_DIR}"/${SERVICE_NAME} ];then
		! [ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/conf ] \
			&& mkdir "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/conf
		echo -en "\n\e[1mBacking up configuration files\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/${SERVICE_NAME}/* "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/conf
		exit_response
	fi

	if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ];then
		! [ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl ] \
			&& mkdir "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl
		echo -en "\n\e[1mBacking up SSL certificate\e[0m"
		sleep 0.2
		[[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] \
			&& mkdir -p \
				"${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/live \
				"${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/archive \
				"${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/renewal \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]} "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/archive \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/live \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/renewal
		cp -r "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/ssl
		exit_response
	fi

	if [ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ];then
		! [ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/nginx ] \
			&& mkdir -p "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/nginx
		echo -en "\n\e[1mBacking up nginx configuration\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}* "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}/nginx
		exit_response
	fi

	if [ -f "${ENV_DIR}"/${SERVICE_NAME}.env ];then
		echo -en "\n\e[1mBacking up environemt file(s)\e[0m"
		sleep 0.2
		[[ -f "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ]] \
			&& cp "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}
		cp "${ENV_DIR}"/${SERVICE_NAME}.env "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${NOW}
		exit_response
	else
		echo -e "\n\e[3mCould not find environment file(s) for ${PROPER_NAME}.\e[0m"
	fi
}

restore() {
echo ${FUNCNAME[@]}
	restoring=1
	## Collect the backups in the array $backups
	backups=( "${BASE_DIR}"/data/backup/${SERVICE_NAME}/* )
	# strip path from directory names
	backups=( "${backups[@]##*/}" )
	## Enable extended globbing. This lets us use @(foo|bar) to
	## match either 'foo' or 'bar'.
	shopt -s extglob
	
	## Start building the string to match against.
	string="@(${backups[0]}"
	## Add the rest of the backups to the string
	for((i=1;i<${#backups[@]};i++))
	do
	    string+="|${backups[$i]}"
	done
	## Close the parenthesis. $string is now @(backup1|backup2|...|backupN)
	string+=")"
	# only continue if backup directory is not empty
	if [[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME} ]] \
		&& [[ $(ls -A "${BASE_DIR}"/data/backup/${SERVICE_NAME}) ]];then
		echo ""
		echo -e "\e[4mPlease choose a backup\e[0m"
		
		## Show the menu. This will list all backups and the string "back to previous menu"
		select backup in "${backups[@]}" "Back to previous menu"
		do
		    case $backup in
		    ## If the choice is one of the backups (if it matches $string)
		    $string)
				! [[ -f "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env ]] \
					&& echo -e "\n\e[3mCould not find ${SERVICE_NAME}.env in ${backup}\e[0m" \
					&& return
				# destroy current service if found
				if [[ $(docker ps -q -a --filter name=^/"${SERVICE_NAME}-service-dockerbunker"$) ]];then
					echo -e "\n\e[3m\xe2\x86\x92 Destroying ${PROPER_NAME}\e[0m"
					destroy_service
				fi

				source "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env

				! [[ $(docker ps -q --filter name=^/nginx-dockerbunker$) ]] && setup_nginx
				echo -e "\n\e[3m\xe2\x86\x92 Restoring ${PROPER_NAME}\e[0m"
				for volume in ${!volumes[@]};do
					[[ $(docker volume ls --filter name=^${volume}$) ]] \
						&& docker volume create $volume >/dev/null
					docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BASE_DIR}/data/backup/${SERVICE_NAME}/${backup}:/backup debian:jessie tar xvfz /backup/${volume}.tar.gz 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
					echo -en "\n\e[1mDecompressing $volume\e[0m"
					exit_response
				done
				sleep 0.2

				if [ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/conf ];then
					! [ -d "${CONF_DIR}"/${SERVICE_NAME} ] \
						&& mkdir "${CONF_DIR}"/${SERVICE_NAME}
					echo -en "\n\e[1mRestoring configuration files\e[0m"
					sleep 0.2
					cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/conf/* "${CONF_DIR}"/${SERVICE_NAME}
					exit_response
				fi

				if [ -f "${BASE_DIR}"/data/backup/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}.conf ];then
					! [[ -d "${CONF_DIR}"/nginx/conf.inactive.d ]] \
						&& mkdir "${CONF_DIR}"/nginx/conf.inactive.d
					echo -en "\n\e[1mRestoring nginx configuration\e[0m"
					cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}* "${CONF_DIR}"/nginx/conf.inactive.d
					exit_response
				fi
				sleep 0.2


				if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl ];then
					! [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ] \
						&& mkdir -p "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}
					echo -en "\n\e[1mRestoring SSL certificate\e[0m"
					sleep 0.2
					[[ -d "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] \
						&& mkdir -p \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/live \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/archive \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/renewal \
						&& cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl/letsencrypt/archive \
						&& cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl/letsencrypt/live \
						&& cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal
					cp -r "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/ssl/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl
					exit_response
				fi

				if [ -f "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env ];then
					echo -en "\n\e[1mRestoring environemt file(s)\e[0m"
					sleep 0.2
					[[ -f "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_SPECIFIC_MX}mx.env ]] \
						&& cp "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_SPECIFIC_MX}mx.env "${ENV_DIR}"
					cp "${BASE_DIR}"/data/backup/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env "${ENV_DIR}"
					exit_response
				fi
				create_networks
				docker_run_all
				activate_nginx_conf
				post_setup_routine
				exit 0
		        ;;
		
		    "Back to previous menu")
				"${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh
				;;
		    *)
		        backup=""
		        echo "Please choose a number from 1 to $((${#backups[@]}+1))";;
		    esac
		done
	else
		echo -e "\n\e[1mNo ${PROPER_NAME} backup found\e[0m"
		echo -e "\n\e[3m\xe2\x86\x92 Checking service status"
		exec "${SERVICES_DIR}"/${SERVICE_NAME}/${SERVICE_NAME}.sh
	fi
}
