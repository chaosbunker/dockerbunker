#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="CS50 IDE"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1
safe_to_keep_volumes_when_reconfiguring=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a volumes=( [${SERVICE_NAME}-data-vol-1]="/home/ubuntu/workspace" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a networks=( )
declare -A IMAGES=( [service]="cs50/ide50-offline" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mCS50 IDE Settings\e[0m"

	set_domain

	echo -e "\nCS50 IDE should not be run anywhere but locally. If you want to run it on a server that is accessible by anyone, it is recommended to protect https://${SERVICE_DOMAIN} with basic authentication.\n"

	prompt_confirm "Use Basic Authentication to limit access to https://${SERVICE_DOMAIN}?" choice
	if [[ $? == 0 ]];then
		BASIC_AUTH="yes"
		if [[ -z $HTUSER ]]; then
			while [[ -z ${HTUSER} ]];do
				read -p "Basic Auth Username: " -ei "" HTUSER
			done
		else
			read -p "Basic Auth Username: " -ei "${HTUSER}" HTUSER
		fi
		unset HTPASSWD
		while [[ "${#HTPASSWD}" -le 6 || "$HTPASSWD" != *[A-Z]* || "$HTPASSWD" != *[a-z]* || "$HTPASSWD" != *[0-9]* ]];do
			if [ $VALIDATE ];then
				echo -e "\n\e[31m  Password does not meet requirements\e[0m"
			fi
				stty_orig=$(stty -g)
				stty -echo
		  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6, Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" HTPASSWD
				stty "$stty_orig"
				echo ""
			VALIDATE=1
		done
		unset VALIDATE
		echo ""
	else
		AUTH_SWITCH="#"
		BASIC_AUTH="no"
	fi

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	LE_EMAIL=${LE_EMAIL}
	SSL_CHOICE=${SSL_CHOICE}
	BASIC_AUTH=${BASIC_AUTH}
	AUTH_SWITCH=${AUTH_SWITCH}
	HTUSER=${HTUSER}
	HTPASSWD=${HTPASSWD}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	EOF

	post_configure_routine
}

setup() {
	initial_setup_routine

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" "\${AUTH_SWITCH}" )
	basic_nginx

	docker_run_all

	post_setup_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi
