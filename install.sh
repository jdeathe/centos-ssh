#!/usr/bin/env bash

# Change working directory
cd -- "$(
  dirname "${0}"
)"

source environment.sh
source default.sh

source install.conf

# UI constants
COLOUR_NEGATIVE='\033[1;31m'
COLOUR_POSITIVE='\033[1;32m'
COLOUR_RESET='\033[0m'
CHARACTER_STEP='--->'
PREFIX_STEP=$(
	printf -- \
		'%s ' \
		"${CHARACTER_STEP}"
)
PREFIX_SUB_STEP=$(
	printf -- \
		' %s ' \
		"${CHARACTER_STEP}"
)
PREFIX_STEP_NEGATIVE=$(
	printf -- \
		'%b%s%b' \
		"${COLOUR_NEGATIVE}" \
		"${PREFIX_STEP}" \
		"${COLOUR_RESET}"
)
PREFIX_STEP_POSITIVE=$(
	printf -- \
		'%b%s%b' \
		"${COLOUR_POSITIVE}" \
		"${PREFIX_STEP}" \
		"${COLOUR_RESET}"
)
PREFIX_SUB_STEP_NEGATIVE=$(
	printf -- \
		'%b%s%b' \
		"${COLOUR_NEGATIVE}" \
		"${PREFIX_SUB_STEP}" \
		"${COLOUR_RESET}"
)
PREFIX_SUB_STEP_POSITIVE=$(
	printf -- \
		'%b%s%b' \
		"${COLOUR_POSITIVE}" \
		"${PREFIX_SUB_STEP}" \
		"${COLOUR_RESET}"
)

INSTALL_SERVICE_REGISTER_ENABLED=false

function docker_prerequisites ()
{

	docker=''

	declare -a local DOCKER_PATHS=(
		'/usr/bin/docker'
		'/usr/local/bin/docker'
	)

	# Set the docker binary command
	if [[ ${CHROOT_DIRECTORY} == / ]]; then
		if ! command -v docker &> /dev/null; then
			printf -- \
				"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
				'ERROR: Missing docker binary'
			exit 1
		fi

		printf -v \
			docker \
			-- '%s' \
			$(command -v docker)
	else
		for DOCKER_PATH in "${DOCKER_PATHS[@]}"; do
			if [[ -f ${CHROOT_DIRECTORY%*/}/${DOCKER_PATH} ]]; then
				printf -v \
					docker \
					-- 'chroot %s %s' \
					${CHROOT_DIRECTORY} \
					${DOCKER_PATH}
				break
			fi
		done

		if [[ -z ${docker} ]]; then
			printf -- \
				"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
				'ERROR: Missing docker binary'
			exit 1
		fi
	fi

	# Test docker connection
	if [[ -z $(${docker} info) ]]; then
		printf -- \
			"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
			'ERROR: Docker failed to connect to host.'
		exit 1
	fi

	if [[ -z ${DOCKER_NAME} ]]; then
		printf -- \
			"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
			'ERROR: DOCKER_NAME not set.'
		exit 1
	fi
}

function docker_require_container ()
{

	if [[ -z $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]]; then \
		echo "${PREFIX_STEP_NEGATIVE} This operation requires the ${DOCKER_NAME} docker container."; \
		exit 1; \
	fi

}

function docker_require_container_not ()
{

	if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]]; then \
		echo "${PREFIX_STEP_NEGATIVE} This operation requires the ${DOCKER_NAME} docker container be removed (or renamed)."; \
		echo "${PREFIX_SUB_STEP} Try removing it with: docker rm -f ${DOCKER_NAME}"; \
		exit 1; \
	fi

}

function docker_require_container_not_status_paused ()
{

	if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=paused") ]]; then \
		echo "${PREFIX_STEP_NEGATIVE} This operation requires the ${DOCKER_NAME} docker container to be unpaused."; \
		echo "${PREFIX_SUB_STEP} Try unpausing it with: docker ${DOCKER_NAME} unpause"; \
		exit 1; \
	fi

}

function docker_terminate ()
{

	if [[ -z $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]]; then \
		echo "${PREFIX_STEP} Container termination skipped"; \
	else \
		echo "${PREFIX_STEP} Terminating container"; \
		if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=paused") ]]; then \
			echo "${PREFIX_SUB_STEP} Unpausing container"; \
			${docker} unpause ${DOCKER_NAME} 1> /dev/null; \
		fi; \
		if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=running") ]]; then \
			echo "${PREFIX_SUB_STEP} Stopping container"; \
			${docker} stop ${DOCKER_NAME} 1> /dev/null; \
		fi; \
		if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]]; then
			echo "${PREFIX_SUB_STEP} Removing container"
			if [[ ${CHROOT_DIRECTORY} != / ]]; then
				CONTAINER_ID=$(
					${docker} inspect --format="{{.Id}}" ${DOCKER_NAME}
				)
				CONTAINER_SHM_MOUNT=$(
					find \
						${CHROOT_DIRECTORY%*/}/var/lib/docker/containers/${CONTAINER_ID} \
						-type d \
						-name "shm" \
						2> /dev/null
				)

				if [[ -n ${CONTAINER_ID} ]] && [[ -n ${CONTAINER_SHM_MOUNT} ]]; then
					echo "${PREFIX_SUB_STEP} Unmounting container id: ${CONTAINER_ID}"
					umount ${CHROOT_DIRECTORY%*/}/var/lib/docker/containers/${CONTAINER_ID}/shm
				fi
			fi
			${docker} rm -f ${DOCKER_NAME} 1> /dev/null
		fi
		if [[ -z $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]] \
			&& [[ -z $(find ${CHROOT_DIRECTORY%*/}/var/lib/docker/containers -type d -name "${CONTAINER_ID}" 2> /dev/null) ]]; then \
			echo "${PREFIX_SUB_STEP_POSITIVE} Container terminated"; \
		else \
			echo "${PREFIX_SUB_STEP_NEGATIVE} Container termination failed"; \
			exit 1; \
		fi; \
	fi

}

function docker_create ()
{

	docker_require_container_not

	echo "${PREFIX_STEP} Creating container"

	(
		eval "set -x; \
			${docker} create \
			${DOCKER_CONTAINER_PARAMETERS} \
			${DOCKER_CONTAINER_PARAMETERS_APPEND} \
			${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
			1> /dev/null;"
	)

	if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=created") ]]; then \
		echo "${PREFIX_SUB_STEP} $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=created")"; \
		echo "${PREFIX_SUB_STEP_POSITIVE} Container created"; \
	else \
		echo "${PREFIX_SUB_STEP_NEGATIVE} Container creation failed"; \
		exit 1; \
	fi

}

function docker_start ()
{
	docker_require_container
	docker_require_container_not_status_paused

	echo "${PREFIX_STEP} Starting container"

	if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}") ]] \
		&& [[ -z $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=running") ]]; then \
		${docker} start ${DOCKER_NAME} 1> /dev/null; \
	fi

	if [[ -n $(${docker} ps -aq --filter "name=${DOCKER_NAME}" --filter "status=running") ]]; then \
		echo "${PREFIX_SUB_STEP_POSITIVE} Container started"; \
	else \
		echo "${PREFIX_SUB_STEP_NEGATIVE} Container start failed"; \
		exit 1; \
	fi
}

function docker_install ()
{
	docker_prerequisites
	docker_terminate
	docker_create
	docker_start
}

function make_install ()
{

	local COMMAND
	declare -a local LOCAL_COMMAND_PATHS=(
		'/usr/bin/make'
	)

	for COMMAND_PATH in "${LOCAL_COMMAND_PATHS[@]}"; do
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

	if [[ -f ./Makefile ]]; then
		make install start
	else
		printf -- \
			"${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" \
			'ERROR: Missing Makefile.'
	fi

}

function systemd_install ()
{

	local COMMAND
	declare -a local COMMAND_PATHS=(
		'/usr/bin/docker'
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
	SERVICE_UNIT_INSTALL_TEMPLATE_PATH=${SERVICE_UNIT_INSTALL_TEMPLATE_NAME}
	if [[ -f /etc/systemd/system/${SERVICE_UNIT_INSTALL_TEMPLATE_NAME} ]]; then
		SERVICE_UNIT_INSTALL_TEMPLATE_PATH=/etc/systemd/system/${SERVICE_UNIT_INSTALL_TEMPLATE_NAME}
	fi

	SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_PATH=${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_NAME}
	if [[ -f /etc/systemd/system/${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_NAME} ]]; then
		SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_PATH=/etc/systemd/system/${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_NAME}
	fi

	cat \
		${SERVICE_UNIT_INSTALL_TEMPLATE_PATH} \
		> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_TEMPLATE_NAME}

	if [[ ${INSTALL_SERVICE_REGISTER_ENABLED} == true ]]; then
		sed \
			-e "s~{{SERVICE_UNIT_NAME}}~${SERVICE_UNIT_NAME}~g" \
			-e "s~{{SERVICE_UNIT_GROUP}}~${SERVICE_UNIT_GROUP}~g" \
			${SERVICE_UNIT_REGISTER_INSTALL_TEMPLATE_PATH} \
			> ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME}
	else
		# Remove register service unit template if found on host.
		if [[ -f ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME} ]]; then
			rm -f ${CHROOT_DIRECTORY%*/}/etc/systemd/system/${SERVICE_UNIT_REGISTER_TEMPLATE_NAME}
		fi
	fi

	# Create drop-in to set environment variables defined at install time.
	if [[ -n ${SERVICE_UNIT_ENVIRONMENT_KEYS} ]]; then

		SYSTEMD_OVERRIDE_DIRECTORY=${CHROOT_DIRECTORY%*/}
		SYSTEMD_OVERRIDE_DIRECTORY+=/etc/systemd/system
		SYSTEMD_OVERRIDE_DIRECTORY+=/${SERVICE_UNIT_TEMPLATE_NAME}.d
		SYSTEMD_OVERRIDE_FILE=10-override.conf

		mkdir -p ${SYSTEMD_OVERRIDE_DIRECTORY}

		cat <<-EOF > ${SYSTEMD_OVERRIDE_DIRECTORY}/${SYSTEMD_OVERRIDE_FILE}
		[Service]
		EOF

		# Set each key and value - escaping any % characters.
		for KEY in ${SERVICE_UNIT_ENVIRONMENT_KEYS}; do
			VALUE="${!KEY//%/%%}"

			# Allow variable expansion for DOCKER_CONTAINER_PARAMETERS_APPEND
			if [[ ${KEY} == DOCKER_CONTAINER_PARAMETERS_APPEND ]]; then
				printf \
					-- 'Environment="%s"\n' \
					"$(
						eval -- \
						echo \
							"${KEY}=${VALUE}"
					)" \
					>> ${SYSTEMD_OVERRIDE_DIRECTORY}/${SYSTEMD_OVERRIDE_FILE}
			else
				printf \
					-- 'Environment="%s=%s"\n' \
					"${KEY}" \
					"${VALUE}" \
					>> ${SYSTEMD_OVERRIDE_DIRECTORY}/${SYSTEMD_OVERRIDE_FILE}
			fi
		done

	fi

	${systemctl} daemon-reload
	${systemctl} enable -f ${SERVICE_UNIT_INSTANCE_NAME}
	if [[ ${INSTALL_SERVICE_REGISTER_ENABLED} == true ]]; then
		${systemctl} enable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
	elif ${systemctl} -q is-active ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}; then
		${systemctl} disable -f ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
		${systemctl} stop ${SERVICE_UNIT_REGISTER_INSTANCE_NAME}
	fi

	# Deleting a container from host from a container that has the docker host's
	# root directory volume mounted fails for CentOS hosts. To work around this
	# issue we unmount the shm mount before calling docker rm.
	if [[ ${CHROOT_DIRECTORY} != / ]]; then
		CONTAINER_ID=$(
			${docker} inspect --format="{{.Id}}" ${DOCKER_NAME}
		)
		CONTAINER_SHM_MOUNT=$(
			find \
				${CHROOT_DIRECTORY%*/}/var/lib/docker/containers/${CONTAINER_ID} \
				-type d \
				-name "shm" \
				2> /dev/null
		)

		if [[ -n ${CONTAINER_ID} ]] && [[ -n ${CONTAINER_SHM_MOUNT} ]]; then
			printf -- \
				"---> Unmounting container id: %s\n" \
				${CONTAINER_ID}

			umount ${CHROOT_DIRECTORY%*/}/var/lib/docker/containers/${CONTAINER_ID}/shm
		fi
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
	  -m --manager=MANAGER       Container manager (docker, make, systemd).
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
			if [[ ${1#*=} != docker ]] && [[ ${1#*=} != make ]] && [[ ${1#*=} != systemd ]]; then
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
	make)
		make_install
		;;
	docker|*)
		docker_install
		;;
esac
