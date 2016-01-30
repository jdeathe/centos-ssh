#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]] ; then
	cd ${DIR_PATH}
fi

source run.conf

have_docker_container_name ()
{
	local NAME=$1

	if [[ -z ${NAME} ]]; then
		return 1
	fi

	if [[ -n $(docker ps -a | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	fi

	return 1
}

have_docker_image ()
{
	local NAME=$1

	if [[ -n $(show_docker_image ${NAME}) ]]; then
		return 0
	fi

	return 1
}

is_docker_container_name_running ()
{
	local NAME=$1

	if [[ -z ${NAME} ]]; then
		return 1
	fi

	if [[ -n $(docker ps | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	fi

	return 1
}

remove_docker_container_name ()
{
	local NAME=$1

	if have_docker_container_name ${NAME}; then
		if is_docker_container_name_running ${NAME}; then
			echo "Stopping container ${NAME}"
			docker stop ${NAME} &> /dev/null

			if [[ ${?} -ne 0 ]]; then
				return 1
			fi
		fi
		echo "Removing container ${NAME}"
		docker rm ${NAME} &> /dev/null

		if [[ ${?} -ne 0 ]]; then
			return 1
		fi
	fi
}

show_docker_image ()
{
	local NAME=$1
	local NAME_PARTS=(${NAME//:/ })

	# Set 'latest' tag if no tag requested
	if [[ ${#NAME_PARTS[@]} == 1 ]]; then
		NAME_PARTS[1]='latest'
	fi

	docker images | \
		awk \
			-v FS='[ ]+' \
			-v pattern="^${NAME_PARTS[0]}[ ]+${NAME_PARTS[1]} " \
			'$0 ~ pattern { print $0; }'
}

SERVICE_UNIT_LONG_NAME=${SERVICE_UNIT_LONG_NAME:-ssh.pool-1.1.1}
SERVICE_UNIT_FILE_NAME=${SERVICE_UNIT_FILE_NAME:-${SERVICE_UNIT_LONG_NAME}@2020.service}

# Stop the service and remove containers.
sudo systemctl stop ${SERVICE_UNIT_FILE_NAME} &> /dev/null
remove_docker_container_name volume-config.${SERVICE_UNIT_LONG_NAME}
remove_docker_container_name ${SERVICE_UNIT_LONG_NAME}

# Copy systemd definition into place and enable it.
sudo cp ${SERVICE_UNIT_FILE_NAME} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/${SERVICE_UNIT_FILE_NAME}

printf -- "\nInstalling %s\n" ${SERVICE_UNIT_FILE_NAME}
sudo systemctl restart ${SERVICE_UNIT_FILE_NAME} &
INSTALL_PID=${!}

# Tail the systemd unit logs unitl installation completes.
journalctl -fu ${SERVICE_UNIT_FILE_NAME} &
LOG_PID=${!}
wait ${INSTALL_PID}
INSTALL_STATUS=${?}
kill -9 ${LOG_PID}

printf -- "\nService status:\n"
if [[ ${INSTALL_STATUS} -eq 0 ]]; then
	sudo systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n ${COLOUR_POSITIVE}--->${COLOUR_RESET} %s\n" 'Install complete'
else
	sudo systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n ${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'ERROR'
fi
