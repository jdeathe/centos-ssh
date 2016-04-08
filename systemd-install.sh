#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]] ; then
	cd ${DIR_PATH}
fi

source run.conf
source docker-helpers.sh

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
# Allow time for the container bootstrap to complete
sleep 5
kill -9 ${LOG_PID}

printf -- "\nService status:\n"
if [[ ${INSTALL_STATUS} -eq 0 ]]; then
	sudo systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n ${COLOUR_POSITIVE}--->${COLOUR_RESET} %s\n" 'Install complete'
else
	sudo systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n ${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'ERROR'
fi
