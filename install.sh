#!/usr/bin/env bash

# Change working directory
cd -- "$(
  dirname "${0}"
)"

source install.conf

INSTALL_SERVICE_REGISTER_ENABLED=false

function systemd_install ()
{

	declare -a COMMAND_PATHS=(
		'/usr/bin/systemctl'
		'/usr/bin/journalctl'
	)

	if [[ ${CHROOT_DIRECTORY} == / ]]; then
		for COMMAND_PATH in "${COMMAND_PATHS[@]}"; do
			COMMAND=${COMMAND_PATH##*/}
			if ! command -v ${COMMAND} &> /dev/null; then
				printf -- \
					"${COLOUR_NEGATIVE}--->${COLOUR_RESET} ERROR: Missing required command: %s\n" \
					${COMMAND_PATH}
				exit 1
			fi

			printf -v \
				${COMMAND} \
				-- '%s' \
				${COMMAND_PATH}
		done
	else
		for COMMAND_PATH in "${COMMAND_PATHS[@]}"; do
			COMMAND=${COMMAND_PATH##*/}
			if [[ ! -f ${CHROOT_DIRECTORY%*/}/${COMMAND_PATH} ]]; then
				printf -- \
					"${COLOUR_NEGATIVE}--->${COLOUR_RESET} ERROR: Missing required command: %s\n" \
					${COMMAND_PATH}
				exit 1
			fi

			printf -v \
				${COMMAND} \
				-- 'chroot %s %s' \
				${CHROOT_DIRECTORY} \
				${COMMAND_PATH}
		done
	fi

	printf -- \
		"---> Installing %s\n" \
		${SERVICE_UNIT_INSTANCE_NAME}

	# Copy systemd unit-files into place.
	cat \
		${SERVICE_UNIT_INSTALL_TEMPLATE_NAME} \
		> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_TEMPLATE_NAME}

	if [[ ${INSTALL_SERVICE_REGISTER_ENABLED} == true ]]; then
		sed \
			-e "s~{{SERVICE_UNIT_NAME}}~${SERVICE_UNIT_NAME}~g" \
			-e "s~{{SERVICE_UNIT_GROUP}}~${SERVICE_UNIT_GROUP}~g" \
			${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_NAME} \
			> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME}
	else
		# Remove register service unit template if found on host.
		if [[ -f ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME} ]]; then
			rm -f ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME}
		fi
	fi

	${systemctl} daemon-reload
	${systemctl} enable -f ${SERVICE_UNIT_INSTANCE_NAME}
	if [[ ${INSTALL_SERVICE_REGISTER_ENABLED} == true ]]; then
		${systemctl} enable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
	else
		${systemctl} disable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
	fi
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
		&& ( \
			[[ ${INSTALL_SERVICE_REGISTER_ENABLED} != true ]] \
			|| ${systemctl} -q is-active ${SERVICE_UNIT_REGISTER_INSTANCE_NAME} \
		); then

		printf -- \
			"---> Service unit is active: %s\n" \
			"$(
				${systemctl} list-units --type=service \
				| grep "^[ ]*${SERVICE_UNIT_INSTANCE_NAME}"
			)"

		if [[ ${INSTALL_SERVICE_REGISTER_ENABLED} == true ]]; then
			printf -- \
				"---> Service register unit is active: %s\n" \
				"$(
					${systemctl} list-units --type=service \
					| grep "^[ ]*${SERVICE_UNIT_REGISTER_INSTANCE_NAME}"
				)"
		else
			printf -- \
				"---> Service register unit is disabled (not installed)\n"
		fi

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

function usage ()
{
	cat <<-EOF
	Usage: $(basename $0) [OPTIONS]

	Options:
	  -h --help                  Show this help.
	  -m --manager=MANAGER       Container manager (docker, systemd).
	  -r --register              Enable the etcd registration service.
	EOF

  exit 1
}

# Abort if not run by root user or with sudo
if [[ ${EUID} -ne 0 ]]; then
	printf -- \
		"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
		'Run as root or use: sudo -E <command>'
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

# Display usage and exit if no arguments provided.
if [[ ${#} -eq 0 ]]; then
  INSTALL_SERVICE_MANAGER_TYPE=docker
fi

# Parse install options
while [[ ${#} -gt 0 ]]; do
	case "${1}" in
		-h|--help)
			usage
			;;
		-m)
			if [[ -z ${2:-} ]]; then
				usage
			fi

			INSTALL_SERVICE_MANAGER_TYPE="${2}"
			shift 2
			;;
		--manager=*)
			if [[ ${1#*=} != docker ]] && [[ ${1#*=} != systemd ]]; then
				usage
			fi

			INSTALL_SERVICE_MANAGER_TYPE="${1#*=}"
			shift 1
			;;
		-r|--register)
			INSTALL_SERVICE_REGISTER_ENABLED=true
			shift 1
			;;
		*)
			printf -- \
				"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s (%s)\n" \
				'ERROR: Unkown option' \
				"${1}"
			usage
			;;
	esac
done

# Run install for selected service manager
case ${INSTALL_SERVICE_MANAGER_TYPE} in
	systemd)
		systemd_install
		;;
	docker|*)
		make install start
		;;
esac
