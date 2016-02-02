#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]]; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]]; then
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

show_docker_container_name_status ()
{
	local NAME=$1

	if [[ -z ${NAME} ]]; then
		return 1
	fi

	docker ps | \
		awk \
			-v pattern="${NAME}$" \
			'$NF ~ pattern { print $0; }'

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

# Configuration volume
if [[ ${VOLUME_CONFIG_ENABLED} == true ]] && ! have_docker_container_name ${VOLUME_CONFIG_NAME}; then

	echo "Creating configuration volume."
	if [[ ${VOLUME_CONFIG_NAMED} == true ]]; then
		DOCKER_VOLUME_MAPPING=${VOLUME_CONFIG_NAME}:/etc/services-config
	else
		DOCKER_VOLUME_MAPPING=/etc/services-config
	fi

	(
	set -x
	docker run \
		--name ${VOLUME_CONFIG_NAME} \
		-v ${DOCKER_VOLUME_MAPPING} \
		${DOCKER_IMAGE_REPOSITORY_NAME} \
		/bin/true;
	)

	# Named data volumes require files to be copied into place.
	if [[ ${VOLUME_CONFIG_NAMED} == true ]]; then
		echo "Populating configuration volume."
		(
		set -x
		docker cp \
			./etc/services-config/. \
			${DOCKER_VOLUME_MAPPING};
		)
	fi
fi

# Application container
remove_docker_container_name ${DOCKER_NAME}

if [[ ${#} -eq 0 ]]; then
	echo "Running container ${DOCKER_NAME} as a background/daemon process."
	DOCKER_OPERATOR_OPTIONS="-d"
else
	# This is useful for running commands like 'export' or 'env' to check the 
	# environment variables set by the --link docker option.
	# 
	# If you need to pipe to another command, quote the commands. e.g: 
	#   ./run.sh "env | grep MYSQL | sort"
	printf "Running container %s with CMD [/bin/bash -c '%s']\n" "${DOCKER_NAME}" "${*}"
	DOCKER_OPERATOR_OPTIONS="-it --entrypoint /bin/bash --env TERM=${TERM:-xterm}"
fi

if [[ ${VOLUME_CONFIG_ENABLED} == true ]] && have_docker_container_name ${VOLUME_CONFIG_NAME}; then
	DOCKER_VOLUMES_FROM="--volumes-from ${VOLUME_CONFIG_NAME}"
fi

# In a sub-shell set xtrace - prints the docker command to screen for reference
(
set -xe
docker run \
	${DOCKER_OPERATOR_OPTIONS} \
	--name ${DOCKER_NAME} \
	-p ${DOCKER_HOST_PORT_SSH:-}:22 \
	${DOCKER_VOLUMES_FROM:-} \
	${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
)

# Forced SFTP
# 	sftp -P 2020 -i ~/.ssh/id_rsa_insecure app-sftp@docker-host
# (
# set -xe
# docker run \
# 	${DOCKER_OPERATOR_OPTIONS} \
# 	--name ${DOCKER_NAME} \
# 	-p ${DOCKER_HOST_PORT_SSH:-}:22 \
# 	--env "SSH_USER=app-sftp" \
# 	--env "SSH_USER_FORCE_SFTP=true" \
# 	${DOCKER_VOLUMES_FROM:-} \
# 	${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
# )

# Use environment variables instead of configuration volume
# SHA-512 hashed password: Passw0rd!
# Salt: salt/pepper.pot.
# (
# set -xe
# docker run \
# 	${DOCKER_OPERATOR_OPTIONS} \
# 	--name ${DOCKER_NAME} \
# 	-p ${DOCKER_HOST_PORT_SSH:-}:22 \
# 	--env "SSH_AUTHORIZED_KEYS=
# ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
# ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew==
# " \
# 	--env "SSH_INHERIT_ENVIRONMENT=true" \
# 	--env "SSH_SUDO=ALL=(ALL) ALL" \
# 	--env "SSH_USER=app-1" \
# 	--env "SSH_USER_PASSWORD_HASHED=true" \
# 	--env 'SSH_USER_PASSWORD=$6$salt/pepper.pot.$vXFjBSve4gdT2gmS3p4pXycFSmkN4yT6eE.FmuFTqiSzH1bRFzulKtlYmJIMvP0pfrL4rx6L78ZQ7hjbWNRff1' \
# 	--env "SSH_USER_FORCE_SFTP=false" \
# 	--env "SSH_USER_HOME_DIR=/home/app" \
# 	--env "SSH_USER_SHELL=/bin/sh" \
# 	${DOCKER_VOLUMES_FROM:-} \
# 	${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
# )

if is_docker_container_name_running ${DOCKER_NAME}; then
	printf -- "\n%s:\n" 'Docker process status'
	show_docker_container_name_status ${DOCKER_NAME}
	printf -- " ${COLOUR_POSITIVE}--->${COLOUR_RESET} %s\n" 'Container running'
elif [[ ${#} -eq 0 ]]; then
	printf -- " ${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'ERROR'
fi

# Linked container test
# if [[ ${#} -eq 0 ]]; then

# 	DOCKER_NAME_LINK_HOST=${DOCKER_NAME}.link-host

# 	if [[ -n ${DOCKER_HOST_PORT_SSH} ]]; then
# 		(( DOCKER_HOST_PORT_SSH ++ ))
# 	fi

# 	remove_docker_container_name ${DOCKER_NAME_LINK_HOST}

# 	(
# 	set -xe
# 	docker run \
# 		${DOCKER_OPERATOR_OPTIONS} \
# 		--name ${DOCKER_NAME_LINK_HOST} \
# 		-p ${DOCKER_HOST_PORT_SSH:-}:22 \
# 		--link ${DOCKER_NAME}:link-guest \
# 		--env "SSH_INHERIT_ENVIRONMENT=true" \
# 		${DOCKER_VOLUMES_FROM:-} \
# 		${DOCKER_IMAGE_REPOSITORY_NAME}${@:+ -c }"${@}"
# 	)

# 	if is_docker_container_name_running ${DOCKER_NAME_LINK_HOST}; then
# 		printf -- "\n%s:\n" 'Docker process status'
# 		show_docker_container_name_status ${DOCKER_NAME_LINK_HOST}
# 		printf -- " ${COLOUR_POSITIVE}--->${COLOUR_RESET} %s\n" 'Container running'
# 	else
# 		printf -- " ${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'ERROR'
# 	fi
# fi
