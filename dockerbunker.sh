#!/usr/bin/env bash

if [[ -r /etc/redhat-release ]];then
	if ! dnf list installed docker-ce  &>/dev/null;then
	docker_missing=1
	fi
elif [[ -r /etc/debian_version ]];then
	if ! dpkg -l docker &>/dev/null;then
	docker_missing=1
	fi
fi

# if docker is missing install it
[[ $docker_missing ]] \
	&& echo -e "\n\e[3m\xe2\x86\x92 \e[1mCould not find docker.\e[3m\n\nMost systems can install Docker by running:\n\nwget -qO- https://get.docker.com/ | sh\n";

# Find base dir
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# initialize dockerbunker with variables and functions
source "${BASE_DIR}"/data/include/init.sh

#######
# load service-names dynamically
# via loop through folder-names at depth 1 within ./data/services, e.g. data/services/service-name
while IFS= read -r servicename; do
  declare -a ALL_SERVICES+=( $(basename "$servicename") )
done < <(find "${BASE_DIR}/data/services/" -mindepth 1 -maxdepth 1 -type d)

IFS=$'\n' sorted=($(printf '%s\n' "${ALL_SERVICES[@]}"|sort))

source "${BASE_DIR}"/data/include/init_menu.sh
