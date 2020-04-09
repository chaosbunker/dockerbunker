#######
# All functions used during setup of a service
#
# function: docker_pull
# function: docker_run
# function: docker_run_all
# function: get_current_images_sha256
# function: pull_and_compare
# function: delete_old_images
# function: create_volumes
# function: wait_for_db
#######

docker_pull() {
	for image in ${IMAGES[@]};do
		[[ "$image" != "dockerbunker/${SERVICE_NAME}" ]] \
			&& echo -e "\n\e[1m$PRINT_PULLING $image\e[0m" \
			&& docker pull $image
	done
}

docker_run() {
	$1
}

docker_run_all() {
	echo -e "\n\e[1m$PRINT_STARTING_CONTAINERS\e[0m"
	for container in "${containers[@]}";do
		! [[ $(docker ps -q --filter name="^/${container}$") ]] \
			&& echo -en "- $container" \
			&& ${container//-/_} \
			&& exit_response \
			|| echo "- $container $PRINT_ALREADY_RUNNING"
	done
	connect_containers_to_network
}

get_current_images_sha256() {
	# get current images' sha256
	if [[ -z ${CURRENT_IMAGES_SHA256[@]} ]];then
		collectImageNamesAndCorrespondingSha256
		declare -A CURRENT_IMAGES_SHA256
		for key in "${!IMAGES_AND_SHA256[@]}";do
			CURRENT_IMAGES_SHA256[$key]+=${IMAGES_AND_SHA256[$key]}
		done
	fi
	declare -p CURRENT_IMAGES_SHA256 >> "${BASE_DIR}"/.image_shas.tmp
	unset IMAGES_AND_SHA256
}

pull_and_compare() {
	[[ -f "${BASE_DIR}"/.image_shas.tmp ]] \
		&& rm "${BASE_DIR}"/.image_shas.tmp

	get_current_images_sha256

	if [[ ${DOCKER_COMPOSE} ]];then
		pushd "${SERVICE_HOME}" >/dev/null
		echo ""
		echo -e "\e[1m$PRINT_PULLING_NEW_IMAGES\e[0m"
		echo ""
		docker-compose pull
	else
		docker_pull
	fi

	if [[ -f "${BASE_DIR}"/.image_shas.tmp ]];then
		source "${BASE_DIR}"/.image_shas.tmp
	else
		echo -e "\n\e[31m$PRINT_COULD_NOT_FIND_IMAGE_DIGEST.\n$PRINT_EXITING.\e[0m"
		exit 1
	fi
	# compare sha256 and delete old unused images
	collectImageNamesAndCorrespondingSha256
	declare -A NEW_IMAGES_SHA256
	for key in "${!IMAGES_AND_SHA256[@]}";do
		NEW_IMAGES_SHA256[$key]+=${IMAGES_AND_SHA256[$key]}
	done

	for key in "${!CURRENT_IMAGES_SHA256[@]}";do
		if [[ ${CURRENT_IMAGES_SHA256[$key]} != ${NEW_IMAGES_SHA256[$key]} ]];then
			old_images_to_delete+=( ${CURRENT_IMAGES_SHA256[$key]} )
		else
			unchanged_images_to_keep+=( ${CURRENT_IMAGES_SHA256[$key]} )
		fi
	done

	if [[ ${DOCKER_COMPOSE} ]] \
	&& [[ ${old_images_to_delete[0]} ]];then
		pushd "${SERVICE_HOME}" >/dev/null
		echo -e "\n\e[1m$PRINT_TAKING_DOWN_SERVICE ${SERVICE_NAME}\e[0m"
		docker-compose down
		echo -e "\n\e[1m$PRINT_BRINGIN_UP_SERVICE ${SERVICE_NAME}\e[0m"
		docker-compose up -d
		popd >/dev/null
	fi

	[[ ${old_images_to_delete[0]} ]] \
		&& declare -p old_images_to_delete >> "${BASE_DIR}"/.image_shas.tmp
	[[ ${unchanged_images_to_keep[0]} ]] \
		&& declare -p unchanged_images_to_keep >> "${BASE_DIR}"/.image_shas.tmp

	for container in "${containers[@]}";do
		! [[ $(docker ps -q --filter name="^/${container}$") ]] \
			&& missing_containers+=( $container )
	done

	[[ -z ${old_images_to_delete[0]} ]] && [[ -z ${missing_containers[0]} ]] \
		&& echo -e "\n\e[1m$PRINT_IMAGES_DID_NOT_CHANGE\e[0m" \
		&& rm "${BASE_DIR}"/.image_shas.tmp \
		&& exit 0
}

delete_old_images() {
	if [[ -f "${BASE_DIR}"/.image_shas.tmp ]];then
		source "${BASE_DIR}"/.image_shas.tmp
	else
		echo -en "\n\e[31m$PRINT_COULD_NOT_FIND_IMAGE_DIGEST\n$PRINT_EXITING\e[0m"
		return
	fi

	[[ -z ${old_images_to_delete[0]} ]] \
		&& return

	prompt_confirm "$PRINT_PROMPT_DELETE_OLD_IMAGES"
	if [[ $? == 0 ]];then
		echo ""
		for image in "${old_images_to_delete[@]}";do
				echo -en "\e[1m$PRINT_DELETING\e[0m $image"
				docker rmi $image >/dev/null
				exit_response
		done
		for image in ${unchanged_images_to_keep[@]};do
			echo -en "\e[1m$PRINT_KEEPING\e[0m $image $PRINT_DID_NOT_CHANGE"
		done
		echo ""
	fi
	rm "${BASE_DIR}"/.image_shas.tmp
}

create_volumes() {
	if [[ ${volumes[@]} && ! ${DOCKER_COMPOSE} ]];then
		echo -e "\n\e[1m$PRINT_CREATING_VOLUMES\e[0m"
		for volume in "${!volumes[@]}";do
			[[ ! $(docker volume ls -q --filter name=^${volume}$) ]] \
				&& echo -en "- $volume" \
				&& docker volume create $volume >/dev/null \
				&& exit_response \
				|| echo "- $volume $PRINT_ALREADY_EXISTS"
		done
	fi
}

wait_for_db() {
	if ! docker exec ${FUNCNAME[1]//_/-} mysqladmin ping -h"127.0.0.1" --silent;then
		while ! docker exec ${FUNCNAME[1]//_/-} mysqladmin ping -h"127.0.0.1" --silent;do
			sleep 1
		done
	fi
}
