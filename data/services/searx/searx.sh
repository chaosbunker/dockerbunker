#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Searx"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="dockerbunker/${SERVICE_NAME}" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}]="${DOCKERFILES}/${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

upgrade() {
	get_current_images_sha256

	sed -i "s/default_theme\ :.*/default_theme\ :\ ${THEME}/" data/Dockerfiles/${SERVICE_NAME}/${SERVICE_NAME}/settings.yml
	sed -i "s/instance_name\ \:.*/instance_name\ \:\ \"${INSTANCE_NAME}\"/" data/Dockerfiles/${SERVICE_NAME}/${SERVICE_NAME}/settings.yml
	
	docker_build
	docker_pull

	stop_containers
	remove_containers

	docker_run_all

	delete_old_images

	restart_nginx
}

configure() {
	pre_configure_routine

	! [[ -d "${BASE_DIR}/data/Dockerfiles/${SERVICE_NAME}" ]] \
	&& echo -n "Cloning Searx repository into ${BASE_DIR}/data/Dockerfiles/${SERVICE_NAME}" \
	&& git submodule add -f https://github.com/asciimoo/searx.git "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME} >/dev/null \
	&& exit_response

	echo -e "# \e[4mSearx Settings\e[0m"

	set_domain
	
	if [ "$INSTANCE_NAME" ]; then
	  read -p "Instance Name: " -ei "$INSTANCE_NAME" INSTANCE_NAME
	else
	  read -p "Instance Name: " -ei "${SERVICE_NAME}" INSTANCE_NAME
	fi

	if [ "$THEME" ]; then
	  read -p "Theme [oscar, courgette, pix-art, simple]: " -ei "$THEME" THEME
	else
	  read -p "Theme [oscar, courgette, pix-art, simple]: " -ei "oscar" THEME
	fi

	cat <<-EOF >> "${SERVICE_ENV}"
	#SEARX
	## ------------------------------

	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME="${SERVICE_NAME}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN="${SERVICE_DOMAIN}"
	INSTANCE_NAME="${INSTANCE_NAME}"
	THEME="${THEME}"

	## ------------------------------
	#/SEARX

	EOF

	post_configure_routine
}
setup() {

	sed -i "s/default_theme\ :.*/default_theme\ :\ ${THEME}/" data/Dockerfiles/${SERVICE_NAME}/${SERVICE_NAME}/settings.yml
	sed -i "s/instance_name\ \:.*/instance_name\ \:\ \"${INSTANCE_NAME}\"/" data/Dockerfiles/${SERVICE_NAME}/${SERVICE_NAME}/settings.yml

	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi