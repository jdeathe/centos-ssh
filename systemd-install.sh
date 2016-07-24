#!/usr/bin/env bash

# Change working directory
cd -- "$(
  dirname "${0}"
)"

source run.conf

# Abort if systemd not supported
if ! type -p systemctl &> /dev/null; then
	printf -- "${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'Systemd installation not supported.'
	exit 1
fi

# Abort if not run by root user or with sudo
if [[ ${EUID} -ne 0 ]]; then
	printf -- "${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'Please run as root.'
	exit 1
fi

printf -- "---> Installing %s\n" ${SERVICE_UNIT_INSTANCE_NAME}

# Copy systemd unit-files into place.
cp ${SERVICE_UNIT_TEMPLATE_NAME} /etc/systemd/system/
cp ${SERVICE_UNIT_REGISTER_TEMPLATE_NAME} /etc/systemd/system/

systemctl daemon-reload

systemctl enable -f ${SERVICE_UNIT_INSTANCE_NAME}
systemctl enable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
systemctl restart ${SERVICE_UNIT_INSTANCE_NAME} &
PIDS[0]=${!}

# Tail the systemd unit logs unitl installation completes
journalctl -fn 0 -u ${SERVICE_UNIT_INSTANCE_NAME} &
PIDS[1]=${!}

# Wait for installtion to complete
[[ -n ${PIDS[0]} ]] && wait ${PIDS[0]}

# Allow time for the container bootstrap to complete
sleep 5
kill -15 ${PIDS[1]}
wait ${PIDS[1]} 2> /dev/null

if systemctl -q is-active ${SERVICE_UNIT_INSTANCE_NAME} && systemctl -q is-active ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}; then
	printf -- "---> Service unit is active: %s\n" "$(systemctl list-units --type=service | grep "^[ ]*${SERVICE_UNIT_INSTANCE_NAME}")"
	printf -- "---> Service register unit is active: %s\n" "$(systemctl list-units --type=service | grep "^[ ]*${SERVICE_UNIT_REGISTER_INSTANCE_NAME}")"
	printf -- "${COLOUR_POSITIVE} --->${COLOUR_RESET} %s\n" 'Install complete'
else
	printf -- "\nService status:\n"
	systemctl status -ln 50 ${SERVICE_UNIT_INSTANCE_NAME}
	printf -- "\n${COLOUR_NEGATIVE} --->${COLOUR_RESET} %s\n" 'Install error'
fi
