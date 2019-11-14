# All functions used during setup of a service

docker_pull() {
	for image in ${IMAGES[@]};do
		[[ "$image" != "dockerbunker/${SERVICE_NAME}" ]] \
			&& echo -e "\n\e[1mPulling $image\e[0m" \
			&& docker pull $image
	done
}

docker_run() {
	$1
}

docker_run_all() {
	echo -e "\n\e[1mStarting up containers\e[0m"
	for container in "${containers[@]}";do
		! [[ $(docker ps -q --filter name="^/${container}$") ]] \
			&& echo -en "- $container" \
			&& ${container//-/_} \
			&& exit_response \
			|| echo "- $container (already running)"
	done
	connect_containers_to_network
}

get_current_images_sha256() {
	# get current images' sha256
	if [[ -z ${CURRENT_IMAGES_SHA256[@]} ]];then
		collectImageNamesAndCorrespondingSha256
		declare -A CURRENT_IMAGES_SHA256
		for key in "${!IMAGES_AND_SHA256[@]}";do
			CURRENT_IMAGES_SHA256[$key]+=${IMAGES_AND_SHA256[$key]}
		done
	fi
	declare -p CURRENT_IMAGES_SHA256 >> "${BASE_DIR}"/.image_shas.tmp
	unset IMAGES_AND_SHA256
}

pull_and_compare() {
	[[ -f "${BASE_DIR}"/.image_shas.tmp ]] \
		&& rm "${BASE_DIR}"/.image_shas.tmp

	get_current_images_sha256

	if [[ ${DOCKER_COMPOSE} ]];then
		pushd "${SERVICE_HOME}" >/dev/null
		echo ""
		echo -e "\e[1mPulling new images\e[0m"
		echo ""
		docker-compose pull
	else
		docker_pull
	fi

	if [[ -f "${BASE_DIR}"/.image_shas.tmp ]];then
		source "${BASE_DIR}"/.image_shas.tmp
	else
		echo -e "\n\e[31mCould not find digests of current images.\nExiting.\e[0m"
		exit 1
	fi
	# compare sha256 and delete old unused images
	collectImageNamesAndCorrespondingSha256
	declare -A NEW_IMAGES_SHA256
	for key in "${!IMAGES_AND_SHA256[@]}";do
		NEW_IMAGES_SHA256[$key]+=${IMAGES_AND_SHA256[$key]}
	done

	for key in "${!CURRENT_IMAGES_SHA256[@]}";do
		if [[ ${CURRENT_IMAGES_SHA256[$key]} != ${NEW_IMAGES_SHA256[$key]} ]];then
			old_images_to_delete+=( ${CURRENT_IMAGES_SHA256[$key]} )
		else
			unchanged_images_to_keep+=( ${CURRENT_IMAGES_SHA256[$key]} )
		fi
	done

	if [[ ${DOCKER_COMPOSE} ]] \
	&& [[ ${old_images_to_delete[0]} ]];then
		pushd "${SERVICE_HOME}" >/dev/null
		echo -e "\n\e[1mTaking down ${PROPER_NAME}\e[0m"
		docker-compose down
		echo -e "\n\e[1mBringing ${PROPER_NAME} back up\e[0m"
		docker-compose up -d
		popd >/dev/null
	fi

	[[ ${old_images_to_delete[0]} ]] \
		&& declare -p old_images_to_delete >> "${BASE_DIR}"/.image_shas.tmp
	[[ ${unchanged_images_to_keep[0]} ]] \
		&& declare -p unchanged_images_to_keep >> "${BASE_DIR}"/.image_shas.tmp

	for container in "${containers[@]}";do
		! [[ $(docker ps -q --filter name="^/${container}$") ]] \
			&& missing_containers+=( $container )
	done

	[[ -z ${old_images_to_delete[0]} ]] && [[ -z ${missing_containers[0]} ]] \
		&& echo -e "\n\e[1mImage(s) did not change.\e[0m" \
		&& rm "${BASE_DIR}"/.image_shas.tmp \
		&& exit 0
}

delete_old_images() {
	if [[ -f "${BASE_DIR}"/.image_shas.tmp ]];then
		source "${BASE_DIR}"/.image_shas.tmp
	else
		echo -en "\n\e[31mCould not find digests of current images.\nExiting.\e[0m"
		return
	fi

	[[ -z ${old_images_to_delete[0]} ]] \
		&& return

	prompt_confirm "Delete all old images?"
	if [[ $? == 0 ]];then
		echo ""
		for image in "${old_images_to_delete[@]}";do
				echo -en "\e[1m[DELETING]\e[0m $image"
				docker rmi $image >/dev/null
				exit_response
		done
		for image in ${unchanged_images_to_keep[@]};do
			echo -en "\e[1m[KEEPING]\e[0m $image (did not change)"
		done
		echo ""
	fi
	rm "${BASE_DIR}"/.image_shas.tmp
}

setup_nginx() {
	[[ ! $(docker ps -q --filter name=^/${NGINX_CONTAINER}$) ]] && bash "${SERVER_DIR}/nginx/init.sh" setup
}

# Build image if necessary, set up nginx container if necessary, create or use existing volumes, create networks if necessary, pull images if necessary

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

create_volumes() {
	if [[ ${volumes[@]} && ! ${DOCKER_COMPOSE} ]];then
		echo -e "\n\e[1mCreating volumes\e[0m"
		for volume in "${!volumes[@]}";do
			[[ ! $(docker volume ls -q --filter name=^${volume}$) ]] \
				&& echo -en "- $volume" \
				&& docker volume create $volume >/dev/null \
				&& exit_response \
				|| echo "- $volume (already exists)"
		done
	fi
}

create_networks() {
	for network in "${networks[@]}";do
		[[ $(docker network ls -q --filter name=^${network}$) ]] \
			&& docker network rm $network >/dev/null
		[[ ! $(docker network ls -q --filter name=^${network}$) ]] \
			&& docker network create $network >/dev/null
	done
}

generate_certificate() {
	[[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]] && rm "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem
	[[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem ]] && rm "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem
	echo -en "\n\e[1mGenerating self-signed certificate for ${SERVICE_DOMAIN[0]}\e[0m"
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem -out "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem -subj "/C=XY/ST=hidden/L=nowhere/O=${PROPER_NAME}/OU=IT Department/CN=${SERVICE_DOMAIN[0]}" >/dev/null 2>&1
	exit_response
}
# this generates the nginx configuration for the service that is being set up and puts it into data/services/ngix/conf.d
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
			cp "${SERVICES_DIR}"/${SERVICE_NAME}/nginx/service.conf "${SERVICES_DIR}"/${SERVICE_NAME}/nginx/${SERVICE_DOMAIN[0]}.conf
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


wait_for_db() {
	if ! docker exec ${FUNCNAME[1]//_/-} mysqladmin ping -h"127.0.0.1" --silent;then
		while ! docker exec ${FUNCNAME[1]//_/-} mysqladmin ping -h"127.0.0.1" --silent;do
			sleep 1
		done
	fi
}

post_setup_routine() {

	remove_from_CONFIGURED_SERVICES

	! elementInArray "${PROPER_NAME}" "${INSTALLED_SERVICES[@]}" && INSTALLED_SERVICES+=( "${PROPER_NAME}" )
	for container in ${add_to_network[@]};do
		! elementInArray "${container}" "${CONTAINERS_IN_DOCKERBUNKER_NETWORK[@]}" && CONTAINERS_IN_DOCKERBUNKER_NETWORK+=( "${container}" )
	done

	[[ -f "${ENV_DIR}/dockerbunker.env" ]] && ( sed -i '/CONFIGURED_SERVICES/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/WEB_SERVICES/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/CONTAINERS_IN_DOCKERBUNKER_NETWORK/d' "${ENV_DIR}/dockerbunker.env"; sed -i '/INSTALLED_SERVICES/d' "${ENV_DIR}/dockerbunker.env" )
	declare -p CONFIGURED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p INSTALLED_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p WEB_SERVICES >> "${ENV_DIR}/dockerbunker.env"
	declare -p CONTAINERS_IN_DOCKERBUNKER_NETWORK >> "${ENV_DIR}/dockerbunker.env" 2>/dev/null

	if elementInArray "${PROPER_NAME}" "${STOPPED_SERVICES[@]}";then
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

# This function issues a Let's Encrypt certificate if the choice has been made earlier and finally updates the arrays in dockerbunker.env so dockerbunker knows that the service now is installed
letsencrypt() {
	echo ""
	add_domains() {
		prompt_confirm "Include other domains in certificate beside ${SERVICE_DOMAIN[*]}?"
		if [[ $? == 0 ]];then
			unset fqdn_is_valid
			unset domains
			while [[ -z $fqdn_is_valid ]];do
				if [[ $invalid ]];then
					echo -e "\nPlease enter a valid domain!\n"
				fi
				unset invalid
				read -p "Enter domains, separated by spaces: ${SERVICE_DOMAIN[*]} " -ei "" domains
				if [[ -z $domains ]];then
					domains=( ${SERVICE_DOMAIN[*]} )
					break
				else
					domains=( ${SERVICE_DOMAIN[*]} $domains )
					for i in "${domains[@]}";do
						# don't check if main domain is valid, otherwise it will complain that the domain already exists because an nginx configuration is already in place
						[[ $i != ${SERVICE_DOMAIN[0]} ]] && validate_fqdn $i
					done
					invalid=1
				fi
				invalid=1
			done

			if [[ ${STATIC} ]];then
				[[ ${domains[1]} ]] && sed -i "s/server_name.*/server_name ${domains[*]}\;/" "data/conf/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf" && sed -i "s/^SERVICE\_DOMAIN.*/SERVICE\_DOMAIN\=\(\ ${domains[*]}\ \)/" "data/env/static/${SERVICE_DOMAIN[0]}.env"
			else
				[[ ${domains[1]} ]] && sed -i "s/server_name.*/server_name ${domains[*]}\;/" "data/conf/nginx/conf.d/${SERVICE_DOMAIN[0]}.conf" && sed -i "s/^SERVICE\_DOMAIN.*/SERVICE\_DOMAIN\=\(\ ${domains[*]}\ \)/" "data/env/${SERVICE_NAME}.env"
			fi
			expand="--expand "
		else
			domains=( ${SERVICE_DOMAIN[@]} )
		fi
	}
	issue() {
		[[ -z $1 ]] && ! [[ $(docker ps -q --filter name=^/${SERVICE_NAME}-service-dockerbunker$) ]] && echo "${PROPER_NAME} container not running. Exiting." && exit 1
			for value in $*;do
				[[ ( $value == "letsencrypt" || $value == "issue" || $value == "static" ) ]] || domains+=( "$value" )
			done
			for domain in ${domains[@]};do
				[[ ${domain} != ${SERVICE_DOMAIN[0]} ]] && validate_fqdn $domain || fqdn_is_valid=1
				if [[ $fqdn_is_valid ]];then
					[[ ! "${le_domains[@]}" =~ $domain ]] && le_domains+=( "-d $domain" )
				else
					exit
				fi
			done
		[[ ( "${domains[@]}" =~ ${SERVICE_DOMAIN[0]} && ! "${domains[0]}" =~ "${SERVICE_DOMAIN[0]}" ) ]] && ( echo "Please list ${SERVICE_DOMAIN[0]} first.";exit 1 )
			[[ "${domains[@]}" =~ ${SERVICE_DOMAIN[0]} ]] || ( echo -e "Please include your chosen ${PROPER_NAME} domain ${SERVICE_DOMAIN[0]}";exit 1 )
			[[ ! -d "${CONF_DIR}"/nginx/ssl/letsencrypt ]] && mkdir "${CONF_DIR}"/nginx/ssl/letsencrypt
		[[ ( "${domains[@]}" =~ "${SERVICE_DOMAIN[0]}" && "${domains[0]}" =~ "${SERVICE_DOMAIN[0]}" ) ]] \
			&& echo "" \
			&& docker run --rm -it --name=certbot \
				--network ${NETWORK} \
				-v "${CONF_DIR}"/nginx/ssl/letsencrypt:/etc/letsencrypt \
				-v "${BASE_DIR}"/data/web:/var/www/html:rw \
				certbot/certbot \
				certonly --noninteractive \
				--webroot -w /var/www/html \
				${le_domains[@]} \
				--email ${LE_EMAIL} ${expand}\
				--agree-tos
		if [[ $? == 0 ]];then
			if ! [[ -L "data/conf/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem" ]];then
				echo -en "\n\e[1mBacking up self-signed certificate\e[0m"
				mv "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.{pem,pem.backup} && \
					mv "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.{pem,pem.backup} && exit_response || exit_response
				echo -en "\n\e[1mSymlinking letsencrypt certificate\e[0m"
				ln -sf "/etc/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]}/fullchain.pem" "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem && \
					ln -sf "/etc/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]}/privkey.pem" "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem && exit_response || exit_response
			fi
			restart_nginx
		fi
	}

	renew() {
		docker run --rm -it --name=certbot \
		--network ${NETWORK} \
		-v "${CONF_DIR}"/nginx/ssl/letsencrypt:/etc/letsencrypt \
		-v "${BASE_DIR}"/data/web:/var/www/html:rw \
		certbot/certbot \
		renew

		restart_nginx
	}

	echo -e "\e[1mObtain certificate from Let's Encrypt\e[0m"
	if [[ ( "$1" == "issue" ) ]] || [[ ( "$1" == "letsencrypt" && "$2" == "issue" ) ]];then
			add_domains
			issue ${domains[@]}
	elif [[ ( "$1" == "letsencrypt" && "$2" == "renew" ) ]] || [[ "$1" == "renew" ]];then
		renew
	else
		echo "Usage: issue example.org www.example.org | renew"
		exit 0
	fi

}
