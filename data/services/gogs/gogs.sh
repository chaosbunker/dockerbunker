#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Gogs"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-db-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/data" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -a networks=( "dockerbunker-gogs" )
declare -A IMAGES=( [db]="mariadb:10.2" [service]="gogs/gogs" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}]="${DOCKERFILES}/${SERVICE_NAME}" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mGogs Settings\e[0m"

	set_domain

	if [ "$GOGS_APP_NAME" ]; then
	  read -p "Gogs Application Name: " -ei "$GOGS_APP_NAME" GOGS_APP_NAME
	else
	  read -p "Gogs Application Name: " -ei "Gogs Go Git Service" GOGS_APP_NAME
	fi
	
	echo "# User Settings"
	echo ""

	unset GOGS_ADMIN
	if [ "$GOGS_ADMIN" ]; then
	  read -p "Gogs Admin User: " -ei "$GOGS_ADMIN" GOGS_ADMIN
	else
		while [[ -z $GOGS_ADMIN || $GOGS_ADMIN == "admin" ]];do
			read -p "Gogs Admin User: " -ei "$GOGS_ADMIN" GOGS_ADMIN
			[[ ${GOGS_ADMIN} == "admin" ]] && echo -e "\n\e[31mAdmin account setting is invalid: name is reserved [name: admin]\e[0m\n"
		done
	fi
	
	if [ "$GOGS_ADMIN_EMAIL" ]; then
	  read -p "Gogs Admin E-Mail: " -ei "$GOGS_ADMIN_EMAIL" GOGS_ADMIN_EMAIL
	else
	  read -p "Gogs Admin E-Mail: " GOGS_ADMIN_EMAIL
	fi
	
	unset GOGS_ADMIN_PASSWORD
	while [[ "${#GOGS_ADMIN_PASSWORD}" -le 6 || "$GOGS_ADMIN_PASSWORD" != *[A-Z]* || "$GOGS_ADMIN_PASSWORD" != *[a-z]* || "$GOGS_ADMIN_PASSWORD" != *[0-9]* ]];do
		if [ $VALIDATE ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig=$(stty -g)
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" GOGS_ADMIN_PASSWORD
			stty "$stty_orig"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""

	prompt_confirm "Enable Registration Confirmation?" && GOGS_REGISTER_CONFIRM="on" || GOGS_REGISTER_CONFIRM="off"
	
	prompt_confirm "Enable Mail Notification?" && GOGS_MAIL_NOTIFY="on" || GOGS_MAIL_NOTIFY="off"

	echo ""	
	echo "# Server & Other  Service Settings"
	echo ""
	
	prompt_confirm "Enable Offline Mode?" && GOGS_OFFLINE_MODE="on" || GOGS_OFFLINE_MODE="off"
	
	prompt_confirm "Disable Gravatar Service?" && GOGS_DISABLE_GRAVATAR="on" || GOGS_DISABLE_GRAVATAR="off"
	
	prompt_confirm "Enable Federated Avatars Lookup?" && GOGS_ENABLE_FEDERATED_AVATAR="on" || GOGS_ENABLE_FEDERATED_AVATAR="on"

	prompt_confirm "Disable Self Registration?" && GOGS_DISABLE_REGISTRATION="off" || GOGS_DISABLE_REGISTRATION="on"
	
	prompt_confirm "Enable Captcha?" && GOGS_ENABLE_CAPTCHA="on" || GOGS_ENABLE_CAPTCHA="off"
	
	prompt_confirm "Enable Require Sign In To View Pages?" && GOGS_REQUIRE_SIGN_IN_VIEW="on" || GOGS_REQUIRE_SIGN_IN_VIEW="off"
	
	configure_mx

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

	# ------------------------------
	# SQL database configuration
	# ------------------------------

	GOGS_DBNAME=gogs
	GOGS_DBUSER=gogs
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	GOGS_DBPASS=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	GOGS_DBROOT=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	GOGS_APP_NAME="${GOGS_APP_NAME}"
	
	GOGS_REGISTER_CONFIRM=${GOGS_REGISTER_CONFIRM}
	GOGS_MAIL_NOTIFY=${GOGS_MAIL_NOTIFY}
	
	# ------------------------------
	# User configuration
	# ------------------------------
	
	GOGS_ADMIN=${GOGS_ADMIN}
	GOGS_ADMIN_EMAIL=${GOGS_ADMIN_EMAIL}
	GOGS_ADMIN_PASSWORD="${GOGS_ADMIN_PASSWORD}"
	
	# ------------------------------
	# Server & Other  Service Settings
	# ------------------------------
	
	GOGS_OFFLINE_MODE=${GOGS_OFFLINE_MODE}
	GOGS_DISABLE_GRAVATAR=${GOGS_DISABLE_GRAVATAR}
	GOGS_ENABLE_FEDERATED_AVATAR=${GOGS_ENABLE_FEDERATED_AVATAR}
	GOGS_DISABLE_REGISTRATION=${GOGS_DISABLE_REGISTRATION}
	GOGS_ENABLE_CAPTCHA=${GOGS_ENABLE_CAPTCHA}
	GOGS_REQUIRE_SIGN_IN_VIEW=${GOGS_REQUIRE_SIGN_IN_VIEW}
	
	SERVICE_SPECIFIC_MX=${SERVICE_SPECIFIC_MX}
	EOF
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	post_configure_routine
}
setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	docker_run_all

	# wait for gogs db to be available
	if ! docker exec gogs-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;then
		echo -e "\n\e[3mWaiting for gogs-db-dockerbunker to be ready...\e[0m"
		while ! docker exec gogs-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;do
			sleep 1
		done
	fi

	echo -e "\n\e[3mWaiting for https://${SERVICE_DOMAIN}/install to be accessible ...\e[0m"
	# Check if installation page is accessible and then install gogs
	while [[ $response != 200 ]];do
		response=$(curl -kso /dev/null -w '%{http_code}' https://${SERVICE_DOMAIN}/install)
		sleep 1
		count+=1
		[[ $count > 30 ]] && echo "\e[31mfailed\n\nCannot reach https://${SERVICE_DOMAIN}/install. Exiting\e[0m\n" && exit 1
	done
	[[ $response == 200 ]] && true

	echo -en "\n\e[1mInstalling Gogs via cURL ...\e[0m"
curl -k \
	-H 'Origin: null' -H 'Accept-Encoding: gzip, deflate' \
	-H 'Accept-Language: en-US,en;q=0.8,en-US;q=0.6,en;q=0.4' \
	-H 'Upgrade-Insecure-Requests: 1' \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36' \
	-H 'Content-Type: application/x-www-form-urlencoded' \
	-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
	-H 'Cache-Control: max-age=0' \
	-H 'Cookie: _ga=GA1.1.221947403.1432575239; lang=en_US; i_like_gogits=4e8b96e2a97347e0; _csrf=0NHae8OjPYKJ6xiplpZcsUhkwu86MTQ0MTExMTA2MDEyMzQ4ODk0Ng%3D%3D' \
	-H 'Connection: keep-alive' \
	-d "db_type=MySQL\
&db_host=db%3A3306\
&db_user=${GOGS_DBUSER}\
&db_passwd=${GOGS_DBPASS}\
&db_name=${GOGS_DBNAME}\
&ssl_mode=disable\
&db_path=data/gogs.db\
&app_name=${GOGS_APP_NAME}\
&repo_root_path=/data/git/gogs-repositories\
&run_user=git\
&domain=${SERVICE_DOMAIN}\
&ssh_port=22\
&http_port=3000\
&app_url=https://${SERVICE_DOMAIN}\
&log_root_path=/app/gogs/log\
&smtp_host=${MX_DOMAIN}:587\
&smtp_from=\
&smtp_user=${MX_EMAIL}\
&smtp_passwd=${MX_PASSWORD}\
&admin_name=${GOGS_ADMIN}\
&admin_passwd=${GOGS_ADMIN_PASSWORD}\
&admin_confirm_passwd=${GOGS_ADMIN_PASSWORD}\
&admin_email=${GOGS_ADMIN_EMAIL}\
&register_confirm=${GOGS_REGISTER_CONFIRM}\
&mail_notify=${GOGS_MAIL_NOTIFY}\
&offline_mode=${GOGS_OFFLINE_MODE}\
&disable_gravatar=${GOGS_DISABLE_GRAVATAR}\
&enable_federated_avatar=${GOGS_ENABLE_FEDERATED_AVATAR}\
&disable_registration=${GOGS_DISABLE_REGISTRATION}\
&enable_captcha=${GOGS_ENABLE_CAPTCHA}\
&require_sign_in_view=${GOGS_REQUIRE_SIGN_IN_VIEW}" --compressed \
-X POST "https://${SERVICE_DOMAIN}/install"

	response=$(curl -kso /dev/null -w '%{http_code}' https://${SERVICE_DOMAIN})
	[[ $response == 200 ]] && echo -e " \e[32m\xE2\x9C\x94\e[0m" || echo  -e " \e[31mfailed\e[0m"

	post_setup_routine
}
if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi

