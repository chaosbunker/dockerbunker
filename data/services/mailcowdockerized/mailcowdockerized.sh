#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

SERVICE_HOME="${BASE_DIR}"/data/docker-compose/mailcowdockerized
PROPER_NAME="Mailcow Dockerized"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/include/init.sh" "data/env/dockerbunker.env" "data/docker-compose/${SERVICE_NAME}/mailcow.conf" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "mailcowdockerized_acme-mailcow_1" "mailcowdockerized_rspamd-mailcow_1" "mailcowdockerized_nginx-mailcow_1" "mailcowdockerized_netfilter-mailcow_1" "mailcowdockerized_php-fpm-mailcow_1" "mailcowdockerized_redis-mailcow_1" "mailcowdockerized_unbound-mailcow_1" "mailcowdockerized_ipv6nat_1" "mailcowdockerized_postfix-mailcow_1" "mailcowdockerized_memcached-mailcow_1" "mailcowdockerized_sogo-mailcow_1" "mailcowdockerized_watchdog-mailcow_1" "mailcowdockerized_dockerapi-mailcow_1" "mailcowdockerized_clamd-mailcow_1" "mailcowdockerized_dovecot-mailcow_1" "mailcowdockerized_mysql-mailcow_1" )
declare -a volumes=( "mailcowdockerized_crypt-vol-1" "mailcowdockerized_dkim-vol-1" "mailcowdockerized_mysql-vol-1" "mailcowdockerized_postfix-vol-1" "mailcowdockerized_redis-vol-1" "mailcowdockerized_rspamd-sock" "mailcowdockerized_rspamd-vol-1" "mailcowdockerized_vmail-vol-1" )
declare -a networks=( )
declare -a add_to_network=( "mailcowdockerized_nginx-mailcow_1" )

unset images
for image in ${IMAGES[@]};do
	images+=( $image )
done

DOCKER_COMPOSE=1

[[ -z $1 ]] && options_menu


upgrade() {
	echo ""
	echo "Please manually update the mailcow repository first, before continuing."
	echo "The repository is located in ${SERVICE_HOME}"
	echo ""
	echo "For instructions refer to:"
	echo "https://mailcow.github.io/mailcow-dockerized-docs/install-update/"
	echo ""
	prompt_confirm "Continue?"

	if [[ $? == 0 ]];then
		pull_and_compare
		delete_old_images
		restart_nginx
	else
		exit 0
	fi
}

configure() {
	pre_configure_routine

	! [[ -d "${BASE_DIR}"/data/docker-compose ]] && mkdir -p "${BASE_DIR}"/data/docker-compose

	pushd "${BASE_DIR}" >/dev/null
	! [[ -d "${SERVICE_HOME}" ]] \
	&& echo -n "Cloning Mailcow Dockerized repository into "${BASE_DIR}"/data/docker-compose/mailcowdockerized" \
	&& git submodule add https://github.com/mailcow/mailcow-dockerized.git data/docker-compose/mailcowdockerized >/dev/null \
	&& exit_response
	popd >/dev/null

	echo -e "# \e[4mMailcow Dockerized Settings\e[0m"

	pushd "${SERVICE_HOME}" >/dev/null
	echo -e "\n\e[3m\xe2\x86\x92 Running external script generate_config.sh\e[0m"
	echo -e "\nThis script is required by mailcow. It generates the file "mailcow.conf". Both files can be found in the following directory\e"
	echo ""
	echo " ${SERVICE_HOME}"
	echo ""
	./generate_config.sh
	popd >/dev/null
	echo -e "\n\e[3m\xe2\x86\x92 Finished running generate_config.sh\e[0m"
	echo ""

	for i in $(grep "image:" "${SERVICE_HOME}"/docker-compose.yml | awk '{print $NF}');do IMAGES+=( \"$i\" );done

	configure_ssl

	[[ -f "${SERVICE_HOME}"/mailcow.conf ]] &&  source "${SERVICE_HOME}"/mailcow.conf || echo "Could not find mailcow.conf. Exiting."

	sed -i "s/HTTP_PORT=.*/HTTP_PORT=8080/" "${SERVICE_HOME}"/mailcow.conf
	sed -i "s/HTTPS_PORT=.*/HTTPS_PORT=8443/" "${SERVICE_HOME}"/mailcow.conf
	sed -i "s/HTTP_BIND=.*/HTTP_BIND=127\.0\.0\.1/" "${SERVICE_HOME}"/mailcow.conf
	sed -i "s/HTTPS_BIND=.*/HTTPS_BIND=127\.0\.0\.1/" "${SERVICE_HOME}"/mailcow.conf

	cat <<-EOF >> "${SERVICE_ENV}"
	SERVICE_HOME="${SERVICE_HOME}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME="${SERVICE_NAME}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	DOCKER_COMPOSE=${DOCKER_COMPOSE}

	SERVICE_DOMAIN="${MAILCOW_HOSTNAME}"
	DOMAIN=${MAILCOW_HOSTNAME#*.}

	IMAGES=( ${IMAGES[@]} )

	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	which docker-compose >/dev/null
	if [[ $? == 1 ]];then
		echo -e "docker-compose not found. You can now automatically be installed via\n\n\
			curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose\n"
		prompt_confirm "Continue?"
		if [[ $? == 0 ]];then
			curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
			chmod +x /usr/local/bin/docker-compose
		else
			echo "Please install docker-compose and try again."
			exit 0;
		fi
	fi

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${DOMAIN}" )

	basic_nginx

	pushd "${SERVICE_HOME}" >/dev/null
	docker-compose up -d
	popd >/dev/null

	connect_containers_to_network

	restart_nginx

	[[ SSL_CHOICE == "le" ]] && echo -e "\nMake sure to add autodiscover.${DOMAIN} and autoconfig.${DOMAIN} to your Let's Encrypt certificate."

	post_setup_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi