
# Handle incrementing the docker host port for instances unless a port range is defined.
DOCKER_PUBLISH := $(shell \
	if [[ "$(DOCKER_PORT_MAP_TCP_22)" != NULL ]]; \
	then \
		if grep -qE \
				'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:)?[1-9][0-9]*$$' \
				<<< "$(DOCKER_PORT_MAP_TCP_22)" \
			&& grep -qE \
				'^.+\.[0-9]+(\.[0-9]+)?$$' \
				<<< "$(DOCKER_NAME)"; \
		then \
			printf -- ' --publish %s%s:22' \
				"$$(\
					grep -o '^[0-9\.]*:' \
						<<< "$(DOCKER_PORT_MAP_TCP_22)" \
				)" \
				"$$(( \
					$$(\
						grep -oE \
							'[0-9]+$$' \
							<<< "$(DOCKER_PORT_MAP_TCP_22)" \
					) \
					+ $$(\
						grep -oE \
							'([0-9]+)(\.[0-9]+)?$$' \
							<<< "$(DOCKER_NAME)" \
						| awk -F. \
							'{ print $$1; }' \
					) \
					- 1 \
				))"; \
		else \
			printf -- ' --publish %s:22' \
				"$(DOCKER_PORT_MAP_TCP_22)"; \
		fi; \
	fi; \
)

# Common parameters of create and run targets
define DOCKER_CONTAINER_PARAMETERS
--name $(DOCKER_NAME) \
--restart $(DOCKER_RESTART_POLICY) \
--env "ENABLE_SSHD_BOOTSTRAP=$(ENABLE_SSHD_BOOTSTRAP)" \
--env "ENABLE_SSHD_WRAPPER=$(ENABLE_SSHD_WRAPPER)" \
--env "ENABLE_SUPERVISOR_STDOUT=$(ENABLE_SUPERVISOR_STDOUT)" \
--env "SSH_AUTHORIZED_KEYS=$(SSH_AUTHORIZED_KEYS)" \
--env "SSH_CHROOT_DIRECTORY=$(SSH_CHROOT_DIRECTORY)" \
--env "SSH_INHERIT_ENVIRONMENT=$(SSH_INHERIT_ENVIRONMENT)" \
--env "SSH_PASSWORD_AUTHENTICATION=$(SSH_PASSWORD_AUTHENTICATION)" \
--env "SSH_SUDO=$(SSH_SUDO)" \
--env "SSH_USER=$(SSH_USER)" \
--env "SSH_USER_FORCE_SFTP=$(SSH_USER_FORCE_SFTP)" \
--env "SSH_USER_HOME=$(SSH_USER_HOME)" \
--env "SSH_USER_ID=$(SSH_USER_ID)" \
--env "SSH_USER_PASSWORD=$(SSH_USER_PASSWORD)" \
--env "SSH_USER_PASSWORD_HASHED=$(SSH_USER_PASSWORD_HASHED)" \
--env "SSH_USER_PRIVATE_KEY=$(SSH_USER_PRIVATE_KEY)" \
--env "SSH_USER_SHELL=$(SSH_USER_SHELL)" \
--env "SYSTEM_TIMEZONE=$(SYSTEM_TIMEZONE)"
endef
