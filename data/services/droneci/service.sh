
######
# service specific configuration
# you should setup your service here
######

# overrides service specific docker-variables
declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="drone/drone:1" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/data" )
declare -a networks=( )

# service specific functions
# to setup save service specific docker-variables to environment file
configure() {
	pre_configure_routine

	echo -e "# \e[4mDrone CI Settings\e[0m"

	set_domain

	# docker config

	# git server specific config
	PS3='Select your Server: '
	options=("Gogs" "Gitea" "Quit")
	select opt in "${options[@]}"
	do
		case $opt in
			"Gogs")
				CHOOSEN_SERVER_NAME="GOGS"
				SAVE_GOGS_ENV_DATA=1
				break
			;;
			"Gitea")
				CHOOSEN_SERVER_NAME="GITEA"

				read -p "$CHOOSEN_SERVER_NAME oauth Client ID: " -ei "" DRONE_GITEA_CLIENT_ID
				read -p "$CHOOSEN_SERVER_NAME  oauth Client Secret: " -ei "" DRONE_GITEA_CLIENT_SECRET
				SAVE_GITEA_ENV_DATA=1
				break
			;;
			"Quit")
				break
			;;
			*)
				echo "invalid option $REPLY"
			;;
		esac
	done

	if [ ${SAVE_GOGS_ENV_DATA} ] || [ ${SAVE_GITEA_ENV_DATA} ];then
		read -p "$CHOOSEN_SERVER_NAME server address: " -ei "https://" DRONE_SERVER_ADDRESS

		read -p "Drone-Ci username: " -ei "" DRONE_SERVER_USER

		# save Drone-Ci Config
		cat <<-EOF >> "${SERVICE_ENV}"
		PROPER_NAME=${PROPER_NAME}
		SERVICE_NAME=${SERVICE_NAME}
		SSL_CHOICE=${SSL_CHOICE}
		LE_EMAIL=${LE_EMAIL}

		# Drone-Ci Server Config
		DRONE_${CHOOSEN_SERVER_NAME}_SERVER=${DRONE_SERVER_ADDRESS}
		DRONE_SERVER_HOST=${SERVICE_DOMAIN}
		DRONE_SERVER_PROTO=https
		DRONE_RUNNER_CAPACITY=2
		DRONE_TLS_AUTOCERT=false
		DRONE_GIT_ALWAYS_AUTH=false
		DRONE_USER_CREATE=username:${DRONE_SERVER_USER},admin:true
		DRONE_DATABASE_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
		SERVICE_DOMAIN=${SERVICE_DOMAIN}
		DRONE_AGENTS_DISABLED=true
		EOF

		# save Drone-Ci special Gittea Config
		if [ ${SAVE_GITEA_ENV_DATA} ];then
			cat <<-EOF >> "${SERVICE_ENV}"

			# Drone-Ci special Gittea Config
			DRONE_GITEA_CLIENT_ID=${DRONE_GITEA_CLIENT_ID}
			DRONE_GITEA_CLIENT_SECRET=${DRONE_GITEA_CLIENT_SECRET}
			EOF
		fi
	fi

	post_configure_routine
}
