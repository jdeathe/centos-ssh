#!/usr/bin/env bash

DIR_PATH="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ $DIR_PATH == */* ]] && [[ $DIR_PATH != "$( pwd )" ]] ; then
	cd $DIR_PATH
fi

source run.conf

have_docker_container_name ()
{
	local NAME=$1

	if [[ -n $(docker ps -a | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	else
		return 1
	fi
}

is_docker_container_name_running ()
{
	local NAME=$1

	if [[ -n $(docker ps | awk -v pattern="^${NAME}$" '$NF ~ pattern { print $NF; }') ]]; then
		return 0
	else
		return 1
	fi
}

remove_docker_container_name ()
{
	local NAME=$1

	if have_docker_container_name ${NAME} ; then
		if is_docker_container_name_running ${NAME} ; then
			echo Stopping container ${NAME}...
			(docker stop ${NAME})
		fi
		echo Removing container ${NAME}...
		(docker rm ${NAME})
	fi
}

# Configuration volume
if ! have_docker_container_name ${VOLUME_CONFIG_NAME} ; then

	CONTAINER_MOUNT_PATH_CONFIG=${MOUNT_PATH_CONFIG}/${SERVICE_UNIT_NAME}.${SERVICE_UNIT_SHARED_GROUP}

	# The Docker Host needs the target configuration directories

	if [ ! -d ${CONTAINER_MOUNT_PATH_CONFIG}/ssh ]; then
	       CMD=$(mkdir -p ${CONTAINER_MOUNT_PATH_CONFIG}/ssh)
	       $CMD || sudo $CMD
	fi

	if [[ ! -n $(find ${CONTAINER_MOUNT_PATH_CONFIG}/ssh -maxdepth 1 -type f) ]]; then
	       CMD=$(cp -R etc/services-config/ssh ${CONTAINER_MOUNT_PATH_CONFIG}/)
	       $CMD || sudo $CMD
	fi

	if [ ! -d ${CONTAINER_MOUNT_PATH_CONFIG}/supervisor ]; then
	       CMD=$(mkdir -p ${CONTAINER_MOUNT_PATH_CONFIG}/supervisor)
	       $CMD || sudo $CMD
	fi

	if [[ ! -n $(find ${CONTAINER_MOUNT_PATH_CONFIG}/supervisor -maxdepth 1 -type f) ]]; then
	       CMD=$(cp -R etc/services-config/supervisor ${CONTAINER_MOUNT_PATH_CONFIG}/)
	       $CMD || sudo $CMD
	fi
(
set -x
docker run \
	--name ${VOLUME_CONFIG_NAME} \
       -v ${CONTAINER_MOUNT_PATH_CONFIG}/ssh:/etc/services-config/ssh \
       -v ${CONTAINER_MOUNT_PATH_CONFIG}/supervisor:/etc/services-config/supervisor \
	busybox:latest \
	/bin/true;
)
fi

# Force replace container of same name if found to exist
remove_docker_container_name ${DOCKER_NAME}

# In a sub-shell set xtrace - prints the docker command to screen for reference
(
set -x
docker run \
	-d \
	--name ${DOCKER_NAME} \
	-p :22 \
	--volumes-from ${VOLUME_CONFIG_NAME} \
	${DOCKER_IMAGE_REPOSITORY_NAME}
)

# Use environment variables instead of configuration volume
# (
# set -x
# docker run \
# 	-d \
# 	--name ${DOCKER_NAME} \
# 	-p :22 \
# 	--env "SSH_USER=app-1" \
# 	--env "SSH_USER_HOME_DIR=/home/app" \
# 	--env "SSH_USER_SHELL=/bin/sh" \
# 	--env "SSH_AUTHORIZED_KEYS=
# ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
# ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew==
# "  \
# 	${DOCKER_IMAGE_REPOSITORY_NAME}
# )

if is_docker_container_name_running ${DOCKER_NAME} ; then
	docker ps | awk -v pattern="${DOCKER_NAME}$" '$NF ~ pattern { print $0 ; }'
	echo " ---> Docker container running."
fi
