
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
safe_to_keep_volumes_when_reconfiguring=1

declare -A WEB_SERVICES
declare -a containers=( "sftpserver-service-dockerbunker" )
declare -a volumes=( )
declare -a networks=( )
declare -A IMAGES=( [service]="atmoz/sftp:alpine-3.7" )
declare -a add_to_network=( "sftpserver-service-dockerbunker" )


# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4msFTP Settings\e[0m"

	set_domain

	userNumber=0
	done=""
	while [[ -z $done ]];do
		[[ -f "${CONF_DIR}"/sftpserver/users.conf ]] && rm "${CONF_DIR}"/sftpserver/users.conf
		unset user password
		((++userNumber))
		read -p "sFTP User $userNumber: " -ei "" user
		echo "USER $user"
		while [[ "${#password}" -le 6 || "$password" != *[A-Z]* || "$password" != *[a-z]* || "$password" != *[0-9]* ]];do
			if [ $VALIDATE ];then
				echo -e "\n\e[31m  Password does not meet requirements\e[0m"
			fi
				stty_orig=$(stty -g)
				stty -echo
		  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Password:") " -ei "" password
				stty "$stty_orig"
				echo ""
			VALIDATE=1
		done
		unset VALIDATE
		declare -A FTP_USERS
		FTP_USERS+=( [$user]="$password" )
		FTP_USERS_ARRAY+=( "[${user}]=\"${password}\"" )
		prompt_confirm "Add another user?"
		[[ $? == 1 ]] && done=1
	done

	[[ ! -d "${CONF_DIR}"/sftpserver/conf/ssh ]] && mkdir -p "${CONF_DIR}"/sftpserver/conf/ssh
	USERID=1001
	for user in ${!FTP_USERS[@]};do
		echo "$user:${FTP_USERS[$user]}:${USERID}:100" >> "${CONF_DIR}"/sftpserver/users.conf
		((++USERID))
	done

	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	LE_EMAIL=${LE_EMAIL}
	SSL_CHOICE=${SSL_CHOICE}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	FTP_USERS=( ${FTP_USERS_ARRAY[@]} )
	EOF

	[[ ! -d "${BASE_DIR}"/data/web/sftpserver ]] && mkdir -p "${BASE_DIR}"/data/web/sftpserver

	[[ ! -d "${CONF_DIR}"/sftpserver/conf/ssh ]] && mkdir "${CONF_DIR}"/sftpserver/conf/ssh

	[[ ! -f "${CONF_DIR}"/sftpserver/ssh/ssh_host_ed25519_key ]] && ssh-keygen -t ed25519 -f "${CONF_DIR}"/sftpserver/ssh/ssh_host_ed25519_key
	[[ ! -f "${CONF_DIR}"/sftpserver/ssh/ssh_host_rsa_key ]] && ssh-keygen -t rsa -b 4096 -f "${CONF_DIR}"/sftpserver/ssh/ssh_host_rsa_key
	post_configure_routine
}
