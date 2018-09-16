#!/usr/bin/env bash
while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Mastodon"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

declare -A WEB_SERVICES
declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -a containers=( "${SERVICE_NAME}-postgres-dockerbunker" "${SERVICE_NAME}-redis-dockerbunker" "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-streaming-dockerbunker" "${SERVICE_NAME}-sidekiq-dockerbunker" "${SERVICE_NAME}-elasticsearch-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" "${SERVICE_NAME}-streaming-dockerbunker" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/mastodon/public/system" [${SERVICE_NAME}-data-vol-2]="/mastodon/public/assets" [${SERVICE_NAME}-data-vol-3]="/mastodon/public/packs" [${SERVICE_NAME}-postgres-vol-1]="/var/lib/postgresql/data" [${SERVICE_NAME}-elasticsearch-vol-1]="/usr/share/elasticsearch/data" [${SERVICE_NAME}-redis-vol-1]="/data" )
declare -a networks=( "dockerbunker-${SERVICE_NAME}" )
declare -A IMAGES=( [service]="dockerbunker/${SERVICE_NAME}" [redis]="redis:4.0-alpine" [postgres]="postgres" [elasticsearch]="docker.elastic.co/elasticsearch/elasticsearch-oss:6.1.3" )
declare -A BUILD_IMAGES=( [dockerbunker/${SERVICE_NAME}${GLITCH}]="${DOCKERFILES}/${SERVICE_NAME}${GLITCH}" )

if [[ $1 == "make_admin" ]];then
	if [[ -z $2 || $3 ]];then
		echo "Usage: ./mastodon.sh make_admin username"
		exit 1
	else
		mastodon_makeadmin_dockerbunker $2
		exit 0
	fi
fi

[[ -z $1 ]] && options_menu

upgrade() {

	get_current_images_sha256

	[[ -z $GLITCH ]] && current="Mastodon" alt="Mastodon Glitch Edition" \
		|| current="Mastodon Glitch Edition" alt="Mastodon" \

	prompt_confirm "You are currently using ${current}. Switch to ${alt}?"
	
	if [[ $? == 0 && -z $GLITCH ]];then
		GLITCH=glitch
		sed -i "s/GLITCH=.*/GLITCH=${GLITCH}/" "${SERVICE_ENV}"
		# temporarily change service name to build image from mastodon glitch repo
		SERVICE_NAME=mastodonglitch
	else
		GLITCH=""
		sed -i "s/GLITCH=.*/GLITCH=/" "${SERVICE_ENV}"
	fi

	docker_build
	docker_pull

	stop_containers
	remove_containers

	[[ $GLITCH ]] && SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"

	mastodon_postgres_dockerbunker
	mastodon_redis_dockerbunker
	mastodon_dbmigrateandprecompileassets_dockerbunker

	docker_run_all

	delete_old_images

	restart_nginx
}

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mMastodon Settings\e[0m"

	unset GLITCH
	prompt_confirm "Deploy Glitch Edition (https://-soc.github.io/docs/)?"
	if [[ $? == 0 ]];then
		GLITCH=glitch
		SERVICE_NAME=${SERVICE_NAME}glitch
		! [[ -d "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME} ]] \
			&& git clone https://github.com/glitch-soc/mastodon.git "data/Dockerfiles/mastodonglitch" >/dev/null
	else
		! [[ -d "${BASE_DIR}"/data/Dockerfiles/mastodon ]] \
			&& git clone https://github.com/tootsuite/mastodon.git "data/Dockerfiles/${SERVICE_NAME}" >/dev/null
	fi

	set_domain

	### Increase number of characters / toot
	sed -i -e 's/500/800/g' \
	    "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/javascript/mastodon/features/compose/components/compose_form.js \
	    "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/validators/status_length_validator.rb \
		${BASE_DIR}/data/Dockerfiles/${SERVICE_NAME}/config/locales/*.yml
	
	### Increase bio length
	sed -i -e 's/160/400/g' \
	    "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/javascript/packs/public.js \
	    "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/models/account.rb \
	    "${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/views/settings/profiles/show.html.haml
	
	### Cat emoji
	sed -i -e 's/1f602/1f431/g' \
		"${BASE_DIR}"/data/Dockerfiles/${SERVICE_NAME}/app/javascript/mastodon/features/compose/components/emoji_picker_dropdown.js

	configure_mx

	SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"

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
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME="${SERVICE_NAME}"
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}
	GLITCH=${GLITCH}

	SERVICE_DOMAIN="${SERVICE_DOMAIN}"
	LOCAL_DOMAIN=${SERVICE_DOMAIN}
	SECRET_KEY_BASE=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 128)
	OTP_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 128)
	VAPID_PRIVATE_KEY=
	VAPID_PUBLIC_KEY=

	REDIS_HOST=redis
	REDIS_PORT=6379
	DB_HOST=postgres
	DB_USER=postgres
	DB_NAME=postgres
	DB_PASS=
	DB_PORT=5432
	ES_ENABLED=true
	ES_HOST=es
	ES_PORT=9200

	SMTP_SERVER=${MX_HOSTNAME}
	SMTP_PORT=587
	SMTP_LOGIN=${MX_EMAIL}
	SMTP_PASSWORD=${MX_PASSWORD}
	SMTP_FROM_ADDRESS=${MX_EMAIL}
	STREAMING_CLUSTER_NUM=1

	SERVICE_SPECIFIC_MX=${SERVICE_SPECIFIC_MX}
	EOF

	source "${SERVICE_ENV}"
	if [[ $OSTYPE =~ "darwin" ]];then
		[[ $oldLC_ALL ]] && export LC_ALL=$oldLC_ALL || unset LC_ALL
	fi

	docker_build dockerbunker/mastodon${GLITCH}

	mastodon_generatevapidkeys_dockerbunker
	source "${ENV_DIR}"/${SERVICE_NAME}_tmp.env
	rm "${ENV_DIR}"/${SERVICE_NAME}_tmp.env

	sed -i "s/VAPID_PRIVATE_KEY=.*/VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}/" "${ENV_DIR}"/${SERVICE_NAME}.env
	sed -i "s/VAPID_PUBLIC_KEY=.*/VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}/" "${ENV_DIR}"/${SERVICE_NAME}.env

	post_configure_routine
}
setup() {

	[[ $GLITCH ]] && SERVICE_NAME=${SERVICE_NAME}${GLITCH}

	initial_setup_routine

	[[ $GLITCH ]] && SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"

	SUBSTITUTE=( "\${SERVICE_DOMAIN}" )
	basic_nginx

	mastodon_postgres_dockerbunker
	mastodon_redis_dockerbunker
	mastodon_dbmigrateandprecompileassets_dockerbunker

	docker_run_all

	post_setup_routine

	echo -e "\nAfter signing up on ${SERVICE_DOMAIN} make your user an admin by running\n\n\
${SERVICES_DIR}/${SERVICE_NAME}/./make_admin.sh username\n"

}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi