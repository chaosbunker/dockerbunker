remove_ssl_certificate() {
	if [[ ${SERVICE_DOMAIN[0]} ]];then
		[[ -d "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} ]] \
			&& echo -en "\n\e[1m$PRINT_REMOVE_SSL_CERTIFICATE\e[0m" \
			&& rm -r "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]} \
			&& exit_response
		[[ -f "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf ]] \
			&& rm "${CONF_DIR}"/nginx/ssl/letsencrypt/renewal/${SERVICE_DOMAIN[0]}.conf
		[[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]} ]] \
			&& rm -r "${CONF_DIR}"/nginx/ssl/letsencrypt/archive/${SERVICE_DOMAIN[0]}
		[[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] \
			&& rm -r "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]}
	fi
}

get_le_cert() {
	if ! [[ $1 == "renew" ]];then
		echo -e "\n\e[3m\xe2\x86\x92 $PRINT_OPTAIN_LS_CERT\e[0m"
		[[ -z ${LE_EMAIL} ]] && get_le_email
		if [[ ${STATIC} ]];then
			sed -i "s/SSL_CHOICE=.*/SSL_CHOICE=le/" "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
			sed -i "s/LE_EMAIL=.*/LE_EMAIL="${LE_EMAIL}"/" "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
		else
			sed -i "s/SSL_CHOICE=.*/SSL_CHOICE=le/" "${SERVICE_ENV}"
			sed -i "s/LE_EMAIL=.*/LE_EMAIL="${LE_EMAIL}"/" "${SERVICE_ENV}"
		fi
		elementInArray "${SERVICE_NAME}" "${STOPPED_SERVICES[@]}" \
			&& "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh start_containers
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
		echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RENEW_LE_CERT\e[0m"
		export prevent_nginx_restart=1
		bash "${SERVICES_DIR}"/${SERVICE_NAME}/init.sh letsencrypt issue
	fi
}

add_ssl_menuentry() {
	if [[ $SSL_CHOICE == "le" ]] && [[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]];then
		# in this case le cert has been obtained previously and everything is as expected
		insert $1 "$PRINT_RENEW_LE_CERT" $2
	elif ! [[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live/${SERVICE_DOMAIN[0]} ]] && [[ -L "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
		# in this case neither a self-signed nor a le cert could be found. nginx container will refuse to restart until it can find a certificate in /etc/nginx/ssl/${SERVICE_DOMAIN} - so offer to put one there either via LE or generate new self-signed
		insert $1 "$PRINT_GENERATE_SS_CERT" $2
		insert $1 "$PRINT_OPTAIN_LS_CERT" $2
	elif [[ -f "${CONF_DIR}"/nginx/ssl/${SERVICE_DOMAIN[0]}/cert.pem ]];then
		# in this case only a self-signed cert is found and a previous cert for the domain might be present in the le directories (if so it will be used and linked to)
		insert $1 "$PRINT_OPTAIN_LS_CERT" $2
	else
		# not sure when this should be the case, but if it does happen, bot options are available
		insert $1 "$PRINT_GENERATE_SS_CERT" $2
		insert $1 "$PRINT_OPTAIN_LS_CERT" $2
	fi
}
