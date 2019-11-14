#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="IPsec VPN Server"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="hwdsl2/ipsec-vpn-server" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/lib/modules" )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "\n# \e[4mIPsec VPN Server Settings\e[0m"
	if [ -z "$VPN_USER" ]; then
		read -p "VPN Username: " -ei "vpnuser" VPN_USER
	else
		read -p "VPN Username: " -ei "${VPN_USER}" VPN_USER
	fi
	
	if [ -z "$VPN_PASSWORD" ]; then
		stty_orig=`stty -g`
		stty -echo
	  	read -p "VPN Password: " -ei "" VPN_PASSWORD
		stty $stty_orig
		echo ""
	fi

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
	# Please use long, random alphanumeric strings (A-Za-z0-9)
	VPN_IPSEC_PSK=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 64)

	# ------------------------------
	# User configuration
	# ------------------------------
	
	VPN_USER=${VPN_USER}
	VPN_PASSWORD="${VPN_PASSWORD}"
	EOF

	if [[ $OSTYPE =~ "darwin" ]];then
		unset LC_ALL
	fi

	post_configure_routine
}

setup() {
	initial_setup_routine
	
	if ! lsmod | grep -q af_key;then
		echo -en "\e[1mLoading the IPsec NETKEY kernel module on the Docker host\e[0m"
		modprobe af_key
		exit_response
		[[ ! $(grep ^af_key$ /etc/modules) ]] && echo af_key >> /etc/modules
	fi

	docker_run_all

	post_setup_routine

}

$1
