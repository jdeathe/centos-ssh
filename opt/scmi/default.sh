
# If gawk is available handle incrementing the docker host port for instances
DOCKER_PUBLISH=
if [[ ${DOCKER_PORT_MAP_TCP_22} != NULL ]]; then
	if command -v gawk &> /dev/null \
		&& [[ -n $(gawk 'match($0, /^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?([0-9]+)$/, matches) { print matches[2]; }' <<< "${DOCKER_PORT_MAP_TCP_22}") ]]; then
		printf -v \
			DOCKER_PUBLISH \
			-- '--publish %s%s:22' \
			"$(gawk 'match($0, /^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?([0-9]+)$/, matches) { print matches[1]; }' <<< "${DOCKER_PORT_MAP_TCP_22}")" \
			"$(( $(gawk 'match($0, /^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?([0-9]+)$/, matches) { print matches[2]; }' <<< "${DOCKER_PORT_MAP_TCP_22}") + $(gawk 'match($0, /^.+\.([0-9]+)\.([0-9]+)$/, matches) { print matches[1]; }' <<< "${DOCKER_NAME}") - 1 ))"
	else
		printf -v \
			DOCKER_PUBLISH \
			-- '--publish %s:22' \
			"${DOCKER_PORT_MAP_TCP_22}"
	fi
fi

# Common parameters of create and run targets
DOCKER_CONTAINER_PARAMETERS="--name ${DOCKER_NAME} \
--restart ${DOCKER_RESTART_POLICY} \
--env \"SSH_AUTHORIZED_KEYS=${SSH_AUTHORIZED_KEYS}\" \
--env \"SSH_AUTOSTART_SSHD=${SSH_AUTOSTART_SSHD}\" \
--env \"SSH_AUTOSTART_SSHD_BOOTSTRAP=${SSH_AUTOSTART_SSHD_BOOTSTRAP}\" \
--env \"SSH_CHROOT_DIRECTORY=${SSH_CHROOT_DIRECTORY}\" \
--env \"SSH_INHERIT_ENVIRONMENT=${SSH_INHERIT_ENVIRONMENT}\" \
--env \"SSH_SUDO=${SSH_SUDO}\" \
--env \"SSH_USER=${SSH_USER}\" \
--env \"SSH_USER_FORCE_SFTP=${SSH_USER_FORCE_SFTP}\" \
--env \"SSH_USER_HOME=${SSH_USER_HOME}\" \
--env \"SSH_USER_ID=${SSH_USER_ID}\" \
--env \"SSH_USER_PASSWORD=${SSH_USER_PASSWORD}\" \
--env \"SSH_USER_PASSWORD_HASHED=${SSH_USER_PASSWORD_HASHED}\" \
--env \"SSH_USER_SHELL=${SSH_USER_SHELL}\" \
${DOCKER_PUBLISH}"
