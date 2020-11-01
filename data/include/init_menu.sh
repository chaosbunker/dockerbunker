
#######
# setup Service menu
#######

# create array with service menu
# style menu according to what status service has
declare -A SERVICES_ARR
for service in "${sorted[@]}";do
	if elementInArray "$service" "${INSTALLED_SERVICES[@]}" \
	|| [[ "${STATIC_SERVICES[@]}" =~ "${service}" ]] ;then
    if elementInArray "$service" "${STOPPED_SERVICES[@]}";then
      # style service as STOPPED
      service_status="$(printf "\e[32m${service}\e[0m \e[31m$PRINT_STOPPED_MESSAGE\e[0m")"
    else
      # style service as INSTALLED
      service_status="$(printf "\e[32m${service}\e[0m")"
    fi
  elif elementInArray "${service}" "${CONFIGURED_SERVICES[@]}";then
    # style service as CONFIGURED
    service_status="$(printf "\e[33m${service}\e[0m")"
	else
    # list service only
    service_status="$(printf "${service}")"
  fi

	SERVICES_ARR+=( ["$service_status"]="${service}" )
	AVAILABLE_SERVICES+=( "$service_status" )
done

# setup service meta-navigation
startall=$(printf "\e[1;4;33m$PRINT_START_ALL_STOPPED_CONTAINERS\e[0m")
stopall=$(printf "\e[1;4;33m$PRINT_STOP_ALL_RUNNING_CONTAINERS\e[0m")
startnginx=$(printf "\e[1;4;33m$PRINT_START_NGINX_CONTAINER\e[0m")
stopnginx=$(printf "\e[1;4;33m$PRINT_STOP_NGINX_CONTAINER\e[0m")
restartnginx=$(printf "\e[1;4;33m$PRINT_RESTART_NGINX_CONTAINER\e[0m")
restartall=$(printf "\e[1;4;33m$PRINT_RESTART_ALL_CONTAINERS\e[0m")
destroyall=$(printf "\e[1;4;33m$PRINT_DESTROY_EVERYTHING\e[0m")
renewcerts=$(printf "\e[1;4;33m$PRINT_RENEW_LE_CERTs\e[0m")
exitmenu=$(printf "\e[1;4;33m$PRINT_EXIT\e[0m")

# add generell menu-entrys
[[ $(docker ps -q --filter "status=running" --filter name=^/nginx-dockerbunker$) ]] \
&& AVAILABLE_SERVICES+=( "$stopnginx" ) \
&& AVAILABLE_SERVICES+=( "$restartnginx")

[[ -d "${CONF_DIR}"/nginx/ssl/letsencrypt/live ]] \
&& [[ ${#INSTALLED_SERVICES[@]} > 0 ]] \
&& [[ $(ls -A "${CONF_DIR}"/nginx/ssl/letsencrypt/live) ]] \
&& AVAILABLE_SERVICES+=( "$renewcerts" )

[[ ${#INSTALLED_SERVICES[@]} > 0 \
|| ${#STATIC_SITES[@]} > 0 \
|| ${#CONFIGURED_SERVICES[@]} > 0 ]] \
&& AVAILABLE_SERVICES+=( "$destroyall" )

[[ $(docker ps -q --filter "status=exited" --filter name=^/nginx-dockerbunker$) ]] \
&& AVAILABLE_SERVICES+=( "$startnginx" )

[[ $(docker ps -q --filter "status=running" --filter name=dockerbunker) \
&& ${#INSTALLED_SERVICES[@]} > 0 ]] \
&& AVAILABLE_SERVICES+=( "$stopall" )

[[ $(docker ps -q --filter "status=exited" --filter name=dockerbunker) \
&& ${#STOPPED_SERVICES[@]} > 0 ]] \
&& AVAILABLE_SERVICES+=( "$startall" )

[[ ${#INSTALLED_SERVICES[@]} > 0 ]] \
&& AVAILABLE_SERVICES+=( "$restartall" )

# count all Menu-Entrys to work with its numbers
count="${#AVAILABLE_SERVICES[@]}"

# print menu
echo ""
echo "$PRINT_SERVICE_MANAGE_MESSAGE"
echo ""
[[ ${INSTALLED_SERVICES[@]} ]] || [[ ${STATIC_SITES[@]} ]] && echo -e " \e[32m$PRINT_GREEN\e[0m: $PRINT_INSTALLED"
[[ ${CONFIGURED_SERVICES[@]} ]] && echo -e " \e[33m$PRINT_ORANGE\e[0m: $PRINT_CONFIGURED"
echo ""

select choice in "${AVAILABLE_SERVICES[@]}"  "$exitmenu"
do
  case $choice in
    "$exitmenu")
    exit 0
    ;;
    "$startnginx")
    echo ""
    start_nginx
    say_done
    sleep 1
    break
    ;;
    "$stopnginx")
    echo ""
    stop_nginx
    say_done
    sleep 1
    break
    ;;
    "$restartnginx")
    prevent_nginx_restart=1
    echo ""
    restart_nginx
    say_done
    sleep 1
    break
    ;;
    "$renewcerts")
    echo -e "\n\e[3m\xe2\x86\x92 $PRINT_RENEW_LE_CERTs\e[0m\n"
    "${BASE_DIR}"/certbot.sh
    restart_nginx
    say_done
    sleep 1
    break
    ;;
    "$startall")
    prevent_nginx_restart=1
    start_all
    say_done
    sleep 1
    break
    ;;
		"$restartall")
		prevent_nginx_restart=1
		restart_all
		say_done
		sleep 1
		break
		;;
    "$stopall")
    prevent_nginx_restart=1
    stop_all
    say_done
    sleep 1
    break
    ;;
    "$destroyall")
    echo -e "\n\e[3m\xe2\x86\x92 $PRINT_DESTROY_ALL\e[0m"
    echo ""
    echo -e "\e[1m$PRINT_RESET_DOCKERBUNKER\e[0m"
    echo ""
    echo "$PRINT_FOLLWONING_WILL_REMOVED"
    echo ""
    echo "- $PRINT_ALL $PRINT_CONATIENRS"
    echo "- $PRINT_ALL $PRINT_VOLUMES"
    echo "- $PRINT_ALL $PRINT_ENVIRONMENT_FILES"
    echo "- $PRINT_ALL $PRINT_NGINX_CONFIG_FILES"
    echo "- $PRINT_ALL $PRINT_SSL_CERT"
    echo ""
    prompt_confirm "$PRINT_PROMPT_CONFIRM_QUESTION" \
    && destroy_all=1 destroy_all
    say_done
    exit 0
    ;;
    *)
    if [[ -z $choice ]];then
      echo "$PRINT_PLEASE_CHOOSE_A_NUMBER $count"
    else
      service="$(echo -e "${choice,,}" | tr -d '[:space:]')"
      echo ""
      echo -e "\n\e[3m\xe2\x86\x92 $PRINT_CHECKING_SERVICE_STATUS ${service}"
      echo ""
      source "${BASE_DIR}/data/services/${SERVICES_ARR[$choice]}/init.sh"
      break
    fi
    ;;
  esac
done
