
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-hubot-dockerbunker" "${SERVICE_NAME}-db-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="rocketchat/rocket.chat:latest" [hubot]="rocketchat/hubot-rocketchat:latest" [db]="mongo" )
declare -A volumes=( [${SERVICE_NAME}-db-vol-1]="/data/db" [${SERVICE_NAME}-db-vol-2]="/dump" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mRocket.Chat Settings\e[0m"

	set_domain

	echo ""

	unset BOT_NAME
	if [ "${BOT_NAME}" ]; then
		read -p "Rocket.Chat Bot Display Name: " -ei "${BOT_NAME}" BOT_NAME
	else
		read -p "Rocket.Chat Bot Display Name: " -ei "Botty MacBotface" BOT_NAME
	fi

	echo ""

	unset ROCKETCHAT_USER
	if [ "$ROCKETCHAT_USER" ]; then
		read -p "Rocket.Chat Bot Username: " -ei "$ROCKETCHAT_USER" ROCKETCHAT_USER
	else
		read -p "Rocket.Chat Bot Username: " -ei "" ROCKETCHAT_USER
	fi

	echo ""

	unset ROCKETCHAT_PASSWORD
	while [[ "${#ROCKETCHAT_PASSWORD}" -le 6 || "$ROCKETCHAT_PASSWORD" != *[A-Z]* || "$ROCKETCHAT_PASSWORD" != *[a-z]* || "$ROCKETCHAT_PASSWORD" != *[0-9]* ]];do
		if [ $VALIDATE ];then
			echo -e "\n\e[31m  Password does not meet requirements\e[0m"
		fi
			stty_orig=$(stty -g)
			stty -echo
	  		read -p " $(printf "\n   \e[4mPassword requirements\e[0m\n   Minimum Length 6,Uppercase, Lowercase, Integer\n\n   Enter Bot Password:") " -ei "" ROCKETCHAT_PASSWORD
			stty "$stty_orig"
			echo ""
		VALIDATE=1
	done
	unset VALIDATE
	echo ""
	cat <<-EOF >> "${SERVICE_ENV}"
	SERVICE_NAME=${SERVICE_NAME}
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	SERVICE_DOMAIN=${SERVICE_DOMAIN}

    MONGO_URL=mongodb://db:27017/rocketchat
	ROOT_URL=https://${SERVICE_DOMAIN}
	Accounts_UseDNSDomainCheck=True
	ROCKETCHAT_URL=rocketchat-service-dockerbunker:3000

	ROCKETCHAT_ROOM=GENERAL
	ROCKETCHAT_USER=${ROCKETCHAT_USER}
	BOT_NAME="${BOT_NAME}"
	ROCKETCHAT_PASSWORD=${ROCKETCHAT_PASSWORD}
	EXTERNAL_SCRIPTS=hubot-help,hubot-seen,hubot-links,hubot-greetings

	EOF

	post_configure_routine
}
