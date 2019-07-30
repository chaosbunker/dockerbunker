#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Gitea"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-db-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( "dockerbunker-gitea" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/data" [${SERVICE_NAME}-db-vol-1]="/var/lib/mysql" )
declare -A IMAGES=( [db]="mariadb:10.3" [service]="gitea/gitea:1.7" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine

	echo -e "# \e[4mGitea Settings\e[0m"

	set_domain

	if [ "${GITEA_APP_NAME}" ]; then
	  read -p "Gitea Application Name: " -ei "${GITEA_APP_NAME}" GITEA_APP_NAME
	else
	  read -p "Gitea Application Name: " -ei "Gitea Go Git Service" GITEA_APP_NAME
	fi
	
	echo "# User Settings"
	echo ""

	unset GITEA_ADMIN
	if [ "${GITEA_ADMIN}" ]; then
	  read -p "Gitea Admin User: " -ei "${GITEA_ADMIN}" GITEA_ADMIN
	else
		while [[ -z ${GITEA_ADMIN} || ${GITEA_ADMIN } == "admin" ]];do
			read -p "Gitea Admin User: " -ei "${GITEA_ADMIN}" GITEA_ADMIN
			[[ ${GITEA_ADMIN} == "admin" ]] && echo -e "\n\e[31mAdmin account setting is invalid: name is reserved [name: admin]\e[0m\n"
		done
	fi
	
	if [ "${GITEA_ADMIN_EMAIL}" ]; then
	  read -p "Gitea Admin E-Mail: " -ei "${GITEA_ADMIN_EMAIL}" GITEA_ADMIN_EMAIL
	else
	  read -p "Gitea Admin E-Mail: " GITEA_ADMIN_EMAIL
	fi
	
	unset GITEA_ADMIN_PASSWORD
	while [[ "${#GITEA_ADMIN_PASSWORD}" -le 6 || "${GITEA_ADMIN_PASSWORD}" != *[A-Z]* || "${GITEA_ADMIN_PASSWORD}" != *[a-z]* || "${GITEA_ADMIN_PASSWORD}" != *[0-9]* ]];do
		if [ ${VALIDATE} ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig=$(stty -g)
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" GITEA_ADMIN_PASSWORD
			stty "${stty_orig}"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""

	prompt_confirm "Enable Registration Confirmation?" && GITEA_REGISTER_CONFIRM="on" || GITEA_REGISTER_CONFIRM="off"
	
	prompt_confirm "Enable Mail Notification?" && GITEA_MAIL_NOTIFY="on" || GITEA_MAIL_NOTIFY="off"

	echo ""	
	echo "# Server & Other  Service Settings"
	echo ""
	
	if [ "${SSH_PORT}" ]; then
	  read -p "SSH Port: " -ei "${SSH_PORT}" SSH_PORT
	else
	  read -p "SSH Port: " -ei "2222" SSH_PORT
	fi

	prompt_confirm "Enable Offline Mode?" && GITEA_OFFLINE_MODE="on" || GITEA_OFFLINE_MODE="off"
	
	prompt_confirm "Disable Gravatar Service?" && GITEA_DISABLE_GRAVATAR="on" || GITEA_DISABLE_GRAVATAR="off"
	
	prompt_confirm "Enable Federated Avatars Lookup?" && GITEA_ENABLE_FEDERATED_AVATAR="on" || GITEA_ENABLE_FEDERATED_AVATAR="on"

	prompt_confirm "Disable Self Registration?" && GITEA_DISABLE_REGISTRATION="off" || GITEA_DISABLE_REGISTRATION="on"
	
	prompt_confirm "Enable Captcha?" && GITEA_ENABLE_CAPTCHA="on" || GITEA_ENABLE_CAPTCHA="off"
	
	prompt_confirm "Enable Require Sign In To View Pages?" && GITEA_REQUIRE_SIGN_IN_VIEW="on" || GITEA_REQUIRE_SIGN_IN_VIEW="off"
	
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

	GITEA_DBNAME=gitea
	GITEA_DBUSER=gitea
	
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	GITEA_DBPASS=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	GITEA_DBROOT=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 28)
	
	# ------------------------------
	# General Settings
	# ------------------------------
	
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	GITEA_APP_NAME="${GITEA_APP_NAME}"
	SSH_PORT=${SSH_PORT}
	
	GITEA_REGISTER_CONFIRM=${GITEA_REGISTER_CONFIRM}
	GITEA_MAIL_NOTIFY=${GITEA_MAIL_NOTIFY}
	
	# ------------------------------
	# User configuration
	# ------------------------------
	
	GITEA_ADMIN=${GITEA_ADMIN}
	GITEA_ADMIN_EMAIL=${GITEA_ADMIN_EMAIL}
	GITEA_ADMIN_PASSWORD="${GITEA_ADMIN_PASSWORD}"
	
	# ------------------------------
	# Server & Other  Service Settings
	# ------------------------------
	
	GITEA_OFFLINE_MODE=${GITEA_OFFLINE_MODE}
	GITEA_DISABLE_GRAVATAR=${GITEA_DISABLE_GRAVATAR}
	GITEA_ENABLE_FEDERATED_AVATAR=${GITEA_ENABLE_FEDERATED_AVATAR}
	GITEA_DISABLE_REGISTRATION=${GITEA_DISABLE_REGISTRATION}
	GITEA_ENABLE_CAPTCHA=${GITEA_ENABLE_CAPTCHA}
	GITEA_REQUIRE_SIGN_IN_VIEW=${GITEA_REQUIRE_SIGN_IN_VIEW}
	
	## ------------------------------
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

	# wait for gitea db to be available
	if ! docker exec gitea-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;then
		echo -e "\n\e[3mWaiting for gitea-db-dockerbunker to be ready...\e[0m"
		while ! docker exec gitea-db-dockerbunker mysqladmin ping -h"127.0.0.1" --silent;do
			sleep 3
		done
	fi

	echo -e "\n\e[3mWaiting for https://${SERVICE_DOMAIN}/install to be accessible ...\e[0m"
	# Check if installation page is accessible and then install gitea
	while [[ $response != 200 ]];do
		response=$(curl -kso /dev/null -w '%{http_code}' https://${SERVICE_DOMAIN}/install)
		sleep 1
		count+=1
		[[ $count > 30 ]] && echo "\e[31mfailed\n\nCannot reach https://${SERVICE_DOMAIN}/install. Exiting\e[0m\n" && exit 1
	done
	[[ $response == 200 ]] && true

	echo -en "\n\e[1mInstalling Gitea via cURL ...\e[0m"
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
&db_user=${GITEA_DBUSER}\
&db_passwd=${GITEA_DBPASS}\
&db_name=${GITEA_DBNAME}\
&ssl_mode=disable\
&db_path=data/gitea.db\
&app_name=${GITEA_APP_NAME}\
&repo_root_path=/data/git/gitea-repositories\
&run_user=git\
&domain=${SERVICE_DOMAIN}\
&ssh_port=${SSH_PORT}\
&http_port=3000\
&app_url=https://${SERVICE_DOMAIN}\
&log_root_path=/app/gitea/log\
&smtp_host=${MX_DOMAIN}:587\
&smtp_from=\
&smtp_user=${MX_EMAIL}\
&smtp_passwd=${MX_PASSWORD}\
&admin_name=${GITEA_ADMIN}\
&admin_passwd=${GITEA_ADMIN_PASSWORD}\
&admin_confirm_passwd=${GITEA_ADMIN_PASSWORD}\
&admin_email=${GITEA_ADMIN_EMAIL}\
&register_confirm=${GITEA_REGISTER_CONFIRM}\
&mail_notify=${GITEA_MAIL_NOTIFY}\
&offline_mode=${GITEA_OFFLINE_MODE}\
&disable_gravatar=${GITEA_DISABLE_GRAVATAR}\
&enable_federated_avatar=${GITEA_ENABLE_FEDERATED_AVATAR}\
&disable_registration=${GITEA_DISABLE_REGISTRATION}\
&enable_captcha=${GITEA_ENABLE_CAPTCHA}\
&require_sign_in_view=${GITEA_REQUIRE_SIGN_IN_VIEW}" --compressed \
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