
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="chaosbunker/json-server" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/json-server" )
declare -a networks=( )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mjson-server Settings\e[0m"

	[[ ! -d "${CONF_DIR}"/jsonserver ]] && \
		mkdir -p "${CONF_DIR}"/jsonserver
	[[ ! -f "${CONF_DIR}"/jsonserver/db.json ]] && \
		cp ${SERVICES_DIR}/${SERVICE_NAME}/db.json "${CONF_DIR}"/jsonserver/db.json

	set_domain

	prompt_confirm "Restrict GET requests?"

	if [ $? == 0 ]; then
		read -p "Header [key]: " -ei "X-Authorize" GET_REQ_HEADER_KEY
		read -p "Header [value]: " -ei "I Like Turtles" GET_REQ_HEADER_VALUE
	fi

	prompt_confirm "Restrict all other request methods with secondary header?"

	if [ $? == 0 ]; then
		read -p "Header [key]: " -ei "X-Modify" MODIFY_REQ_HEADER_KEY
		read -p "Header [value]: " -ei "I Really Like Turtles" MODIFY_REQ_HEADER_VALUE
	fi

	prompt_confirm "Set database id property? [default: id]"

	if [ $? == 0 ]; then
		read -p ": " DB_ID_PROPERTY
		ID=${ID}" --id ${DB_ID_PROPERTY}"
	fi

	prompt_confirm "Set custom routes?"

	if [ $? == 0 ]; then
		cp "${SERVICES_DIR}"/${SERVICE_NAME}/routes.json "${CONF_DIR}"/${SERVICE_NAME}

		echo -e "\nYou can modify your routes.json in ${CONF_DIR}/${SERVICE_NAME}/\n"
	fi

	SUBSTITUTE=( "\${MODIFY_REQ_HEADER_KEY}" "\${MODIFY_REQ_HEADER_VALUE}" "\${GET_REQ_HEADER_KEY}" "\${GET_REQ_HEADER_VALUE}" )

	[[ -f "${CONF_DIR}"/jsonserver/auth.js ]] \
		&& rm "${SERVICES_DIR}"/${SERVICE_NAME}/jsonserver/auth.js

	cp "${SERVICES_DIR}"/${SERVICE_NAME}/auth.js.tmpl "${SERVICES_DIR}"/${SERVICE_NAME}/auth.js

	for variable in "${SUBSTITUTE[@]}";do
		subst="\\${variable}"
		variable=`eval echo "$variable"`
		sed -i "s@${subst}@${variable}@g;" \
		"${SERVICES_DIR}"/${SERVICE_NAME}/auth.js
	done

	[[ -f "${SERVICES_DIR}"/${SERVICE_NAME}/auth.js ]] \
		&& mv "${SERVICES_DIR}"/${SERVICE_NAME}/auth.js "${CONF_DIR}"/${SERVICE_NAME}

	prompt_confirm "Remove default index.html?"

	if [ $? == 0 ]; then
		mkdir -p ${CONF_DIR}/jsonserver/public
		cp "${SERVICES_DIR}"/${SERVICE_NAME}/index.html "${CONF_DIR}"/${SERVICE_NAME}/public
		echo -e "\nPlace your index.html in ${CONF_DIR}/${SERVICE_NAME}/\n"
	fi

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	ID="${ID}"
	GET_REQ_HEADER_KEY="${GET_REQ_HEADER_KEY}"
	GET_REQ_HEADER_VALUE="${GET_REQ_HEADER_VALUE}"
	MODIFY_REQ_HEADER_KEY="${MODIFY_REQ_HEADER_KEY}"
	MODIFY_REQ_HEADER_VALUE="${MODIFY_REQ_HEADER_VALUE}"

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine

	echo -e "\njson-server can be reached at https://${SERVICE_DOMAIN}/v1"
}
