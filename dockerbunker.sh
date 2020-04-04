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

# initialize variables and functions
source "${BASE_DIR}"/data/include/init.sh

# initialize menu
source "${BASE_DIR}"/data/include/init_menu.sh
