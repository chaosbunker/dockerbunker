
######
# service specific configuration
# you should setup your service here
######

# marker for this service as a static html app, to use special setup-functions
STATIC=1

configure() {
	echo -e "# \e[4mSite Settings\e[0m"

	set_domain

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
	## ------------------------------
	#/STATIC
	EOF

	source "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env

	# create dummy index.html
	if ! [[ -d "${STATIC_HOME}" ]];then
		mkdir -p "${STATIC_HOME}"

		# download and unzip keeweb package
		wget https://github.com/keeweb/keeweb/archive/gh-pages.zip -O $STATIC_HOME/keeweb.zip && \
		unzip $STATIC_HOME/keeweb.zip -d $STATIC_HOME && \
		rm $STATIC_HOME/keeweb.zip && \
		mv $STATIC_HOME/keeweb-gh-pages/* $STATIC_HOME && \
		rm -rf $STATIC_HOME/keeweb-gh-pages

	else
		echo -en "Using existing HTML directory [$STATIC_HOME]"
		exit_response
	fi

	post_configure_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	set_nginx_config
	basic_nginx

	[[ ! $(docker ps -q --filter name=^/${NGINX_CONTAINER}$) ]] \
	&& setup_nginx \
	|| restart_nginx

	if [[ $SSL_CHOICE == "le" ]];then
		letsencrypt issue "static"
	fi
}
