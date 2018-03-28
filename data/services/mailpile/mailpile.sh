#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Mailpile"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/mailpile-data" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="dockerbunker/dillinger" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}]="${DOCKERFILES}/${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	! [[ -d "${BASE_DIR}"/data/Dockerfiles/mailpile ]] \
	&& echo -n "Cloning Mailpile repository into ${BASE_DIR}/data/Dockerfiles/mailpile" \
	&& git submodule add https://github.com/mailpile/Mailpile.git "${BASE_DIR}"/data/Dockerfiles/mailpile >/dev/null \
	&& exit_response
	
	
	echo -e "# \e[4mMailpile Settings\e[0m"
	
	set_domain
	
	unset COMMAND
	prompt_confirm "Install in subdirectory?"
	if [[ $? == 0 ]];then
		if [ -z "$SUBDIR" ]; then
			read -p "Enter subdirectory: /" -ei "mailpile" SUBDIR
		else
			read -p "Enter subdirectory: /" -ei "${SUBDIR}" SUBDIR
		fi
		LOCATION="^~ /${SUBDIR}"
		PORT="12345"
		COMMAND="./mp --www=0.0.0.0:${PORT}/${SUBDIR}"
	else
		PORT="33411"
		LOCATION="/"
	fi
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	PROMPT_SSL=${PROMPT_SSL}
	SUBDIR="${SUBDIR}"
	PORT=${PORT}
	LOCATION="${LOCATION}"
	COMMAND="${COMMAND}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL="${LE_EMAIL}"
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${PORT}" "\${LOCATION}" )

	post_configure_routine
}
setup() {
	# add volume section to dockerfile
	[[ ! $(grep "VOLUME" "${BASE_DIR}/data/Dockerfiles/${SERVICE_NAME}/Dockerfile") ]] && sed -i "/EXPOSE/a VOLUME \/mailpile-data\/.local\/share\/Mailpile\nVOLUME \/mailpile-data\/.gnupg/" "${DOCKERFILES}"/${SERVICE_NAME}/Dockerfile

	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${PORT}" "\${LOCATION}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi