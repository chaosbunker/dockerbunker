#!/usr/bin/env bash

[[ -z $1 || $2 ]] && echo "Usage: ./make_admin.sh username" && exit 1

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

declare -a environment=( "data/include/init.sh" "data/env/dockerbunker.env" "data/env/mastodon.env" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}/$env" ]] && source "${BASE_DIR}/$env"
done

image=( "tootsuite/mastodon" )

echo -en "Making ${2} admin..."
docker run -it --rm \
	--name=${SERVICE_NAME}-admin-dockerbunker \
	--network dockerbunker-${SERVICE_NAME} \
	--env-file "${SERVICE_ENV}" \
	--env user="${2}" \
	-v mastodon-data-vol-1:/mastodon/public/system \
	-v mastodon-data-vol-2:/mastodon/public/assets \
	-v mastodon-data-vol-3:/mastodon/public/packs \
${IMAGES[service]} bash -c "RAILS_ENV=production bin/tootctl accounts modify ${user} --role user"
exit_response

