#######
# All functions to setup certificate
#
# function: generate_certificate
# function: letsencrypt
# function: configure_ssl
#######

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

generate_certificate() {
	[[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]] && rm "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem
	[[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem ]] && rm "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem
	echo -en "\n\e[1mGenerating self-signed certificate for ${SERVICE_DOMAIN[0]}\e[0m"
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/key.pem -out "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem -subj "/C=XY/ST=hidden/L=nowhere/O=${SERVICE_NAME}/OU=IT Department/CN=${SERVICE_DOMAIN[0]}" >/dev/null 2>&1
	exit_response
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
		[[ -z $1 ]] && ! [[ $(docker ps -q --filter name=^/${SERVICE_NAME}-service-dockerbunker$) ]] && echo "${SERVICE_NAME} container not running. Exiting." && exit 1
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
			[[ "${domains[@]}" =~ ${SERVICE_DOMAIN[0]} ]] || ( echo -e "Please include your chosen ${SERVICE_NAME} domain ${SERVICE_DOMAIN[0]}";exit 1 )
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
