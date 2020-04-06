
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
      service_status="$(printf "\e[32m${service}\e[0m \e[31m(Stopped)\e[0m")"
    else
      # style service as INSTALLED
      service_status="$(printf "\e[32m${service}\e[0m")"
    fi
    SERVICES_ARR+=( ["$service_status"]="${service}" )
    AVAILABLE_SERVICES+=( "$service_status" )

  elif elementInArray "${service}" "${CONFIGURED_SERVICES[@]}";then
    # style service as CONFIGURED
    service_status="$(printf "\e[33m${service}\e[0m")"
    SERVICES_ARR+=( ["$service_status"]="${service}" )
    AVAILABLE_SERVICES+=( "$service_status" )

	else
    # list service only
    service_status="$(printf "${service}")"
    SERVICES_ARR+=( ["$service_status"]="${service}" )
    AVAILABLE_SERVICES+=( "$service_status" )
  fi
done

# setup service meta-navigation
startall=$(printf "\e[1;4;33mStart all stopped containers\e[0m")
stopall=$(printf "\e[1;4;33mStop all running containers\e[0m")
startnginx=$(printf "\e[1;4;33mStart nginx container\e[0m")
stopnginx=$(printf "\e[1;4;33mStop nginx container\e[0m")
restartnginx=$(printf "\e[1;4;33mRestart nginx container\e[0m")
renewcerts=$(printf "\e[1;4;33mRenew Let's Encrypt certificates\e[0m")
restartall=$(printf "\e[1;4;33mRestart all containers\e[0m")
destroyall=$(printf "\e[1;4;33mDestroy everything\e[0m")
exitmenu=$(printf "\e[1;4;33mExit\e[0m")

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
echo "Please select the service you want to manage"
echo ""
[[ ${INSTALLED_SERVICES[@]} ]] || [[ ${STATIC_SITES[@]} ]] && echo -e " \e[32mGreen\e[0m: Installed"
[[ ${CONFIGURED_SERVICES[@]} ]] && echo -e " \e[33mOrange\e[0m: Configured"
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
    echo -e "\n\e[3m\xe2\x86\x92 Renew Let's Encrypt certificates\e[0m\n"
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
    echo -e "\n\e[3m\xe2\x86\x92 Destroy everything\e[0m"
    echo ""
    echo -e "\e[1mReset dockerbunker to its initial state\e[0m"
    echo ""
    echo "The following will be removed:"
    echo ""
    echo "- All dockerbunker container(s)"
    echo "- All dockerbunker volume(s)"
    echo "- All environment file(s)"
    echo "- All nginx configuration files"
    echo "- All SSL Certificates"
    echo ""
    prompt_confirm "Continue?" \
    && destroy_all=1 destroy_all
    say_done
    exit 0
    ;;
    $choice)
    if [[ -z $choice ]];then
      echo "Please choose a number from 1 to $count"
    else
      service="$(echo -e "${choice,,}" | tr -d '[:space:]')"
      echo ""
      echo -e "\n\e[3m\xe2\x86\x92 Checking service status"
      echo ""
      source "${BASE_DIR}/data/services/${SERVICES_ARR[$choice]}/init.sh"
      break
    fi
    ;;
  esac
done
