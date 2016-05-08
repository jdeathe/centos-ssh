#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]] ; then
	cd ${DIR_PATH}
fi

if [[ ${EUID} -ne 0 ]]; then
	echo "Please run as root."
	exit 1
fi

source run.conf

is_coreos_distribution ()
{
	if [[ -n $( [[ -e /etc/os-release ]] && grep ^ID=coreos$ /etc/os-release ) ]]; then
		return 0
	fi

	return 1
}

replace_etcd_service_name ()
{
	local FILE_PATH=${1}

	if [[ -z ${FILE_PATH} ]]; then
		echo "Path to the service's unit file is required."
		return 1
	fi

	if ! [[ -s ${FILE_PATH} ]]; then
		echo "Unit file not found."
		return 1
	fi

	# CoreOS uses etcd.service and etcd2.service for version 1 and 2 of ETCD 
	# respectively but has both available. Use etcd2.service in the systemd 
	# unit file and rename for other distributions where etcd.service is the 
	# only name used.
	if ! is_coreos_distribution; then
		echo "---> Not a CoreOS distribution."
		echo " ---> Renaming etcd2.service to etcd.service in unit file."
		sed -i -e 's~etcd2.service~etcd.service~g' ${FILE_PATH}
	fi
}

SERVICE_UNIT_LONG_NAME=${SERVICE_UNIT_LONG_NAME:-ssh.pool-1.1.1}
SERVICE_UNIT_FILE_NAME=${SERVICE_UNIT_FILE_NAME:-${SERVICE_UNIT_LONG_NAME}@2020.service}

# Copy systemd definition into place and enable it.
cp ${SERVICE_UNIT_FILE_NAME} /etc/systemd/system/
replace_etcd_service_name /etc/systemd/system/${SERVICE_UNIT_FILE_NAME}
systemctl daemon-reload
systemctl enable -f /etc/systemd/system/${SERVICE_UNIT_FILE_NAME}

# Stop the service and remove containers.
systemctl stop ${SERVICE_UNIT_FILE_NAME} &> /dev/null

# Terminate the container(s)
docker rm -f volume-config.${SERVICE_UNIT_LONG_NAME} &> /dev/null
docker rm -f ${SERVICE_UNIT_LONG_NAME} &> /dev/null

printf -- "---> Installing %s\n" ${SERVICE_UNIT_FILE_NAME}
systemctl start ${SERVICE_UNIT_FILE_NAME} &
PIDS[0]=${!}

# Tail the systemd unit logs unitl installation completes
journalctl -fu ${SERVICE_UNIT_FILE_NAME} &
PIDS[1]=${!}

# Wait for installtion to complete
[[ -n ${PIDS[0]} ]] && wait ${PIDS[0]}

# Allow time for the container bootstrap to complete
sleep 5
kill -15 ${PIDS[1]}

if systemctl -q is-active ${SERVICE_UNIT_FILE_NAME}; then
	printf -- " ---> %s\n${COLOUR_POSITIVE} --->${COLOUR_RESET} %s\n" ${SERVICE_UNIT_FILE_NAME} 'Install complete'
else
	printf -- "\nService status:\n"
	systemctl status -l ${SERVICE_UNIT_FILE_NAME}
	printf -- "\n${COLOUR_NEGATIVE} --->${COLOUR_RESET} %s\n" 'Install error'
fi
