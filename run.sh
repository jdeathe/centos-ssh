#!/usr/bin/env bash

DIR_PATH="$( cd "$( echo "${0%/*}" )"; pwd )"
if [[ $DIR_PATH == */* ]]; then
	cd $DIR_PATH
fi

source run.conf

have_docker_container_name ()
{
	NAME=$1

	if [[ -n $(docker ps -a | grep -v -e "${NAME}/.*,.*" | grep -o ${NAME}) ]]; then
		return 0
	else
		return 1
	fi
}

is_docker_container_name_running ()
{
	NAME=$1

	if [[ -n $(docker ps | grep -v -e "${NAME}/.*,.*" | grep -o ${NAME}) ]]; then
		return 0
	else
		return 1
	fi
}

remove_docker_container_name ()
{
	NAME=$1

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
if [ ! "${VOLUME_CONFIG_NAME}" == "$(docker ps -a | grep -v -e \"${VOLUME_CONFIG_NAME}/.*,.*\" | grep -e '[ ]\{1,\}'${VOLUME_CONFIG_NAME} | grep -o ${VOLUME_CONFIG_NAME})" ]; then
(
set -x
docker run \
	--name ${VOLUME_CONFIG_NAME} \
	-v ${MOUNT_PATH_CONFIG}/${SERVICE_UNIT_NAME}.${SERVICE_UNIT_SHARED_GROUP}:/etc/services-config/ssh \
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

if is_docker_container_name_running ${DOCKER_NAME} ; then
	docker ps | grep -v -e "${DOCKER_NAME}/.*,.*" | grep ${DOCKER_NAME}
	echo " ---> Docker container running."
fi
