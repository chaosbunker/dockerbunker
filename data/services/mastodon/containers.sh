mastodon_service_dockerbunker() {
	docker run -d --user mastodon \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--network dockerbunker-${SERVICE_NAME} \
		--env RUN_DB_MIGRATIONS=true --env UID=991 --env GID=991 --env WEB_CONCURRENCY=16 --env MAX_THREADS=20 --env SIDEKIQ_WORKERS=25 \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
		-v ${SERVICE_NAME}-data-vol-3:${volumes[${SERVICE_NAME}-data-vol-3]} \
	${IMAGES[service]}${GLITCH} bundle exec rails s -p 3000 -b '0.0.0.0' >/dev/null
}

mastodon_streaming_dockerbunker() {
	docker run -d --user mastodon \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network ${NETWORK} \
		--network dockerbunker-${SERVICE_NAME} \
		--env RUN_DB_MIGRATIONS=true --env UID=991 --env GID=991 --env WEB_CONCURRENCY=16 --env MAX_THREADS=20 --env SIDEKIQ_WORKERS=25 \
		--env-file "${SERVICE_ENV}" \
	${IMAGES[service]}${GLITCH} npm run start >/dev/null
}

mastodon_sidekiq_dockerbunker() {
	docker run -d --user mastodon \
		--name=${FUNCNAME[0]//_/-} \
		--restart=always \
		--network dockerbunker-${SERVICE_NAME} --net-alias=sidekiq \
		--env RUN_DB_MIGRATIONS=true --env UID=991 --env GID=991 --env WEB_CONCURRENCY=16 --env MAX_THREADS=20 --env SIDEKIQ_WORKERS=25 \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
	${IMAGES[service]}${GLITCH} bundle exec sidekiq -q default -q mailers -q pull -q push >/dev/null
}

mastodon_redis_dockerbunker() {
	docker run -d --user redis \
		--name ${FUNCNAME[0]//_/-} \
		--network dockerbunker-${SERVICE_NAME} --net-alias redis \
		-v ${SERVICE_NAME}-redis-vol-1:${volumes[${SERVICE_NAME}-redis-vol-1]} \
	${IMAGES[redis]} >/dev/null
}

mastodon_elasticsearch_dockerbunker() {
	docker run -d --user elasticsearch \
		--name=${FUNCNAME[0]//_/-} \
		--restart=unless-stopped \
		--network dockerbunker-${SERVICE_NAME} --net-alias=es \
		--env ES_JAVA_OPTS="-Xms512m -Xmx512m" \
		-v ${SERVICE_NAME}-elasticsearch-vol-1:${volumes[${SERVICE_NAME}-elasticsearch-vol-1]} \
	${IMAGES[elasticsearch]} >/dev/null
}

mastodon_postgres_dockerbunker() {
	docker run -d --user postgres \
		--name=${FUNCNAME[0]//_/-} \
		--restart=unless-stopped \
		--network dockerbunker-${SERVICE_NAME} --net-alias=postgres \
		-v mastodon-postgres-vol-1:/var/lib/postgresql/data \
	${IMAGES[postgres]} >/dev/null
}

mastodon_generatevapidkeys_dockerbunker() {
	echo -en "\n\e[1mGenerating VAPID keys\e[0m"
	docker run -it --rm \
		--name=${SERVICE_NAME}-vapidgen-dockerbunker \
		--env-file "${SERVICE_ENV}" \
	${IMAGES[service]}${GLITCH} rake mastodon:webpush:generate_vapid_key | grep VAPID > "${ENV_DIR}"/${SERVICE_NAME}_tmp.env
	exit_response
}

mastodon_dbmigrateandprecompileassets_dockerbunker() {
	echo -en "\n\e[1mCreating DB and precompiling assets\e[0m"
	docker run -it --rm \
		--name=${SERVICE_NAME}-dbsetup-dockerbunker \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
		-v ${SERVICE_NAME}-data-vol-3:${volumes[${SERVICE_NAME}-data-vol-3]} \
	${IMAGES[service]}${GLITCH} bash -c "rake db:migrate && rake assets:precompile" >/dev/null
	exit_response
}

mastodon_makeadmin_dockerbunker() {
	echo -en "\n\e[1mMaking ${1} admin...\e[0m"
	docker run -it --rm \
		--name=${FUNCNAME[0]//_/-} \
		--network dockerbunker-${SERVICE_NAME} \
		--env-file "${SERVICE_ENV}" \
		-v ${SERVICE_NAME}-data-vol-1:${volumes[${SERVICE_NAME}-data-vol-1]} \
		-v ${SERVICE_NAME}-data-vol-2:${volumes[${SERVICE_NAME}-data-vol-2]} \
		-v ${SERVICE_NAME}-data-vol-3:${volumes[${SERVICE_NAME}-data-vol-3]} \
	${IMAGES[service]} bash -c "RAILS_ENV=production bundle exec rails mastodon:make_admin USERNAME=${1}" >/dev/null
	exit_response
}
