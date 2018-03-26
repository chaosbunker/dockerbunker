#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Static HTML Site"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1
STATIC=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

[[ $1 == "letsencrypt" && $2 == "issue" && $3 ]] \
	&& [[ -f "${ENV_DIR}"/static/${3}.env ]] && source "${ENV_DIR}"/static/${3}.env \
	&& letsencrypt issue "static"

[[ -z $1 ]] && options_menu

configure() {
	echo -e "# \e[4mSite Settings\e[0m"

	set_domain

	[[ -f "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env ]] && echo "Site already exists. Exiting." && exit 0
	
	STATIC_HOME="${BASE_DIR}/data/web/${SERVICE_DOMAIN[0]}"

	! [[ -d "${ENV_DIR}"/static ]] && mkdir "${ENV_DIR}"/static

	cat <<-EOF >> "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env
	#STATIC
	## ------------------------------

	STATIC=${STATIC}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	STATIC_HOME="${STATIC_HOME}"
	SERVICE_DOMAIN[0]=${SERVICE_DOMAIN[0]}

	## ------------------------------
	#/STATIC

	EOF

	source "${ENV_DIR}"/static/${SERVICE_DOMAIN[0]}.env

	if ! [[ -d "${STATIC_HOME}" ]];then
		mkdir -p "${STATIC_HOME}"
		echo "Welcome to my cool website." > "${STATIC_HOME}"/index.html
	else
		echo -en "Using existing HTML directory[data/web/${SERVICE_DOMAIN[0]}]"
		exit_response
	fi

	post_configure_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	[[ ! $(docker ps -q --filter name=^/${NGINX_CONTAINER}$) ]] \
		&& setup_nginx \
		|| restart_nginx

	if [[ $SSL_CHOICE == "le" ]];then
		letsencrypt issue "static"
	fi
}

[[ -z $3 ]] && $1