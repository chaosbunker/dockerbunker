######
# this file is identical to other service files and should not be edited
# pleas edit your service within service.sh
######

# check shell-script call parameter
if [[ -z $1 ]]; then
  # if there isno parameter run menu function
  options_menu
elif [[ $1 == "letsencrypt" && $2 == "issue" && $3 ]] \
&& [[ -f "${ENV_DIR}"/static/${3}.env ]] && source "${ENV_DIR}"/static/${3}.env \
&& letsencrypt issue "static";then
	[[ -z $1 ]] && options_menu
elif [[ $1 == "letsencrypt" ]];then
  # run letsencrypt function with given parameter
  # e.g. init.sh letsencrypt issue
	$1 $*
else
  # run other given functions as parameter
  # e.g. init.sh reconfigure
	$1
fi
