# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
DOCKER_IMAGE_NAME := centos-ssh
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^[1-2]\.[0-9]+\.[0-9]+$
DOCKER_IMAGE_TAG_PATTERN := ^(latest|[1-2]\.[0-9]+\.[0-9]+)$
DOCKER_USER := jdeathe
SHPEC_ROOT := test/shpec

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
DIST_PATH ?= ./dist
DOCKER_CONTAINER_OPTS ?=
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= ssh.1
DOCKER_PORT_MAP_TCP_22 ?= 2020
DOCKER_RESTART_POLICY ?= always
NO_CACHE ?= false
RELOAD_SIGNAL ?= HUP
STARTUP_TIME ?= 2

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
ENABLE_SSHD_BOOTSTRAP ?= true
ENABLE_SSHD_WRAPPER ?= true
ENABLE_SUPERVISOR_STDOUT ?= false
SSH_AUTHORIZED_KEYS ?=
SSH_CHROOT_DIRECTORY ?= %h
SSH_INHERIT_ENVIRONMENT ?= false
SSH_PASSWORD_AUTHENTICATION ?= false
SSH_SUDO ?= ALL=(ALL) ALL
SSH_USER ?= app-admin
SSH_USER_FORCE_SFTP ?= false
SSH_USER_HOME ?= /home/%u
SSH_USER_ID ?= 500:500
SSH_USER_PASSWORD ?=
SSH_USER_PASSWORD_HASHED ?= false
SSH_USER_PRIVATE_KEY ?=
SSH_USER_SHELL ?= /bin/bash
SYSTEM_TIMEZONE ?= UTC
