#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="json-server"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -cd '[:alnum:]')"
PROMPT_SSL=1
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="clue/json-server" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/data" )
declare -a networks=( )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mjson-server Settings\e[0m"

	[[ ! -d "${CONF_DIR}"/jsonserver ]] && \
		mkdir -p "${CONF_DIR}"/jsonserver
	[[ ! -f "${CONF_DIR}"/jsonserver/db.json ]] \
		&& echo -e "\nCannot find db.json in \e[3mdata/conf/jsonserver/db.json\e[0m\n" \
		&& exit 1

	set_domain
	
	prompt_confirm "Set Authentication Request Header?"

	if [ $? == 0 ]; then
		MIDDLEWARE="--middlewares auth.js"
		read -p "Authorization Request Header [key]: " -ei "X-Authorize" AUTH_REQ_HEADER_KEY
		read -p "Authorization Request Header [value]: " -ei "I Like Turtles" AUTH_REQ_HEADER_VALUE
	fi

	SUBSTITUTE=( "\${AUTH_REQ_HEADER_KEY}" "\${AUTH_REQ_HEADER_VALUE}" )
	
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
		&& mv "${SERVICES_DIR}"/${SERVICE_NAME}/auth.js "${CONF_DIR}"/jsonserver
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	MIDDLEWARE="${MIDDLEWARE}"
	AUTH_REQ_HEADER_KEY="${AUTH_REQ_HEADER_KEY}"
	AUTH_REQ_HEADER_VALUE="${AUTH_REQ_HEADER_VALUE}"

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	basic_nginx
	
	docker_run_all

	post_setup_routine
	
	echo -e "\njson-server can be reached at https://${SERVICE_DOMAIN}/v1"
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi
