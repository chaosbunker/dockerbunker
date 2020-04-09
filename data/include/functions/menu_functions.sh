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
	exitmenu=$(printf "\e[1;4;33m$PRINT_EXIT\e[0m")
	returntopreviousmenu=$(printf "\e[1;4;33m$PRINT_RETURN_TO_PREVIOUSE_MENU\e[0m")

	container_check=1

	# if service is marked as installed, make sure all containers exist and offer to run them if necessary
	if elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}";then
		for container in "${containers[@]}";do
			RUNNING=$(docker ps -a --format '{{.Status}}' --filter name=^/${container}$)
			echo "$PRINT_STATUS:  $RUNNING"
			if [[ -z ${RUNNING} ]];then
				echo -e "\n\e[3m$container $PRINT_CONTAINER_MISSING\e[0m\n"
				missingContainers=( "$container" )
				prompt_confirm "$PRINT_RESTORE $container?"
				if [[ $? == 0 ]];then
					restore_container
				fi
			fi
			RUNNING=$(docker ps -a --format '{{.Status}}' --filter name=^/${container}$)
			[[ ${RUNNING} ]] && missingContainers=( "${missingContainers[@]}/$container" )
		done
	fi
	if [[ $RUNNING ]];then
		menu=( "$PRINT_MENU_RECONFIGURE_SERVICE" "$PRINT_MENU_REINSTALL_SERVICE" "$PRINT_MENU_BACKUP_SERVICE" "$PRINT_MENU_UPGRADE_IMAGE" "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "${returntopreviousmenu}" "$exitmenu" )
		add_ssl_menuentry menu 2
		if elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}";then
			insert menu "$PRINT_MENU_START_CONTAINERS" 3
		else
			insert menu "$PRINT_MENU_RESTART_CONTAINERS" 3
			insert menu "$PRINT_MENU_STOP_CONTAINERS" 4
		fi
		[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
		&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
		&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 6
	elif [[ ${missingContainers[@]} ]];then
		echo -e "\n\n\e[3m\xe2\x86\x92 \e[3m$PRINT_CONTAINERS_ARE_MISSING\e[0m"
		for container in "${missingContainers[@]}";do echo -e "\n    - $container";done
		menu=( "$PRINT_MENU_RESTORE_MISSING_CONTAINER" "$PRINT_MENU_RECONFIGURE_SERVICE" "$PRINT_MENU_START_CONTAINERS" "$PRINT_MENU_STOP_CONTAINERS" "$PRINT_MENU_REINSTALL_SERVICE" "$PRINT_MENU_BACKUP_SERVICE" "$PRINT_MENU_RESTORE_SERVICE" "$PRINT_MENU_UPGRADE_IMAGE" "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "$exitmenu" )
	elif [[ $RUNNING = false ]];then
		menu=( "$PRINT_MENU_RECONFIGURE_SERVICE" "$PRINT_MENU_REINSTALL_SERVICE" "$PRINT_MENU_BACKUP_SERVICE" "$PRINT_MENU_START_CONTAINERS" "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "$exitmenu" )
		add_ssl_menuentry menu 2
		[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
		&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
		&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 3
	else
		if ! elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			[[ ${STATIC} \
			&& $(ls -A "${ENV_DIR}"/static) ]] \
			&& [[ "${STATIC_SERVICES[@]}" =~ "${SERVICE_NAME}" ]] \
			&& menu=( "$PRINT_MENU_CONFIGURE_SITES" "$PRINT_MENU_MANAGE_SITES" "$exitmenu" ) \
			|| menu=( "$PRINT_MENU_CONFIGURE_SERVICE" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 1
		elif ! elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& ! elementInArray "${SERVICE_NAME}" "${INSTALLED_SERVICES[@]}";then
			menu=( "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 1
			error="Environment file found but ${SERVICE_NAME} is not marked as configured or installed. Please destroy first!"
		elif elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ ! -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			error="Service marked as configured, but configuration file is missing. Please destroy first."
			menu=( "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 1
		elif elementInArray "${SERVICE_NAME}" "${CONFIGURED_SERVICES[@]}" \
		&& [[ -f "${ENV_DIR}"/${SERVICE_NAME}.env ]];then
			menu=( "$PRINT_MENU_RECONFIGURE_SERVICE" "$PRINT_MENU_SETUP_SERVICE" "$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"" "$exitmenu" )
			[[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] \
			&& [[ $(ls -A ${BACKUP_DIR}/${SERVICE_NAME}) ]] \
			&& insert menu "$PRINT_MENU_RESTORE_SERVICE" 2
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
			"$PRINT_MENU_CONFIGURE_SITES")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_CONFIGURE ${SERVICE_NAME}\e[0m\n"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh configure
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_MENU_CONFIGURE_SERVICE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_CONFIGURE ${SERVICE_NAME}\e[0m\n"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh configure
			sleep 0.2
			break
			;;
			"$PRINT_MENU_MANAGE_SITES")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_MENU_MANAGE_SITES\e[0m"
			static_menu
			sleep 0.2
			break
			;;
			"$PRINT_MENU_RECONFIGURE_SERVICE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RECONFIGURE ${SERVICE_NAME}\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh reconfigure
			break
			;;
			"$PRINT_MENU_SETUP_SERVICE")
			# Set up nginx container if not yet present
			setup_nginx
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_SETUP ${SERVICE_NAME}\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh setup
			sleep 0.2
			break
			;;
			"$PRINT_MENU_REINSTALL_SERVICE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_REINSTALL ${SERVICE_NAME}\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh reinstall
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_MENU_RESTORE_MISSING_CONTAINER")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RESTROING_CONTAINERS\e[0m"
			for container in ${missingContainers[@]};do
				restore_container
			done
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh
			;;
			"$PRINT_MENU_UPGRADE_IMAGE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_UPGRADE ${SERVICE_NAME} images\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh upgrade
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_MENU_BACKUP_SERVICE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_MENU_BACKUP_SERVICE\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh backup
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_MENU_RESTORE_SERVICE")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_MENU_RESTORE_SERVICE\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh restore
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_GENERATE_SS_CERT")
			generate_certificate
			restart_nginx
			say_done
			sleep 0.2
			break
			;;
			"$PRINT_OPTAIN_LS_CERT")
			get_le_cert
			say_done
			sleep 0.2
			exit
			;;
			"$PRINT_RENEW_LE_CERT")
			get_le_cert renew
			say_done
			sleep 0.2
			exit
			;;
			"$PRINT_MENU_RESTART_CONTAINERS")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RESTART ${SERVICE_NAME} $PRINT_CONATIENRS\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh restart_containers
			say_done
			sleep 0.2
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh
			break
			;;
			"$PRINT_MENU_START_CONTAINERS")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_START ${SERVICE_NAME} $PRINT_CONATIENRS\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh start_containers
			say_done
			sleep 0.2
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh
			break
			;;
			"$PRINT_MENU_STOP_CONTAINERS")
			echo -e "\n\e[3m\xe2\x86\x92 Stop ${SERVICE_NAME} $PRINT_CONATIENRS\e[0m"
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh stop_containers
			say_done
			sleep 0.2
			${SERVICES_DIR}/${SERVICE_NAME}/init.sh
			break
			;;
			"$PRINT_MENU_DESTROY_SERVICE  \"${SERVICE_NAME}\"")
			echo -e "\n\e[3m\xe2\x86\x92 $PRINT_DESTROY ${SERVICE_NAME}\e[0m"
			echo ""
			echo "$PRINT_FOLLWONING_WILL_REMOVED"
			echo ""

			for container in ${containers[@]};do
				[[ $(docker ps -a --format '{{.Status}}' --filter name=^/${container}$) ]]  \
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

			prompt_confirm "$PRINT_PROMPT_CONFIRM_QUESTION" \
			&& prompt_confirm "$PRINT_PROMPT_CONFIRM_SHURE" \
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
			echo "$PRINT_INVALID_OPTION_MESSAGE"
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
	for service in "${INSTALLED_SERVICES[@]}";do
		if ! elementInArray "$service" "${STOPPED_SERVICES[@]}";then
			source "${ENV_DIR}/${service}.env"
			source "${SERVICES_DIR}"/${service}/init.sh stop_containers
		fi
	done
	stop_nginx
	export prevent_nginx_restart=1
}

destroy_all() {
	# destroy_service() is calling restart_nginx, we don't want this happening after each service is destroyed
	[[ -z ${CONF_DIR} || -z ${ENV_DIR} || -z ${SERVICES_DIR} ]] \
	&& echo "$PRINT_SOMETHING_WENT_WRONG"

	export prevent_nginx_restart=1
	export destroy_all=1

	all_services=( "${INSTALLED_SERVICES[@]}" "${CONFIGURED_SERVICES[@]}" )

	[[ $(docker ps -a --format '{{.Status}}' --filter name=^/nginx-dockerbunker$) ]] && all_services+=( "nginx" )

	if [[ ${all_services[0]} ]]; then
		printf "\n$PRINT_THE_FOLLOWING_SERVICES_WILL_BE_REMOVED"

		for i in "${all_services[@]}"; do
			if [[ "$i" == ${all_services[-1]} ]];then
				printf " \"\e[33m$i\e[0m\""
			else
				printf " \"\e[33m$i\e[0m\""
			fi
		done
		printf "\n\n"
	fi

	prompt_confirm "$PRINT_PROMPT_CONFIRM_QUESTION"

	[[ $? == 1 ]] && echo "$PRINT_EXITING" && exit 0

	for service in "${all_services[@]}"; do
		echo -e "\n\e[3m\xe2\x86\x92 $PRINT_DESTROY $service\e[0m"

		[[ -f "${SERVER_DIR}"/$service/init.sh ]] \
		&& "${SERVER_DIR}/$service"/init.sh destroy_service

		[[ -f "${SERVICES_DIR}"/$service/init.sh ]] \
		&& "${SERVICES_DIR}/$service"/init.sh destroy_service
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

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${SERVICE_NAME}" )
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
	prompt_confirm "$PRINT_PROMPT_CONFIRM_KEEP_VOLUMES" && export keep_volumes=1

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
		prompt_confirm "$PRINT_PROMPT_CONFIRM_KEEP_VOLUMES" && keep_volumes=1
	else
		echo ""
		prompt_confirm "$PRINT_ALL_VOLUMES_WILL_BE_REMOVED" || exit 0
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
	&& echo -e "\n\e[1m$PRINT_NO_EXISTING_SITE_FOUND\e[0m" \
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
	string="@("
	declare -a current_static_services
	## Add the rest of the site names to the string
	for((i=0;i<${#staticsites[@]};i++))
	do
		# show only services which match STATIC_SERVICES pattern
		# to show only correct static-service in case we habe more than once static-services (agains initial dockerbunker functionality)
		if elementInArray "${SERVICE_NAME}-${staticsites[$i]}" "${STATIC_SERVICES[@]}"; then
			[[ $i > 0 ]] && string+="|";
			string+="${staticsites[$i]}"
			current_static_services+=( "${staticsites[$i]}" )
		fi
	done
	## Close the parenthesis. $string is now @(site1|site2|...|siteN)
	string+=")"
	echo ""

	## Show the menu. This will list all Static Sites that have an active environment file
	select static in "${current_static_services[@]}" "$returntopreviousmenu"
	do
		case $static in
			$string)
			if [[ -f "${BASE_DIR}"/build/env/static/${static}.env ]];then
				source "${BASE_DIR}"/build/env/static/${static}.env
			else
				echo "$PRINT_NO_ENVORINMENT_FILE_FOUND $static. $PRINT_EXITING."
				exit 1
			fi
			echo ""
			static_choices=( "$PRINT_MENU_REMOVE_SITE" "$returntopreviousmenu" )
			add_ssl_menuentry static_choices 1
			select static_choice in "${static_choices[@]}"
			do
				case $static_choice in
					"$PRINT_MENU_REMOVE_SITE")
					echo -e "\n\e[4m$PRINT_MENU_REMOVE_SITE\e[0m"
					prompt_confirm "$PRINT_REMOVE $static" && prompt_confirm "$PRINT_PROMPT_CONFIRM_SHURE" && destroy_service
					say_done
					sleep 0.2
					break
					;;
					"$PRINT_GENERATE_SS_CERT")
					generate_certificate
					restart_nginx
					say_done
					sleep 0.2
					break
					;;
					"$PRINT_OPTAIN_LS_CERT")
					get_le_cert
					say_done
					sleep 0.2
					break
					;;
					"$PRINT_RENEW_LE_CERT")
					get_le_cert renew
					say_done
					sleep 0.2
					break
					;;
					"$returntopreviousmenu")
					static_menu
					;;
					*)
					echo "$PRINT_INVALID_OPTION_MESSAGE"
					;;
				esac
			done

			break;

			;;
			"$returntopreviousmenu")

			exec "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh options_menu

			;;
			*)

			static=""
			echo "$PRINT_PLEASE_CHOOSE_A_NUMBER $((${#current_static_services[@]}+1))"

			;;
		esac
	done
}

backup() {
	! [[ -d ${BACKUP_DIR}/${SERVICE_NAME} ]] && mkdir -p ${BACKUP_DIR}/${SERVICE_NAME}
	NOW=$(date -d "today" +"%Y%m%d_%H%M")
	mkdir -p ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}

	# compressing volumes
	echo -e "\n\e[1m$PRINT_COMPESSING_VOLUMES\e[0m"
	for volume in ${!volumes[@]};do
		docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}:/backup debian:jessie tar cvfz /backup/${volume}.tar.gz /${volumes[$volume]##*/} 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
		echo -en "- $volume"
		exit_response
	done

	if [ -d "${CONF_DIR}"/${SERVICE_NAME} ];then
		! [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf ] \
		&& mkdir ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf
		echo -en "\n\e[1m$PRINT_BACKING_UP_CONFIG_FILES\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/${SERVICE_NAME}/* ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/conf
		exit_response
	fi

	if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ];then
		! [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl ] \
		&& mkdir ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/ssl
		echo -en "\n\e[1m$PRINT_BACKING_UP_CERT\e[0m"
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
		echo -en "\n\e[1m$PRINT_BACKING_UP_NGINX_CONF\e[0m"
		sleep 0.2
		cp -r "${CONF_DIR}"/nginx/conf.d/${SERVICE_DOMAIN[0]}* ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}/nginx
		exit_response
	fi

	if [ -f "${ENV_DIR}"/${SERVICE_NAME}.env ];then
		echo -en "\n\e[1m$PRINT_BACKING_UP_ENV_FILE\e[0m"
		sleep 0.2
		[[ -f "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ]] \
		&& cp "${ENV_DIR}"/${SERVICE_SPECIFIC_MX}mx.env ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}
		cp "${ENV_DIR}"/${SERVICE_NAME}.env ${BACKUP_DIR}/${SERVICE_NAME}/${NOW}
		exit_response
	else
		echo -e "\n\e[3m$PRINT_COULD_NOT_FIND_ENV_FILE ${SERVICE_NAME}.\e[0m"
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
		echo -e "\e[4m$PRINT_COOSE_A_BACKUP\e[0m"

		## Show the menu. This will list all backups and the string "$PRINT_MENU_PRVIOUSE_MENU"
		select backup in "${backups[@]}" "$PRINT_MENU_PRVIOUSE_MENU"
		do
			case $backup in
				## If the choice is one of the backups (if it matches $string)
				$string)
				! [[ -f ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env ]] \
				&& echo -e "\n\e[3m$PRINT_COULD_NOT_FIND ${SERVICE_NAME}.env in ${backup}\e[0m" \
				&& return
				# destroy current service if found
				if [[ $(docker ps -q -a --filter name=^/"${SERVICE_NAME}-service-dockerbunker"$) ]];then
					echo -e "\n\e[3m\xe2\x86\x92 $PRINT_DESTROY ${SERVICE_NAME}\e[0m"
					destroy_service
				fi

				source ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/${SERVICE_NAME}.env

				! [[ $(docker ps -q --filter name=^/nginx-dockerbunker$) ]] && setup_nginx
				echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RESTORE ${SERVICE_NAME}\e[0m"
				for volume in ${!volumes[@]};do
					[[ $(docker volume ls --filter name=^${volume}$) ]] \
					&& docker volume create $volume >/dev/null
					docker run --rm -i -v ${volume}:/${volumes[$volume]##*/} -v ${BACKUP_DIR}/${SERVICE_NAME}/${backup}:/backup debian:jessie tar xvfz /backup/${volume}.tar.gz 2>/dev/null | cut -b1-$(tput cols) | sed -u 'i\\o033[2K' | stdbuf -o0 tr '\n' '\r';echo -e "\033[2K\c"
					echo -en "\n\e[1m$PRINT_DECOMPRESSING $volume\e[0m"
					exit_response
				done
				sleep 0.2

				if [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/conf ];then
					! [ -d "${CONF_DIR}"/${SERVICE_NAME} ] \
					&& mkdir "${CONF_DIR}"/${SERVICE_NAME}
					echo -en "\n\e[1m$PRINT_RESTORING_CONFIGURATION\e[0m"
					sleep 0.2
					cp -r ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/conf/* "${CONF_DIR}"/${SERVICE_NAME}
					exit_response
				fi

				if [ -f ${BACKUP_DIR}/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}.conf ];then
					! [[ -d "${CONF_DIR}"/nginx/conf.inactive.d ]] \
					&& mkdir "${CONF_DIR}"/nginx/conf.inactive.d
					echo -en "\n\e[1m$PRINT_RESTORING_NGINX_CONF\e[0m"
					cp -r ${BACKUP_DIR}/${SERVICE_NAME}/$backup/nginx/${SERVICE_DOMAIN}* "${CONF_DIR}"/nginx/conf.inactive.d
					exit_response
				fi
				sleep 0.2


				if [[ ${SERVICE_DOMAIN[0]} ]] && [ -d ${BACKUP_DIR}/${SERVICE_NAME}/${backup}/ssl ];then
					! [ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ] \
					&& mkdir -p "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}
					echo -en "\n\e[1m$PRINT_RESTORING_SSL_CERT\e[0m"
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
					echo -en "\n\e[1m$PRINT_RESTORING_ENV\e[0m"
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

				"$PRINT_MENU_PRVIOUSE_MENU")
				"${SERVICES_DIR}"/${SERVICE_NAME}/init.sh
				;;
				*)
				backup=""
				echo "$PRINT_PLEASE_CHOOSE_A_NUMBER $((${#backups[@]}+1))";;
			esac
		done
	else
		echo -e "\n\e[1mNo ${SERVICE_NAME} backup found\e[0m"
		echo -e "\n\e[3m\xe2\x86\x92 $PRINT_CHECKING_SERVICE_STATUS ${SERVICE_NAME}"
		exec "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh
	fi
}
