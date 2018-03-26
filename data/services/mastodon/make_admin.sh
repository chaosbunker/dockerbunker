#!/usr/bin/env bash

[[ -z $1 || $2 ]] && echo "Usage: ./make_admin.sh username" && exit 1

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

declare -a environment=( "data/include/init.sh" "data/env/dockerbunker.env" "data/env/mastodon.env" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

image=( "dockerbunker/mastodon${glitch}" )

echo -en "Making ${2} admin..."
docker run -it --rm \
	--name=${SERVICE_NAME}-setup-dockerbunker \
	--network dockerbunker-${SERVICE_NAME} \
	--env-file "${SERVICE_ENV}" \
	-v mastodonglitch-data-vol-1:/mastodon/public/system \
	-v mastodonglitch-data-vol-2:/mastodon/public/assets \
	-v mastodonglitch-data-vol-3:/mastodon/public/packs \
${IMAGES[service]} bash -c "RAILS_ENV=production bundle exec rails mastodon:make_admin USERNAME=${2}" >/dev/null
exit_response

