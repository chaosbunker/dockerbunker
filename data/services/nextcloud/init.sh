#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Nextcloud"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-db-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="nextcloud:stable" [db]="mariadb:10.2" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/var/www/html/custom_apps" [${SERVICE_NAME}-data-vol-2]="/var/www/html/config" [${SERVICE_NAME}-data-vol-3]="/var/www/html/data" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mNextcloud Settings\e[0m"

	set_domain
	
	unset NEXTCLOUD_ADMIN_USER
	if [ "$NEXTCLOUD_ADMIN_USER" ]; then
	  read -p "Nextcloud Admin User: " -ei "$NEXTCLOUD_ADMIN_USER" NEXTCLOUD_ADMIN_USER
	else
		while [[ -z $NEXTCLOUD_ADMIN_USER || $NEXTCLOUD_ADMIN_USER == "admin" ]];do
			read -p "Nextcloud Admin User: " -ei "$NEXTCLOUD_ADMIN_USER" NEXTCLOUD_ADMIN_USER
			[[ ${NEXTCLOUD_ADMIN_USER} == "admin" ]] && echo -e "\n\e[31mAdmin account setting is invalid: name is reserved [name: admin]\e[0m\n"
		done
	fi
	
	unset NEXTCLOUD_ADMIN_PASSWORD
	while [[ "${#NEXTCLOUD_ADMIN_PASSWORD}" -le 6 || "$NEXTCLOUD_ADMIN_PASSWORD" != *[A-Z]* || "$NEXTCLOUD_ADMIN_PASSWORD" != *[a-z]* || "$NEXTCLOUD_ADMIN_PASSWORD" != *[0-9]* ]];do
		if [ $VALIDATE ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig=$(stty -g)
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" NEXTCLOUD_ADMIN_PASSWORD
			stty "$stty_orig"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""

	# avoid tr illegal byte sequence in macOS when generating random strings
	if [[ $OSTYPE =~ "darwin" ]];then
		if [[ $LC_ALL ]];then
			oldLC_ALL=$LC_ALL
			export LC_ALL=C
		else
			export LC_ALL=C
		fi
	fi
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME=${PROPER_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
	NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
	NEXTCLOUD_TRUSTED_DOMAINS=${SERVICE_DOMAIN}
	
	# ------------------------------
	# SQL database configuration
	# ------------------------------

	MYSQL_DATABASE=nextcloud
	MYSQL_USER=nextcloud
	MYSQL_HOST=db
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	EOF
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi