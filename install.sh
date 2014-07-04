#!/usr/bin/env bash

is_docker_image_available_to_pull ()
{
	NAME=$1

	if [[ -n $(docker search ${NAME} | grep -e "^${NAME}") ]]; then
		return 0
	else
		return 1
	fi
}

do_docker_pull ()
{
	NAME=$1

	if is_docker_image_available_to_pull ${NAME} ; then	
		# TODO: this returns true even on 404 error.
		if [[ -n $(docker pull ${NAME}) ]]; then
			return 0
		else
			return 1
		fi
	else
		return 1
	fi
}

have_docker_image ()
{
	NAME=$1

	NAME_PARTS=(${NAME//:/ })

	# Set 'latest' tag if no tag requested
	if [ ${#NAME_PART[@]} -eq 1 ]; then
		NAME_PARTS[1]='latest'
	fi

	if [[ -n $(docker images | grep -e "^${NAME_PARTS[0]}[ ]\{1,\}${NAME_PARTS[1]}") ]]; then
		return 0
	else
		return 1
	fi
}