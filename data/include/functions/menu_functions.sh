#######
#
# function: options_menu
# function: start_all
# function: restart_all
# function: stop_all
# function: destroy_all
# function: setup
# function: upgrade
# function: reinstall
# function: reconfigure
# function: static_menu
# function: backup
# function: restore
#######

options_menu() {
	exitmenu=$(printf "\e[1;4;33mExit\e[0m")
	returntopreviousmenu=$(printf "\e[1;4;33mReturn to previous menu\e[0m")

	container_check=1

	# if service is marked as installed, make sure all containers exist and offer to run them if necessary
	if elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}";then
		for container in "${containers[@]}";do
			RUNNING=$(docker ps -a -q --filter name=^/${container}$)
			echo "Status: $RUNNING"
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
		menu=( "Reconfigure service" "Reinstall service" "Backup Service" "Upgrade Image(s)" "Destroy \"${SERVICE_NAME}\"" "${returntopreviousmenu}" "$exitmenu" )
		add_ssl_menuentry menu 2
		if elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}";then
			insert menu "Start container(s)" 3
		else
			insert menu "Restart container(s)" 3
			insert menu "Stop container(s)" 4
		fi
		[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "Restore Service" 6
	elif [[ ${missingContainers[@]} ]];then
			echo -e "\n\n\e[3m\xe2\x86\x92 \e[3mThe following containers are missing\e[0m"
			for container in "${missingContainers[@]}";do echo -e "\n    - $container";done
			menu=( "Restore missing containers" "Reconfigure service" "Start container(s)" "Stop container(s)" "Reinstall service" "Backup Service" "Restore Service" "Upgrade Image(s)" "Destroy \"${SERVICE_NAME}\"" "$exitmenu" )
	elif [[ $RUNNING = false ]];then
		menu=( "Reconfigure service" "Reinstall service" "Backup Service" "Start container(s)" "Destroy \"${SERVICE_NAME}\"" "$exitmenu" )
		add_ssl_menuentry menu 2
		[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "Restore Service" 3
	else
		if ! elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			[[ ${STATIC} \
				&& $(ls -A "${ENV_DIR}"/static) ]] \
				&& menu=( "Configure Site" "Manage Sites" "$exitmenu" ) \
				|| menu=( "Configure Service" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
				&& [[ ${BACKUP_DIR}/${SERVICE_NAME} ]] \
				&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 1
		elif ! elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}";then
			menu=( "Destroy \"${SERVICE_NAME}\"" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
				&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 1
			error="Environment file found but ${SERVICE_NAME} is not marked as configured or installed. Please destroy first!"
		elif elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
				error="Service marked as configured, but configuration file is missing. Please destroy first."
				menu=( "Destroy \"${SERVICE_NAME}\"" "$exitmenu" )
				[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
					&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
					&& insert menu "Restore Service" 1
		elif elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			menu=( "Reconfigure service" "Setup service" "Destroy \"${SERVICE_NAME}\"" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
				&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
				&& insert menu "Restore Service" 2
		fi
	fi

	echo ""
	echo -e "\e[4m${SERVICE_NAME}\e[0m"
	if [[ $error ]];then
		echo -e "\n\e[3m$error\e[0m\n"
	fi
	select choice in "${menu[@]}"
	do
		case $choice in
			"Configure Site")
				echo -e "\n\e[3m\xe2\x86\x92 Configure ${SERVICE_NAME}\e[0m\n"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh configure
				say_done
				sleep 0.2
				break
				;;
			"Configure Service")
				echo -e "\n\e[3m\xe2\x86\x92 Configure ${SERVICE_NAME}\e[0m\n"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh configure
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
				echo -e "\n\e[3m\xe2\x86\x92 Reconfigure ${SERVICE_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh reconfigure
				break
				;;
			"Setup service")
				# Set up nginx container if not yet present
				setup_nginx
				echo -e "\n\e[3m\xe2\x86\x92 Setup ${SERVICE_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh setup
				sleep 0.2
				break
			;;
			"Reinstall service")
				echo -e "\n\e[3m\xe2\x86\x92 Reinstall ${SERVICE_NAME}\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh reinstall
				say_done
				sleep 0.2
				break
			;;
			"Restore missing containers")
				echo -e "\n\e[3m\xe2\x86\x92 Restoring containers\e[0m"
				for container in ${missingContainers[@]};do
					restore_container
				done
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh
				;;
			"Upgrade Image(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Upgrade ${SERVICE_NAME} images\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh upgrade
				say_done
				sleep 0.2
				break
			;;
			"Backup Service")
				echo -e "\n\e[3m\xe2\x86\x92 Backup Service\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh backup
				say_done
				sleep 0.2
				break
			;;
			"Restore Service")
				echo -e "\n\e[3m\xe2\x86\x92 Restore Service\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh restore
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
				echo -e "\n\e[3m\xe2\x86\x92 Restart ${SERVICE_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh restart_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh
				break
			;;
			"Start container(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Start ${SERVICE_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh start_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh
				break
			;;
			"Stop container(s)")
				echo -e "\n\e[3m\xe2\x86\x92 Stop ${SERVICE_NAME} Containers\e[0m"
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh stop_containers
				say_done
				sleep 0.2
				${SERVICES_DIR}/${SERVICE_NAME}/init.sh
				break
			;;
			"Destroy \"${SERVICE_NAME}\"")
				echo -e "\n\e[3m\xe2\x86\x92 Destroy ${SERVICE_NAME}\e[0m"
				echo ""
				echo "The following will be removed:"
				echo ""

				for container in ${containers[@]};do
					[[ $(docker ps -a -q --filter name=^/${container}$) ]]  \
					&& containers_found+=( $container )
				done

				[[ ${containers_found[0]} ]] \
					&& echo "- ${SERVICE_NAME} container(s)"

				for volume in ${volumes[@]};do
					[[ $(docker volume ls -q --filter name=^${volume}$) ]] \
						&& volumes_found+=( $volume )
				done

				[[ ${volumes_found[0]} ]] \
					&& echo "- ${SERVICE_NAME} volume(s)"

				[[ -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env \
					|| -f "${ENV_DIR}"/${SERVICE_NAME}.env ]] \
					&& echo "- ${SERVICE_NAME} environment file(s)"

				[[ -d "${CONF_DIR}"/${SERVICE_NAME} ]] \
					&& echo "- ${SERVICE_NAME} config file(s)"

				[[ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf \
					|| -f "${CONF_DIR}"/nginx/conf.inactive.d/${SERVICE_DOMAIN[0]}.conf ]] \
					&& echo "- nginx configuration of ${SERVICE_DOMAIN[0]}"

				if [[ ${SERVICE_DOMAIN[0]} ]];then
					[[ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ]] \
						&& echo "- self-signed certificate for ${SERVICE_DOMAIN[0]}"
					[[ -f "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf ]] \
						&& echo "- Let's Encrypt certificate for ${SERVICE_DOMAIN[0]}"
				fi

				echo ""

				prompt_confirm "Continue?" \
					&& prompt_confirm "Are you sure?" \
					&& . "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh destroy_service

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

# all functions that manipulate all containers
start_all() {
	start_nginx
	for SERVICE_NAME in "${STOPPED_SERVICES[@]}";do
		source "${ENV_DIR}"/${SERVICE_NAME}.env
		source "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh start_containers
	done
	restart_nginx
}

restart_all() {
	for SERVICE_NAME in "${INSTALLED_SERVICES[@]}";do
		source "${ENV_DIR}/${SERVICE_NAME}.env"
		source "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh restart_containers
	done
	restart_nginx
}

stop_all() {
	for SERVICE_NAME in "${INSTALLED_SERVICES[@]}";do
		if ! elementInArray "$SERVICE_NAME" "${STOPPED_SERVICES[@]}";then
			source "${ENV_DIR}/${SERVICE_NAME}.env"
			source "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh stop_containers
		fi
	done
	stop_nginx
	export prevent_nginx_restart=1
}

destroy_all() {
	# destroy_service() is calling restart_nginx, we don't want this happening after each service is destroyed
	[[ -z ${CONF_DIR} || -z ${ENV_DIR} || -z ${SERVICES_DIR} ]] \
		&& echo "Something went wrong. Exiting."
	export prevent_nginx_restart=1
	export destroy_all=1
	all_services=( "${INSTALLED_SERVICES[@]}" "${CONFIGURED_SERVICES[@]}" )
	[[ $(docker ps -a -q --filter name=^/nginx-dockerbunker$) ]] && all_services+=( "nginx" )
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
		[[ -f "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh ]] \
			&& "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh destroy_service
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

	rm -rf "${ENV_DIR}"/*
}

# minimal setup routine. if more is needed add custom setup() in data/services/${SERVICE_NAME}/init.sh
setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

# minimal upgrade routine. if more is needed add custom upgrade() in data/services/${SERVICE_NAME}/init.sh
upgrade() {
	pull_and_compare

	stop_containers
	remove_containers

	docker_run_all

	remove_from_STOPPED_SERVICES

	delete_old_images

	activate_nginx_conf

	restart_nginx
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

	[[ $(grep "${SERVICE_NAME}" "${ENV_DIR}"/dockerbunker.env) ]] && echo -en "\n\e[1mRemoving ${SERVICE_NAME} from dockerbunker.env\e[0m"
	remove_from_WEB_SERVICES
	remove_from_CONFIGURED_SERVICES
	remove_from_INSTALLED_SERVICES
	remove_from_STOPPED_SERVICES
	remove_from_CONTAINERS_IN_DOCKERBUNKER_NETWORK

	exit_response
	echo ""
	configure
}

static_menu() {
	! [[ ${STATIC_SITES[@]} ]] \
		&& echo -e "\n\e[1mNo existing sites found\e[0m" \
		&& exec "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh

	# Display all static sites in a menu

	# Option menu from directory listing, based on terdon's answer in https://askubuntu.com/a/682146
	## Collect all sites in the array $staticsites
	staticsites=( "${BASE_DIR}"/build/env/static/* )
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
			if [[ -f "${BASE_DIR}"/build/env/static/${static}.env ]];then
				source "${BASE_DIR}"/build/env/static/${static}.env
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
	! [[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] && mkdir -p ${BACKUP_DIR}/${SERVICE_NAME}
	NOW=$(date -d "today" +"%Y%m%d_%H%M")
	mkdir -p ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}

	# compressing volumes
	echo -e "\n\e[1mCompressing volumes\e[0m"
	for volume in ${!volumes[@]};do
		docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}:/backup debian:jessie tar cvfz /backup/${volume}.tar.gz /${volumes[$volume]##*/} 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
		echo -en "- $volume"
		exit_response
	done

	if [ -d "${CONF_DIR}"/${SERVICE_NAME} ];then
		! [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf ] \
			&& mkdir ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf
		echo -en "\n\e[1mBacking up configuration files\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/${SERVICE_NAME}/* ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf
		exit_response
	fi

	if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ];then
		! [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl ] \
			&& mkdir ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl
		echo -en "\n\e[1mBacking up SSL certificate\e[0m"
		sleep 0.2
		[[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] \
			&& mkdir -p \
				${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/live \
				${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/archive \
				${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/renewal \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]} ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/archive \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/live \
			&& cp -r "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl/letsencrypt/renewal
		cp -r "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl
		exit_response
	fi

	if [ -f "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf ];then
		! [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/nginx ] \
			&& mkdir -p ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/nginx
		echo -en "\n\e[1mBacking up nginx configuration\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}* ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/nginx
		exit_response
	fi

	if [ -f "${ENV_DIR}"/${SERVICE_NAME}.env ];then
		echo -en "\n\e[1mBacking up environemt file(s)\e[0m"
		sleep 0.2
		[[ -f "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ]] \
			&& cp "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}
		cp "${ENV_DIR}"/${SERVICE_NAME}.env ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}
		exit_response
	else
		echo -e "\n\e[3mCould not find environment file(s) for ${SERVICE_NAME}.\e[0m"
	fi
}

restore() {
echo ${FUNCNAME[@]}
	restoring=1
	## Collect the backups in the array $backups
	backups=( ${BACKUP_DIR}/${SERVICE_NAME}/* )
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
	if [[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
		&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]];then
		echo ""
		echo -e "\e[4mPlease choose a backup\e[0m"

		## Show the menu. This will list all backups and the string "back to previous menu"
		select backup in "${backups[@]}" "Back to previous menu"
		do
		    case $backup in
		    ## If the choice is one of the backups (if it matches $string)
		    $string)
				! [[ -f ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env ]] \
					&& echo -e "\n\e[3mCould not find ${SERVICE_NAME}.env in ${backup}\e[0m" \
					&& return
				# destroy current service if found
				if [[ $(docker ps -q -a --filter name=^/"${SERVICE_NAME}-service-dockerbunker"$) ]];then
					echo -e "\n\e[3m\xe2\x86\x92 Destroying ${SERVICE_NAME}\e[0m"
					destroy_service
				fi

				source ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env

				! [[ $(docker ps -q --filter name=^/nginx-dockerbunker$) ]] && setup_nginx
				echo -e "\n\e[3m\xe2\x86\x92 Restoring ${SERVICE_NAME}\e[0m"
				for volume in ${!volumes[@]};do
					[[ $(docker volume ls --filter name=^${volume}$) ]] \
						&& docker volume create $volume >/dev/null
					docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BACKUP_DIR}/${SERVICE_NAME}/${backup}:/backup debian:jessie tar xvfz /backup/${volume}.tar.gz 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
					echo -en "\n\e[1mDecompressing $volume\e[0m"
					exit_response
				done
				sleep 0.2

				if [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/conf ];then
					! [ -d "${CONF_DIR}"/${SERVICE_NAME} ] \
						&& mkdir "${CONF_DIR}"/${SERVICE_NAME}
					echo -en "\n\e[1mRestoring configuration files\e[0m"
					sleep 0.2
					cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/conf/* "${CONF_DIR}"/${SERVICE_NAME}
					exit_response
				fi

				if [ -f ${BACKUP_DIR}/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}.conf ];then
					! [[ -d "${CONF_DIR}"/nginx/conf.inactive.d ]] \
						&& mkdir "${CONF_DIR}"/nginx/conf.inactive.d
					echo -en "\n\e[1mRestoring nginx configuration\e[0m"
					cp -r ${BACKUP_DIR}/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}* "${CONF_DIR}"/nginx/conf.inactive.d
					exit_response
				fi
				sleep 0.2


				if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl ];then
					! [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ] \
						&& mkdir -p "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}
					echo -en "\n\e[1mRestoring SSL certificate\e[0m"
					sleep 0.2
					[[ -d ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] \
						&& mkdir -p \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/live \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/archive \
							"${CONF_DIR}"/nginx/ssl/letsencrypt/renewal \
						&& cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl/letsencrypt/archive \
						&& cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl/letsencrypt/live \
						&& cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal
					cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl/${SERVICE_DOMAIN[0]} "${CONF_DIR}"/nginx/ssl
					exit_response
				fi

				if [ -f ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env ];then
					echo -en "\n\e[1mRestoring environemt file(s)\e[0m"
					sleep 0.2
					[[ -f ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_SPECIFIC_MX}mx.env ]] \
						&& cp ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_SPECIFIC_MX}mx.env "${ENV_DIR}"
					cp ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env "${ENV_DIR}"
					exit_response
				fi
				create_networks
				docker_run_all
				activate_nginx_conf
				post_setup_routine
				exit 0
		        ;;

		    "Back to previous menu")
				"${SERVICES_DIR}"/${SERVICE_NAME}/init.sh
				;;
		    *)
		        backup=""
		        echo "Please choose a number from 1 to $((${#backups[@]}+1))";;
		    esac
		done
	else
		echo -e "\n\e[1mNo ${SERVICE_NAME} backup found\e[0m"
		echo -e "\n\e[3m\xe2\x86\x92 Checking service status"
		exec "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh
	fi
}
