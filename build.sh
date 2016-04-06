#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]]; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]]; then
	cd ${DIR_PATH}
fi

source build.conf
source docker-helpers.sh

NO_CACHE=$1

echo "Building ${DOCKER_IMAGE_REPOSITORY_NAME}"

# Allow cache to be bypassed
if [[ ${NO_CACHE} == true ]]; then
	echo " ---> Skipping cache"
else
	NO_CACHE=false
fi

# Build from working directory
docker build --no-cache=${NO_CACHE} -t ${DOCKER_IMAGE_REPOSITORY_NAME} .

if [[ ${?} -eq 0 ]]; then
	printf -- "\n%s:\n" 'Docker image'
	show_docker_image ${DOCKER_IMAGE_REPOSITORY_NAME}
	printf -- " ${COLOUR_POSITIVE}--->${COLOUR_RESET} %s\n" 'Build complete'
else
	printf -- " ${COLOUR_NEGATIVE}--->${COLOUR_RESET} %s\n" 'ERROR'
fi
