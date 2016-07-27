#!/usr/bin/env bash

# Change working directory
cd -- "$(
  dirname "${0}"
)"

source install.conf

# Abort if not run by root user or with sudo
if [[ ${EUID} -ne 0 ]]; then
	printf -- \
		"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
		'Please run as root.'
	exit 1
fi

if [[ -z ${CHROOT_DIRECTORY} ]]; then
	printf -- \
		"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
		'ERROR: CHROOT_DIRECTORY not set.'
	exit 1
elif [[ ! -d ${CHROOT_DIRECTORY} ]]; then
	printf -- \
		"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
		'ERROR: CHROOT_DIRECTORY not a valid directory.'
	exit 1
fi

function systemd_install ()
{

	declare -A COMMAND_PATHS=(
		[journalctl]=/usr/bin/journalctl
		[systemctl]=/usr/bin/systemctl
	)

	if [[ ${CHROOT_DIRECTORY} == / ]]; then
		for COMMAND in "${!COMMAND_PATHS[@]}"; do
			if ! command -v ${COMMAND} &> /dev/null; then
				printf -- \
					"%s Command %s not available - exiting.\n" \
					"${COLOUR_NEGATIVE}--->${COLOUR_RESET}" \
					${COMMAND}
				exit 1
			fi

			printf -v \
				${COMMAND} \
				-- '%s' \
				${COMMAND_PATHS[${COMMAND}]}
		done
	else
		for COMMAND in "${!COMMAND_PATHS[@]}"; do
			if [[ ! -f ${CHROOT_DIRECTORY%*/}/${COMMAND_PATHS[${COMMAND}]} ]]; then
				printf -- \
					"%s Command %s not available - exiting.\n" \
					"${COLOUR_NEGATIVE}--->${COLOUR_RESET}" \
					${COMMAND}
				exit 1
			fi

			printf -v \
				${COMMAND} \
				-- 'chroot %s %s' \
				${CHROOT_DIRECTORY} \
				${COMMAND_PATHS[${COMMAND}]}
		done
	fi

	printf -- \
		"---> Installing %s\n" \
		${SERVICE_UNIT_INSTANCE_NAME}

	# Copy systemd unit-files into place.
	cat \
		${SERVICE_UNIT_INSTALL_TEMPLATE_NAME} \
		> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_TEMPLATE_NAME}

	sed \
		-e "s~{{SERVICE_UNIT_NAME}}~${SERVICE_UNIT_NAME}~g" \
		-e "s~{{SERVICE_UNIT_GROUP}}~${SERVICE_UNIT_GROUP}~g" \
		${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_NAME} \
		> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME}

	${systemctl} daemon-reload
	${systemctl} enable -f ${SERVICE_UNIT_INSTANCE_NAME}
	${systemctl} enable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
	${systemctl} restart ${SERVICE_UNIT_INSTANCE_NAME} &
	PIDS[0]=${!}

	# Tail the systemd unit logs unitl installation completes
	${journalctl} -fn 0 -u ${SERVICE_UNIT_INSTANCE_NAME} &
	PIDS[1]=${!}

	# Wait for installtion to complete
	[[ -n ${PIDS[0]} ]] && wait ${PIDS[0]}

	# Allow time for the container bootstrap to complete
	sleep ${SERVICE_UNIT_INSTALL_TIMEOUT}
	kill -15 ${PIDS[1]}
	wait ${PIDS[1]} 2> /dev/null

	if ${systemctl} -q is-active ${SERVICE_UNIT_INSTANCE_NAME} \
		&& ${systemctl} -q is-active ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}; then
		printf -- \
			"---> Service unit is active: %s\n" \
			"$(
				${systemctl} list-units --type=service \
				| grep "^[ ]*${SERVICE_UNIT_INSTANCE_NAME}"
			)"
		printf -- \
			"---> Service register unit is active: %s\n" \
			"$(
				${systemctl} list-units --type=service \
				| grep "^[ ]*${SERVICE_UNIT_REGISTER_INSTANCE_NAME}"
			)"
		printf -- \
			"${COLOUR_POSITIVE} --->${COLOUR_RESET} %s\n" \
			'Install complete'
	else
		printf -- \
			"\nService status:\n"
		${systemctl} status -ln 50 ${SERVICE_UNIT_INSTANCE_NAME}
		printf -- \
			"\n${COLOUR_NEGATIVE} --->${COLOUR_RESET} %s\n" \
			'Install error'
	fi

}

systemd_install
