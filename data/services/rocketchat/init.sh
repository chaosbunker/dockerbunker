#!/usr/bin/env bash
######
# this file is identical to other service files and should not be edited
# pleas edit your service within service.sh
######

# setup base-directory variable
while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

# load PROPER_NAME and SERVICE_NAME dynamically
# from service folder-name
PROPER_NAME="$(basename $(dirname "$BASH_SOURCE"))"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -d '[:space:]')"
PROMPT_SSL=1

# load prior saved dockerbunker and service specific environment variables
declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

# load service specific configuration
source "$(dirname "$BASH_SOURCE")/service.sh"

# check shell-script call parameter
if [[ -z $1 ]]; then
  # if there isno parameter run menu function
  options_menu
elif [[ $1 == "letsencrypt" ]];then
  # run letsencrypt function with given parameter
  # e.g. init.sh letsencrypt issue
	$1 $*
else
  # run other given functions as parameter
  # e.g. init.sh reconfigure
	$1
fi
