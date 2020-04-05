######
# this file is identical to other service files and should not be edited
# pleas edit your service within service.sh
######

# setup base-directory variable
while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

# load SERVICE_NAME and SERVICE_NAME dynamically
# from service folder-name
SERVICE_NAME="$(basename $(dirname "$BASH_SOURCE") | tr -cd '[a-z|0-9|\-|\_]')" # tr delets all the other characters)"
PROMPT_SSL=1

# load prior saved dockerbunker and service specific environment variables
declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

# load service specific configuration
source "$(dirname "$BASH_SOURCE")/service.sh"

# load common service function after service.sh
source "$BASE_DIR/data/include/init_service_after.sh"
