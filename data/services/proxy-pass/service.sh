
######
# service specific configuration
# you should setup your service here
######

# marker for this service as a static html app, to use special setup-functions
STATIC=1

configure() {
	echo -e "# \e[4mSite Settings\e[0m"

	set_domain
	set_IP_PORT

	[[ -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env ]] \
	&& echo "Site already exists. Exiting." && exit 0

	STATIC_HOME="$WEB_DIR/${SERVICE_DOMAIN[0]}"

	# create environment static folder
	! [[ -d "${ENV_DIR}"/static ]] && mkdir "${ENV_DIR}"/static

	cat <<-EOF >> "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
	#STATIC
	## ------------------------------
	STATIC=${STATIC}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	STATIC_HOME="${STATIC_HOME}"
	SERVICE_DOMAIN[0]=${SERVICE_DOMAIN[0]}
	SERVICE_SERVER_CONFIG=${SERVICE_SERVER_CONFIG}
	SERVICE_IP=${SERVICE_IP}
	SERVICE_PORT=${SERVICE_PORT}
	## ------------------------------
	#/STATIC
	EOF

	source "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env

	post_configure_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${SERVICE_PORT}" "\${SERVICE_IP}" )
	set_nginx_config
	basic_nginx

	[[ ! $(docker ps -q --filter name=^/${NGINX_CONTAINER}$) ]] \
	&& setup_nginx \
	|| restart_nginx

	if [[ $SSL_CHOICE == "le" ]];then
		letsencrypt issue "static"
	fi
}
