#!/usr/bin/env bash

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

have_docker_image ()
{
	local NAME=$1

	if [[ -n $(show_docker_image ${NAME}) ]]; then
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
