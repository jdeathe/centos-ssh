export SHELL := /usr/bin/env bash
export PATH := ${PATH}

define USAGE
Usage: make [options] [target] ...
Usage: VARIABLE="VALUE" make [options] -- [target] ...

This Makefile allows you to build, operate and create release packages for the
container image defined by the Dockerfile.

Targets:
  all                       Combines targets build images install start and ps.
  build                     Builds the image. This is the default target.
  clean                     Clean up build artifacts.
  create                    Execute the create container template.
  dist                      Pull a release version from the registry and save a
                            package suitable for offline distribution. Image is
                            saved as a tar archive, compressed with xz.
  distclean                 Clean up distribution artifacts.
  exec COMMAND [ARG...]     Run command in a the running container.
  help                      Show this help.
  inspect [-f \"FORMAT\"]   Return low-level information on the container.
  install                   Terminate running container and run the docker
                            create template.
  images                    Show container's image details.
  load                      Loads from the distribution package. Requires
                            DOCKER_IMAGE_TAG variable.
  logs [OPTIONS]            Display log output from the container.
  logsdef                   Display log output from the container deferred for
                            STARTUP_TIME seconds. This will work in a chain
                            unlike the logs target.
  logs-delayed              [DEPRECATED] Replaced with logsdef.
  pause                     Pause the running container.
  pull                      Pull the release image from the registry. Requires
                            the DOCKER_IMAGE_TAG variable.
  ps                        Display the details of the container process.
  reload                    Send SIGHUP to the PID 1 container process.
  restart                   Restarts the container.
  rm                        Force remove the container.
  rm-exited                 Force remove all containers in the exited state.
  rmi                       Untag (remove) the image.
  rmi-dangling              Untag (remove) images not referenced by any
                            container.
  run                       Execute the run container template.
  start                     Start the container in the created state.
  stop                      Stop the container when in a running state.
  terminate                 Unpause, stop and remove the container.
  test                      Run all test cases.
  test-setup                Install test dependencies.
  top [ps OPTIONS]          Display the running processes of the container.
  unpause                   Unpause the container when in a paused state.

Variables:
  - DOCKER_CONTAINER_OPTS   Set optional docker parameters to append that will
                            be appended to the create and run templates.
  - DOCKER_IMAGE_TAG        Defines the image tag name.
  - DOCKER_NAME             Container name. The required format is as follows
                            where <instance> and <node> are numeric values.
                            <name>[.<instance>[.<node>]]
  - DOCKER_PORT_MAP_TCP_*   The port map variable is used to define the initial
                            port mapping to use for the docker host value where
                            "*" corresponds to an exposed port on the container.
                            Setting this to an empty string or 0 will result in
                            an automatically assigned port and setting to NULL
                            will prevent the port from being published.
  - DOCKER_RESTART_POLICY   Defines the container restart policy.
  - DIST_PATH               Ouput directory path - where the release package
                            artifacts are placed.
  - NO_CACHE                When true, no cache will be used while running the
                            build target.
  - RELOAD_SIGNAL           Default signal is SIGHUP. Use to set an alternative
                            signal value.
  - STARTUP_TIME            Defines the number of seconds expected to complete
                            the startup process, including the bootstrap where
                            applicable.

endef

include environment.mk
include default.mk

.DEFAULT_GOAL := build
COLOUR_NEGATIVE := \033[1;31m
COLOUR_POSITIVE := \033[1;32m
COLOUR_RESET := \033[0m
CHARACTER_STEP := --->
PREFIX_STEP := $(shell \
	printf -- '%s ' \
		"$(CHARACTER_STEP)"; \
)
PREFIX_SUB_STEP := $(shell \
	printf -- ' %s ' \
		"$(CHARACTER_STEP)"; \
)
PREFIX_STEP_NEGATIVE := $(shell \
	printf -- '%b%s%b' \
		"$(COLOUR_NEGATIVE)" \
		"$(PREFIX_STEP)" \
		"$(COLOUR_RESET)"; \
)
PREFIX_STEP_POSITIVE := $(shell \
	printf -- '%b%s%b' \
		"$(COLOUR_POSITIVE)" \
		"$(PREFIX_STEP)" \
		"$(COLOUR_RESET)"; \
)
PREFIX_SUB_STEP_NEGATIVE := $(shell \
	printf -- '%b%s%b' \
		"$(COLOUR_NEGATIVE)" \
		"$(PREFIX_SUB_STEP)" \
		"$(COLOUR_RESET)"; \
)
PREFIX_SUB_STEP_POSITIVE := $(shell \
	printf -- '%b%s%b' \
		"$(COLOUR_POSITIVE)" \
		"$(PREFIX_SUB_STEP)" \
		"$(COLOUR_RESET)"; \
)
docker := $(shell \
	command -v docker \
)
docker-status := $(shell \
	if ! docker version > /dev/null; \
	then \
		printf -- 'ERROR'; \
	else \
		printf -- 'OK'; \
	fi \
)
shpec := $(shell \
	command -v shpec \
)
xz := $(shell \
	command -v xz \
)

define get-docker-image-id
$$(if [[ -n $$($(docker) images -q \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(1) \
	) ]]; \
then \
	printf -- '%s\n' \
		"$$($(docker) images -q \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(1) \
		)"; \
else \
	printf -- '%s\n' \
		"$$($(docker) images -q \
			docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(1) \
		)"; \
fi)
endef

.PHONY: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-not \
	_require-docker-container-not-status-paused \
	_require-docker-container-status-created \
	_require-docker-container-status-exited \
	_require-docker-container-status-paused \
	_require-docker-container-status-running \
	_require-docker-image-tag \
	_require-docker-release-tag \
	_require-package-path \
	_require-root \
	_test-prerequisites \
	_usage \
	all \
	build \
	clean \
	create \
	dist \
	distclean \
	exec \
	help \
	inspect \
	install \
	images \
	load \
	logs \
	logsdef \
	logs-delayed \
	pause \
	pull \
	ps \
	reload \
	restart \
	rm \
	rm-exited \
	rmi \
	rmi-dangling \
	run \
	start \
	stop \
	terminate \
	test \
	test-setup \
	top \
	unpause

_prerequisites:
ifeq ($(docker),)
	$(error "Please install the docker (docker-engine) package.")
endif

ifeq ($(xz),)
	$(error "Please install the xz package.")
endif

ifneq ($(docker-status),OK)
	$(error "Docker server host error.")
endif

_require-docker-container:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"install"; \
		exit 1; \
	fi

_require-docker-container-not:
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"be removed or renamed"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"rm"; \
		exit 1; \
	fi

_require-docker-container-not-status-paused:
	@ if [[ -n $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=paused" \
		) ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"to be unpaused"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"unpause"; \
		exit 1; \
	fi

_require-docker-container-status-created:
	@ if [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=created" \
		) ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"to be created"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"install"; \
		exit 1; \
	fi

_require-docker-container-status-exited:
	@ if [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=exited" \
		) ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"to be exited"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"stop"; \
		exit 1; \
	fi

_require-docker-container-status-paused:
	@ if [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=paused" \
		) ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"to be paused"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"pause"; \
		exit 1; \
	fi

_require-docker-container-status-running:
	@ if [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=running" \
		) ]]; \
	then \
		>&2 printf -- '%sThis operation requires the %s container %s.\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"$(DOCKER_NAME)" \
			"to be running"; \
		>&2 printf -- '%sTry: DOCKER_NAME=%s make %s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(DOCKER_NAME)" \
			"start"; \
		exit 1; \
	fi

_require-docker-image-tag:
	@ if ! [[ "$(DOCKER_IMAGE_TAG)" =~ $(DOCKER_IMAGE_TAG_PATTERN) ]]; \
	then \
		>&2 printf -- '%sInvalid %s value: %s\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"DOCKER_IMAGE_TAG" \
			"$(DOCKER_IMAGE_TAG)"; \
		exit 1; \
	fi

_require-docker-release-tag:
	@ if ! [[ "$(DOCKER_IMAGE_TAG)" =~ $(DOCKER_IMAGE_RELEASE_TAG_PATTERN) ]]; \
	then \
		>&2 printf -- '%sInvalid %s value: %s\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"DOCKER_IMAGE_TAG" \
			"$(DOCKER_IMAGE_TAG)"; \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"A release tag is required for this operation."; \
		exit 1; \
	fi

_require-package-path:
	@ if [[ -n $(DIST_PATH) ]] && [[ ! -d $(DIST_PATH) ]]; \
	then \
		printf -- '%s%\n' \
			"$(PREFIX_STEP)" \
			"Creating package directory"; \
		mkdir -p $(DIST_PATH); \
	fi; \
	if [[ ! $${?} -eq 0 ]]; \
	then \
		>&2 printf -- '%s%s: %s\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"Failed to make package path" \
			"$(DIST_PATH)"; \
		exit 1; \
	elif [[ -z $(DIST_PATH) ]]; \
	then \
		>&2 printf -- '%sUndefined %s\n' \
			"$(PREFIX_STEP_NEGATIVE)" \
			"DIST_PATH"; \
		exit 1; \
	fi

_require-root:
	@ if [[ $${EUID} -ne 0 ]]; \
	then \
	>&2 printf -- '%sMust be run as root\n' \
		"$(PREFIX_STEP_NEGATIVE)"; \
	exit 1; \
	fi

_test-prerequisites:
ifeq ($(shpec),)
	$(error "Please install shpec. Try: DOCKER_NAME=$(DOCKER_NAME) make test-setup")
endif

_usage:
	@: $(info $(USAGE))

all: \
	_prerequisites \
	| \
	build \
	images \
	install \
	start \
	ps

build: \
	_prerequisites \
	_require-docker-image-tag
	@ printf -- '%sBuilding %s/%s:%s\n' \
		"$(PREFIX_STEP)" \
		"$(DOCKER_USER)" \
		"$(DOCKER_IMAGE_NAME)" \
		"$(DOCKER_IMAGE_TAG)"
	@ if [[ $(NO_CACHE) == true ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"Skipping cache"; \
	fi
	@ $(docker) build \
		--no-cache=$(NO_CACHE) \
		-t $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		.; \
	if [[ $${?} -eq 0 ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Build complete"; \
	else \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Build error"; \
		exit 1; \
	fi

clean: \
	_prerequisites \
	| \
	terminate \
	rm-exited \
	rmi \
	rmi-dangling

create: \
	_prerequisites \
	_require-docker-container-not
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Creating container"
	@ set -x; \
	$(docker) create \
		$(DOCKER_CONTAINER_PARAMETERS) \
		$(DOCKER_PUBLISH) \
		$(DOCKER_CONTAINER_OPTS) \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		1> /dev/null
	@ if [[ -n $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=created" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
				--filter "status=created" \
			)"; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Container created"; \
	else \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Container creation failed"; \
		exit 1; \
	fi

dist: \
	_prerequisites \
	_require-docker-release-tag \
	_require-package-path \
	| \
	pull
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	$(eval $@_dist_file := $(shell \
		printf -- '%s.%s.tar.xz' \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)" \
	))
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Saving package"
	@ if [[ -s $($@_dist_path)/$($@_dist_file) ]]; \
	then \
		printf -- '%sPackage path: %s/%s.%s.tar.xz\n' \
			"$(PREFIX_SUB_STEP)" \
			"$($@_dist_path)" \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)"; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Package already exists"; \
	else \
		$(docker) save \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
			| $(xz) -9 \
			> $($@_dist_path)/$($@_dist_file); \
		if [[ $${?} -eq 0 ]]; \
		then \
			printf -- '%sPackage path: %s/%s.%s.tar.xz\n' \
				"$(PREFIX_SUB_STEP)" \
				"$($@_dist_path)" \
				"$(DOCKER_IMAGE_NAME)" \
				"$(DOCKER_IMAGE_TAG)"; \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Package saved"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Package save error"; \
			exit 1; \
		fi; \
	fi

distclean: \
	_prerequisites \
	_require-docker-release-tag \
	_require-package-path \
	| \
	clean
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	$(eval $@_dist_file := $(shell \
		printf -- '%s.%s.tar.xz' \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)" \
	))
	@ if [[ -e $($@_dist_path)/$($@_dist_file) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Deleting package"; \
		printf -- '%sPackage path: %s/%s.%s.tar.xz\n' \
			"$(PREFIX_SUB_STEP)" \
			"$($@_dist_path)" \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)"; \
		find $($@_dist_path) \
			-name $($@_dist_file) \
			-delete; \
		if [[ ! -e $($@_dist_path)/$($@_dist_file) ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Package cleanup complete"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Package cleanup failed"; \
			exit 1; \
		fi; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Package cleanup skipped"; \
	fi

exec: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-running
	@ $(docker) exec -it $(DOCKER_NAME) $(filter-out $@, $(MAKECMDGOALS))
%:; @:

images: \
	_prerequisites
	@ $(docker) images \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

help: \
	_usage

inspect: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-running
	@ $(docker) inspect \
		--type=container \
		$(filter-out $@, $(MAKECMDGOALS)) \
		$(DOCKER_NAME)
%:; @:

install: | \
	_prerequisites \
	terminate \
	create

logs: \
	_prerequisites \
	_require-docker-container
	@ $(docker) logs \
		$(filter-out $@, $(MAKECMDGOALS)) \
		$(DOCKER_NAME)
%:; @:

logsdef: \
	_prerequisites \
	_require-docker-container
	@ sleep $(STARTUP_TIME)
	@ $(MAKE) logs

logs-delayed: \
	logsdef

load: \
	_prerequisites \
	_require-docker-release-tag \
	_require-package-path
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	$(eval $@_dist_file := $(shell \
		printf -- '%s.%s.tar.xz' \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)" \
	))
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Loading image from package"; \
	printf -- '%sPackage path: %s/%s.%s.tar.xz\n' \
		"$(PREFIX_SUB_STEP)" \
		"$($@_dist_path)" \
		"$(DOCKER_IMAGE_NAME)" \
		"$(DOCKER_IMAGE_TAG)"; \
	if [[ ! -s $($@_dist_path)/$($@_dist_file) ]]; \
	then \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Package not found"; \
		>&2 printf -- '%sTry: DOCKER_IMAGE_TAG=%s make %s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"$(DOCKER_IMAGE_TAG)" \
			"dist"; \
		exit 1; \
	else \
		$(xz) -dc \
			$($@_dist_path)/$($@_dist_file) \
			| $(docker) load; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(call get-docker-image-id,$(DOCKER_IMAGE_TAG))"; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Image loaded"; \
	fi

pause: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-running
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Pausing container"
	@ $(docker) pause \
		$(DOCKER_NAME) \
		1> /dev/null
	@ printf -- '%s%s\n' \
		"$(PREFIX_SUB_STEP_POSITIVE)" \
		"Container paused"

pull: \
	_prerequisites \
	_require-docker-image-tag
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Pulling image from registry"
	@ $(docker) pull \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG); \
	if [[ $${?} -eq 0 ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(call get-docker-image-id,$(DOCKER_IMAGE_TAG))"; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Image pulled"; \
	else \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Error pulling image"; \
		exit 1; \
	fi

ps: \
	_prerequisites \
	_require-docker-container
	@ $(docker) ps -as \
		--filter "name=$(DOCKER_NAME)"

reload: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-running
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Reloading container"
	@ $(docker) exec $(DOCKER_NAME) \
		kill -$(RELOAD_SIGNAL) 1
	@ printf -- '%s%s\n' \
		"$(PREFIX_SUB_STEP_POSITIVE)" \
		"Container reloaded"

restart: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-not-status-paused
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Restarting container"
	@ $(docker) restart \
		$(DOCKER_NAME) \
		1> /dev/null
	@ printf -- '%s%s\n' \
		"$(PREFIX_SUB_STEP_POSITIVE)" \
		"Container restarted"

rm: \
	_prerequisites \
	_require-docker-container-not-status-paused
	@ if [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Container removal skipped"; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Removing container"; \
		$(docker) rm -f $(DOCKER_NAME); \
		if [[ -z $$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
			) ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Container removed"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Container removal failed"; \
			exit 1; \
		fi; \
	fi

rm-exited: \
	_prerequisites
	@ if [[ -z $$($(docker) ps -aq \
			--filter "status=exited" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Exited containers removal skipped"; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Removing exited containers"; \
		$(docker) rm -f \
			$$($(docker) ps -aq \
				--filter "status=exited" \
			) \
			1> /dev/null; \
	fi

rmi: \
	_prerequisites \
	_require-docker-image-tag \
	_require-docker-container-not
	@ if [[ -n $(call get-docker-image-id,$(DOCKER_IMAGE_TAG)) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Untagging image"; \
		printf -- '%s%s : %s/%s:%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$(call get-docker-image-id,$(DOCKER_IMAGE_TAG))" \
			"$(DOCKER_USER)" \
			"$(DOCKER_IMAGE_NAME)" \
			"$(DOCKER_IMAGE_TAG)"; \
		$(docker) rmi \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
			1> /dev/null; \
		if [[ $${?} -eq 0 ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Image untagged"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Error untagging image"; \
			exit 1; \
		fi; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Untagging image skipped"; \
	fi

rmi-dangling: \
	_prerequisites
	@ if [[ -z $$($(docker) images -q \
			--filter "dangling=true" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Untagging dangling images skipped"; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Untagging dangling images"; \
		$(docker) rmi \
			$$($(docker) images -q \
				--filter "dangling=true" \
			) \
			1> /dev/null; \
	fi

run: \
	_prerequisites \
	_require-docker-image-tag
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Running container"
	@ set -x; \
	$(docker) run \
		--detach \
		$(DOCKER_CONTAINER_PARAMETERS) \
		$(DOCKER_PUBLISH) \
		$(DOCKER_CONTAINER_OPTS) \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		1> /dev/null
	@ if [[ -n $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=running" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP)" \
			"$$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
				--filter "status=running" \
			)"; \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Container running"; \
	else \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Container run failed"; \
		exit 1; \
	fi

start: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-not-status-paused
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Starting container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]] \
		&& [[ -z $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=running" \
		) ]]; \
	then \
		$(docker) start \
			$(DOCKER_NAME) \
			1> /dev/null; \
	fi
	@ if [[ -n $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=running" \
		) ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_POSITIVE)" \
			"Container started"; \
	else \
		>&2 printf -- '%s%s\n' \
			"$(PREFIX_SUB_STEP_NEGATIVE)" \
			"Container start failed"; \
		exit 1; \
	fi

stop: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-not-status-paused \
	_require-docker-container-status-running
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Stopping container"
	@ if [[ -n $$($(docker) ps -aq \
			--filter "name=$(DOCKER_NAME)" \
			--filter "status=running" \
		) ]]; \
	then \
		$(docker) stop \
			$(DOCKER_NAME) \
			1> /dev/null; \
		if [[ -n $$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
				--filter "status=exited" \
			) ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Container stopped"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Error stopping container"; \
			exit 1; \
		fi; \
	fi

top: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-running
	@ $(docker) top $(DOCKER_NAME) $(filter-out $@, $(MAKECMDGOALS))
%:; @:

terminate: \
	_prerequisites
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; \
	then \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Container termination skipped"; \
	else \
		printf -- '%s%s\n' \
			"$(PREFIX_STEP)" \
			"Terminating container"; \
		if [[ -n $$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
				--filter "status=paused" \
			) ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP)" \
				"Unpausing container"; \
			$(docker) unpause \
				$(DOCKER_NAME) \
				1> /dev/null; \
		fi; \
		if [[ -n $$($(docker) ps -aq \
				--filter "name=$(DOCKER_NAME)" \
				--filter "status=running" \
			) ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP)" \
				"Stopping container"; \
			$(docker) stop \
				$(DOCKER_NAME) \
				1> /dev/null; \
		fi; \
		if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP)" \
				"Removing container"; \
			$(docker) rm -f \
				$(DOCKER_NAME) \
				1> /dev/null; \
		fi; \
		if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; \
		then \
			printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_POSITIVE)" \
				"Container terminated"; \
		else \
			>&2 printf -- '%s%s\n' \
				"$(PREFIX_SUB_STEP_NEGATIVE)" \
				"Container termination failed"; \
			exit 1; \
		fi; \
	fi

test: \
	_test-prerequisites
	@ if [[ -z $(call get-docker-image-id,latest) ]]; \
	then \
		DOCKER_IMAGE_TAG=latest $(MAKE) build; \
	fi
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Functional test"
	@ SHPEC_ROOT=$(SHPEC_ROOT) $(shpec)

test-setup: \
	_require-root
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Installing shpec"
	@ bash -c "$$(curl -LSs \
			https://raw.githubusercontent.com/rylnd/shpec/master/install.sh \
		)"
	@ ln -sf \
		/usr/local/bin/shpec \
		/usr/bin/shpec

unpause: \
	_prerequisites \
	_require-docker-container \
	_require-docker-container-status-paused
	@ printf -- '%s%s\n' \
		"$(PREFIX_STEP)" \
		"Unpausing container"
	@ $(docker) unpause \
		$(DOCKER_NAME) \
		1> /dev/null
	@ printf -- '%s%s\n' \
		"$(PREFIX_SUB_STEP_POSITIVE)" \
		"Container unpaused"
