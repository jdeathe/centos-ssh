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
# 	--env "SSH_USER=app-admin" \
# 	--env "SSH_USER_HOME_DIR=/home/app-admin" \
# 	--env "SSH_USER_SHELL=/bin/sh" \
# 	${DOCKER_IMAGE_REPOSITORY_NAME}
# )

if is_docker_container_name_running ${DOCKER_NAME} ; then
	docker ps | awk -v pattern="${DOCKER_NAME}$" '$NF ~ pattern { print $0 ; }'
	echo " ---> Docker container running."
fi
