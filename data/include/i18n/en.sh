export PRINT_MISSING_DOCKER="\e[1mCould not find docker.\e[3m\n\nMost systems can install Docker by running:\n\nwget -qO- https://get.docker.com/ | sh"


# helper_function
export PRINT_FAIL_MESSAGE="[failed]"
export PRINT_DONE_MESSAGE="[Done.]"
export PRINT_NOT_FOUND_MESSAGE="[not found]"
export PRINT_NOT_RUNNING_MESSAGE="[not running]"
export PRINT_STOPPED_MESSAGE="[stopped]"
export PRINT_ALREADY_RUNNING="[already running]"
export PRINT_ALREADY_EXISTS="[already exists]"
export PRINT_INVALID_OPTION_MESSAGE="[invalid option]"
export PRINT_INVALID_PATH_MESSAGE="[invalid PATH]"
export PRINT_SOMETHING_WENT_WRONG="Something went wrong. Exiting."
export PRINT_STATUS="Status"
export PRINT_RESTORE="Restore"
export PRINT_EXIT="Exit"
export PRINT_EXITING="Exiting"
export PRINT_DELETING="Deleting"
export PRINT_REMOVE="Remove"
export PRINT_KEEPING="Keeping"
export PRINT_DID_NOT_CHANGE="[did not change]"
export PRINT_ALL="All"
export PRINT_INSTALLED="Installed"
export PRINT_GREEN="Green"
export PRINT_CONFIGURED="Configured"
export PRINT_ORANGE="Orange"

export PRINT_PROMPT_CONFIRM_SHURE="Are you sure?"
export PRINT_PROMPT_CONFIRM_QUESTION="Continue?"
export PRINT_PROMPT_CONFIRM_KEEP_VOLUMES="Keep volumes?"
export PRINT_EXITING="Exiting..."
export PRINT_PROMPT_CONFIRM_YES="[Yes]"
export PRINT_PROMPT_CONFIRM_NO="[No]"
export PRINT_PROMPT_CONFIRM_ERROR="[Invalid Input]"

export PRINT_VALIDATE_FQDN_USE="is already in use"
export PRINT_VALIDATE_FQDN_INVALID="is not a valid domain"

export PRINT_SERVICE_MANAGE_MESSAGE="Please select the service you want to manage"

# init.menu
export PRINT_DESTROY_ALL="Destroy everything"
export PRINT_RESET_DOCKERBUNKER="Reset dockerbunker to its initial state"

export PRINT_CONATIENRS="Container(s)"
export PRINT_VOLUMES="Volume(s)"
export PRINT_NGINX_CONFIG_FILES="nginx configuration file(s)"
export PRINT_ENVIRONMENT_FILES="environment file(s)"
export PRINT_SSL_CERT="SSL Certificates"

export PRINT_START_ALL_STOPPED_CONTAINERS="Start all stopped containers"
export PRINT_STOP_ALL_RUNNING_CONTAINERS="Stop all running containers"
export PRINT_START_NGINX_CONTAINER="Start nginx container"
export PRINT_STOP_NGINX_CONTAINER="Stop nginx container"
export PRINT_RESTART_NGINX_CONTAINER="Restart nginx container"
export PRINT_RESTART_ALL_CONTAINERS="Restart all containers"
export PRINT_DESTROY_EVERYTHING="Destroy everything"

# menu_function_server
export PRINT_RESTART_NGINX="Restarting nginx container"
export PRINT_RESTART_NGINX_TEST_ERROR="\`nginx -t\` failed. Trying to add missing containers to dockerbunker-network."
export PRINT_RESTART_NGINX_TEST_ERROR_AGAIN="\`nginx -t\` failed again. Please resolve issue and try again."

export PRINT_START_NGINX="Starting nginx container"
export PRINT_STOP_NGINX="Stopping nginx container"

export PRINT_DEACTIVATE_NGINX_CONF="Deactivating nginx configuration"
export PRINT_REMOVE_NGINX_CONF="Removing nginx configuration"
export PRINT_REMOVE_NETWORKS="Removing networks"

# menu_functions_certificate
export PRINT_REMOVE_SSL_CERTIFICATE="Removing SSL Certificates"
export PRINT_RENEW_LE_CERT="Renew Let's Encrypt certificate"

export PRINT_GENERATE_SS_CERT="Generate self-signed certificate"
export PRINT_OPTAIN_LS_CERT="Obtain Let's Encrypt certificate"

# menu_function_service
export PRINT_STARTING_CONTAINERS="Starting containers"
export PRINT_RESTARTING_CONTAINERS="Restarting containers"
export PRINT_STOPING_CONTAINERS="Stopping containers"
export PRINT_REMOVE_CONTAINERS="Removing containers"
export PRINT_REMOVE_VOLUMES="Removing volumes"
export PRINT_REMOVE_ALL_IMAGES="Remove all images?"
export PRINT_REMOVING_IMAGES="Removing images"
export PRINT_REMOVING="Removing"
export PRINT_DECOMPRESSING="Decompressing"
export PRINT_REMVEHTML_DIRECTORY="Remove HTML directory"

# menu_function
export PRINT_CONTAINER_MISSING="container missing"
export PRINT_RETURN_TO_PREVIOUSE_MENU="Return to previous menu"

export PRINT_MENU_REINSTALL_SERVICE="Reinstall service"
export PRINT_MENU_BACKUP_SERVICE="Backup Service"
export PRINT_MENU_UPGRADE_IMAGE="Upgrade Image(s)"
export PRINT_MENU_DESTROY_SERVICE="Destroy"
export PRINT_MENU_START_CONTAINERS="Start container(s)"
export PRINT_MENU_RESTART_CONTAINERS="Restart container(s)"
export PRINT_MENU_STOP_CONTAINERS="Stop container(s)"
export PRINT_MENU_RESTORE_SERVICE="Restore Service"
export PRINT_MENU_RESTORE_MISSING_CONTAINER="Restore missing containers"
export PRINT_MENU_RECONFIGURE_SERVICE="Reconfigure service"
export PRINT_MENU_MANAGE_SITES="Manage Sites"
export PRINT_MENU_CONFIGURE_SITES="Configure Site"
export PRINT_MENU_CONFIGURE_SERVICE="Configure Service"
export PRINT_MENU_SETUP_SERVICE="Setup service"
export PRINT_MENU_REMOVE_SITE="Remove site"
export PRINT_MENU_PRVIOUSE_MENU="Back to previous menu"

export PRINT_CONFIGURE="Configure"
export PRINT_RECONFIGURE="Reconfigure"
export PRINT_SETUP="Setup"
export PRINT_REINSTALL="Reinstall"
export PRINT_RESTROING_CONTAINERS="Restoring containers"
export PRINT_UPGRADE="Upgrade"
export PRINT_RESTART="Restart"
export PRINT_START="Start"
export PRINT_DESTROY="Destroy"
export PRINT_CONTAINERS_ARE_MISSING="The following containers are missing"
export PRINT_FOLLWONING_WILL_REMOVED="The following will be removed:"
export PRINT_THE_FOLLOWING_SERVICES_WILL_BE_REMOVED="The following Services will be removed:"
export PRINT_ALL_VOLUMES_WILL_BE_REMOVED="All volumes will be removed. Continue?"
export PRINT_NO_EXISTING_SITE_FOUND="No existing sites found"
export PRINT_NO_ENVORINMENT_FILE_FOUND="No environment file found for: "
export PRINT_PLEASE_CHOOSE_A_NUMBER="Please choose a number from 1 to"
export PRINT_COMPESSING_VOLUMES="Compressing volumes"
export PRINT_BACKING_UP_CONFIG_FILES="Backing up configuration files"
export PRINT_BACKING_UP_CERT="Backing up SSL certificate"
export PRINT_BACKING_UP_NGINX_CONF="Backing up nginx configuration"
export PRINT_BACKING_UP_ENV_FILE="Backing up environemt file(s)"
export PRINT_COULD_NOT_FIND_ENV_FILE="Could not find environment file(s) for"
export PRINT_COOSE_A_BACKUP="Please choose a backup"
export PRINT_COULD_NOT_FIND="Could not find"
export PRINT_RESTORING_CONFIGURATION="Restoring configuration files"
export PRINT_RESTORING_NGINX_CONF="Restoring nginx configuration"
export PRINT_RESTORING_SSL_CERT="Restoring SSL certificate"
export PRINT_RESTORING_ENV="Restoring environemt file(s)"
export PRINT_CHECKING_SERVICE_STATUS="Checking service status"

# setup_certificate_functions

export PRINT_PROMPT_CONFIRM_USE_LETSENCRYPT="Use Letsencrypt instead of a self-signed certificate?"
export PRINT_ENTER_LETSENCRYPT_EMAIL="Enter E-mail Adress for Let's Encrypt:"
export PRINT_ENTER_LETSENCRYPT_EMAIL_GLOBAL="Use this address globally for every future service configured to obtain a Let's Encrypt certificate?"
export PRINT_GENERATING_SSL_CERT="Generating self-signed certificate for"
export PRINT_INCLUDE_OTHER_DOMAINS_IN_CERT="Include other domains in certificate besides"
export PRINT_CERT_DOMAIN_INVALID="Please enter a valid domain!"
export PRINT_CERT_DOMAIN_INPUT_MESSGE="Enter domains, separated by spaces"
export PRINT_CONTAINER_NOT_RUNNING="container not running. Exiting"
export PRINT_SYMLINK_LETSENCRYPT_CERT="Symlinking letsencrypt certificate"


# setup_docker_functions
export PRINT_PULLING="Pulling"
export PRINT_PULLING_NEW_IMAGES="Pulling new images"
export PRINT_COULD_NOT_FIND_IMAGE_DIGEST="Could not find digests of current images."
export PRINT_TAKING_DOWN_SERVICE="Taking down:"
export PRINT_BRINGIN_UP_SERVICE="Bringing up:"
export PRINT_IMAGES_DID_NOT_CHANGE="Image(s) did not change."
export PRINT_PROMPT_DELETE_OLD_IMAGES="Delete all old images?"
export PRINT_CREATING_VOLUMES="Creating volumes"

# setup_server_function
export PRINT_PROMPT_CONFIRM_USE_DEFAULT_NGINX_CONF="Use default Service Nginx.Config File?"
export PRINT_PROMPT_CONFIRM_SET_NEW_NGINX_SERVICE_PATH="Set new Service Config Path"
export PRINT_MOVING_NGINX_CONFIG="Moving nginx configuration in place"
export PRINT_NGINX_CONFIG_ISSUE="Nginx configuration file could not be found. Exiting."


# menus
# export PRINT_MENU_TASK_DESTROY_SERVICE="destroy_service"

# certbot
export PRINT_CERTBOT_RESTART_SERVER_SUCCESS="Successfully restarted nginx-dockerbunker"
export PRINT_CERTBOT_RESTART_SERVER_ERROR="Restart of nginx-dockerbunker failed"
