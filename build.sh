#!/usr/bin/env bash

# Change working directory
DIR_PATH="$( if [[ $( echo "${0%/*}" ) != $( echo "${0}" ) ]]; then cd "$( echo "${0%/*}" )"; fi; pwd )"
if [[ ${DIR_PATH} == */* ]] && [[ ${DIR_PATH} != $( pwd ) ]]; then
	cd ${DIR_PATH}
fi

source build.conf

show_docker_image ()
{
	local NAME=$1
	local NAME_PARTS=(${NAME//:/ })

	# Set 'latest' tag if no tag requested
	if [[ ${#NAME_PARTS[@]} == 1 ]]; then
		NAME_PARTS[1]='latest'
	fi

	docker images | \
		awk \
			-v FS='[ ]+' \
			-v pattern="^${NAME_PARTS[0]}[ ]+${NAME_PARTS[1]} " \
			'$0 ~ pattern { print $0; }'
}

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
	echo -e "\nDocker image:"
	show_docker_image ${DOCKER_IMAGE_REPOSITORY_NAME}

	echo " ---> ${COLOUR_POSITIVE}Build complete${COLOUR_RESET}"
else
	echo -e "\n ---> ${COLOUR_NEGATIVE}ERROR: Build failed${COLOUR_RESET}"
fi