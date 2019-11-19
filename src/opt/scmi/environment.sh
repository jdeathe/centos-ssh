# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly DOCKER_IMAGE_NAME=centos-ssh
readonly DOCKER_IMAGE_RELEASE_TAG_PATTERN='^[1-2]\.[0-9]+\.[0-9]+$'
readonly DOCKER_IMAGE_TAG_PATTERN='^(latest|[1-2]\.[0-9]+\.[0-9]+)$'
readonly DOCKER_USER=jdeathe

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
DIST_PATH="${DIST_PATH:-./dist}"
DOCKER_CONTAINER_OPTS="${DOCKER_CONTAINER_OPTS:-}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-latest}"
DOCKER_NAME="${DOCKER_NAME:-ssh.1}"
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-2020}"
DOCKER_RESTART_POLICY="${DOCKER_RESTART_POLICY:-always}"
NO_CACHE="${NO_CACHE:-false}"
REGISTER_ETCD_PARAMETERS="${REGISTER_ETCD_PARAMETERS:-}"
REGISTER_TTL="${REGISTER_TTL:-60}"
REGISTER_UPDATE_INTERVAL="${REGISTER_UPDATE_INTERVAL:-55}"
STARTUP_TIME="${STARTUP_TIME:-2}"

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
ENABLE_SSHD_BOOTSTRAP="${ENABLE_SSHD_BOOTSTRAP:-true}"
ENABLE_SSHD_WRAPPER="${ENABLE_SSHD_WRAPPER:-true}"
ENABLE_SUPERVISOR_STDOUT="${ENABLE_SUPERVISOR_STDOUT:-false}"
SSH_AUTHORIZED_KEYS="${SSH_AUTHORIZED_KEYS:-}"
SSH_CHROOT_DIRECTORY="${SSH_CHROOT_DIRECTORY:-%h}"
SSH_INHERIT_ENVIRONMENT="${SSH_INHERIT_ENVIRONMENT:-false}"
SSH_PASSWORD_AUTHENTICATION="${SSH_PASSWORD_AUTHENTICATION:-false}"
SSH_SUDO="${SSH_SUDO:-"ALL=(ALL) ALL"}"
SSH_USER="${SSH_USER:-app-admin}"
SSH_USER_FORCE_SFTP="${SSH_USER_FORCE_SFTP:-false}"
SSH_USER_HOME="${SSH_USER_HOME:-/home/%u}"
SSH_USER_ID="${SSH_USER_ID:-500:500}"
SSH_USER_PASSWORD="${SSH_USER_PASSWORD:-}"
SSH_USER_PASSWORD_HASHED="${SSH_USER_PASSWORD_HASHED:-false}"
SSH_USER_PRIVATE_KEY="${SSH_USER_PRIVATE_KEY:-}"
SSH_USER_SHELL="${SSH_USER_SHELL:-/bin/bash}"
SYSTEM_TIMEZONE="${SYSTEM_TIMEZONE:-UTC}"
