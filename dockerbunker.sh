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

# setup basedir
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# path to used print language
source "${BASE_DIR}/data/include/i18n/en.sh"

# if docker is missing install it
if [[ $docker_missing ]]; then
	echo -e "\n\e[31m\xe2\x86\x92 $PRINT_MISSING_DOCKER\n";
else

	# initialize variables and functions
	source "${BASE_DIR}"/data/include/init.sh

	# initialize menu
	source "${BASE_DIR}"/data/include/init_menu.sh
fi
