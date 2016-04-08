#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]] ; then
	cd ${DIR_PATH}
fi

source run.conf

SERVICE_UNIT_LONG_NAME=${SERVICE_UNIT_LONG_NAME:-ssh.pool-1.1.1}
SERVICE_UNIT_FILE_NAME=${SERVICE_UNIT_FILE_NAME:-${SERVICE_UNIT_LONG_NAME}@2020.service}

# Copy systemd definition into place and enable it.
sudo cp ${SERVICE_UNIT_FILE_NAME} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable -f /etc/systemd/system/${SERVICE_UNIT_FILE_NAME}

# Stop the service and remove containers.
sudo systemctl stop ${SERVICE_UNIT_FILE_NAME} &> /dev/null

# Terminate the container(s)
sudo docker rm -f volume-config.${SERVICE_UNIT_LONG_NAME} &> /dev/null
sudo docker rm -f ${SERVICE_UNIT_LONG_NAME} &> /dev/null

printf -- "---> Installing %s\n" ${SERVICE_UNIT_FILE_NAME}
sudo systemctl start ${SERVICE_UNIT_FILE_NAME} &
PIDS[0]=${!}
PIDS[1]=$(ps --ppid ${PIDS[0]} -o pid=)

# Tail the systemd unit logs unitl installation completes
sudo journalctl -fu ${SERVICE_UNIT_FILE_NAME} &
PIDS[2]=${!}
PIDS[3]=$(ps --ppid ${PIDS[2]} -o pid=)

# Wait for installtion to complete
[[ -n ${PIDS[1]} ]] && wait ${PIDS[1]}
[[ -n ${PIDS[0]} ]] && wait ${PIDS[0]}

# Allow time for the container bootstrap to complete
sleep 5
sudo kill -15 ${PIDS[2]} ${PIDS[3]}

if sudo systemctl -q is-active ${SERVICE_UNIT_FILE_NAME}; then
	printf -- " ---> %s\n${COLOUR_POSITIVE} --->${COLOUR_RESET} %s\n" ${SERVICE_UNIT_FILE_NAME} 'Install complete'
else
	printf -- "\nService status:\n"
	sudo systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n${COLOUR_NEGATIVE} --->${COLOUR_RESET} %s\n" 'Install error'
fi
