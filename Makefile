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
  install                   Terminate running container and run the docker 
                            create template.
  images                    Show container's image details.
  load                      Loads from the distribution package. Requires 
                            DOCKER_IMAGE_TAG variable.
  logs                      Display log output from the running container.
  logs-delayed              Display log output from the running container after
                            backing off for STARTUP_TIME seconds. This can be 
                            necessary when chaining make targets together.
  pause                     Pause the running container.
  pull                      Pull the release image from the registry. Requires 
                            the DOCKER_IMAGE_TAG variable.
  ps                        Display the details of the container process.
  restart                   Restarts the container.
  rm                        Force remove the container.
  rmi                       Untag (remove) the image.
  run                       Execute the run container template.
  start                     Start the container in the created state.
  stop                      Stop the container when in a running state.
  terminate                 Unpause, stop and remove the container.
  test                      Run all test cases.
  unpause                   Unpause the container when in a paused state.

Variables:
  - DOCKER_CONTAINER_OPTS   Set optional docker parameters to append that will 
                            be appended to the create and run templates.
  - DOCKER_IMAGE_TAG        Defines the image tag name.
  - DOCKER_NAME             Container name. The required format is as follows
                            where <instance> and <node> are required numeric
                            values and group is optional. 
                            {<name>|<name>.[group]}.<instance>.<node>
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
  - STARTUP_TIME            Defines the number of seconds expected to complete 
                            the startup process, including the bootstrap where 
                            applicable.

endef

include environment.mk
include default.mk

# UI constants
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

.DEFAULT_GOAL := build

# Package prerequisites
docker := $(shell \
	command -v docker \
)
xz := $(shell \
	command -v xz \
)

# Testing prerequisites
shpec := $(shell \
	command -v shpec \
)

# Used to test docker host is accessible
get-docker-info := $(shell \
	$(docker) info \
)

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
	install \
	images \
	load \
	logs \
	logs-delayed \
	pause \
	pull \
	ps \
	restart \
	rm \
	rmi \
	run \
	start \
	stop \
	terminate \
	test \
	unpause

_prerequisites:
ifeq ($(docker),)
	$(error "Please install the docker (docker-engine) package.")
endif

ifeq ($(xz),)
	$(error "Please install the xz package.")
endif

ifeq ($(get-docker-info),)
	$(error "Unable to connect to docker host.")
endif

_require-docker-container:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container."; \
		echo "$(PREFIX_SUB_STEP)Try installing it with: make install"; \
		exit 1; \
	fi

_require-docker-container-not:
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container be removed (or renamed)."; \
		echo "$(PREFIX_SUB_STEP)Try removing it with: make rm"; \
		exit 1; \
	fi

_require-docker-container-not-status-paused:
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container to be unpaused."; \
		echo "$(PREFIX_SUB_STEP)Try unpausing it with: make unpause"; \
		exit 1; \
	fi

_require-docker-container-status-created:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container to be created."; \
		echo "$(PREFIX_SUB_STEP)Try installing it with: make install"; \
		exit 1; \
	fi

_require-docker-container-status-exited:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=exited") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container to be exited."; \
		echo "$(PREFIX_SUB_STEP)Try stopping it with: make stop"; \
		exit 1; \
	fi

_require-docker-container-status-paused:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container to be paused."; \
		echo "$(PREFIX_SUB_STEP)Try pausing it with: make pause"; \
		exit 1; \
	fi

_require-docker-container-status-running:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)This operation requires the $(DOCKER_NAME) docker container to be running."; \
		echo "$(PREFIX_SUB_STEP)Try starting it with: make start"; \
		exit 1; \
	fi

_require-docker-image-tag:
	@ if [[ -z $$(if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi) ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)Invalid DOCKER_IMAGE_TAG value: $(DOCKER_IMAGE_TAG)"; \
		exit 1; \
	fi

_require-docker-release-tag:
	@ if [[ -z $$(if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_RELEASE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi) ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)Invalid DOCKER_IMAGE_TAG value: $(DOCKER_IMAGE_TAG)"; \
		echo "$(PREFIX_SUB_STEP)A release tag is required for this operation."; \
		exit 1; \
	fi

_require-package-path:
	@ if [[ -n $(DIST_PATH) ]] && [[ ! -d $(DIST_PATH) ]]; then \
		echo "$(PREFIX_STEP)Creating package directory"; \
		mkdir -p $(DIST_PATH); \
	fi; \
	if [[ ! $${?} -eq 0 ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)Failed to make package path: $(DIST_PATH)"; \
		exit 1; \
	elif [[ -z $(DIST_PATH) ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)Undefined DIST_PATH"; \
		exit 1; \
	fi

_test-prerequisites:
ifeq ($(shpec),)
	$(error "Please install shpec.")
endif

_usage:
	@: $(info $(USAGE))

all: _prerequisites | build images install start ps

# build NO_CACHE=[{false,true}]
build: _prerequisites _require-docker-image-tag
	@ echo "$(PREFIX_STEP)Building $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"
	@ if [[ $(NO_CACHE) == true ]]; then \
		echo "$(PREFIX_SUB_STEP)Skipping cache"; \
	fi
	@ $(docker) build \
		--no-cache=$(NO_CACHE) \
		-t $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		.; \
	if [[ $${?} -eq 0 ]]; then \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Build complete"; \
	else \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)Build error"; \
		exit 1; \
	fi

clean: _prerequisites | terminate rmi

create: _prerequisites _require-docker-container-not
	@ echo "$(PREFIX_STEP)Creating container"
	@ set -x; \
	$(docker) create \
		$(DOCKER_CONTAINER_PARAMETERS) \
		$(DOCKER_PUBLISH) \
		$(DOCKER_CONTAINER_OPTS) \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created") ]]; then \
		echo "$(PREFIX_SUB_STEP)$$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created")"; \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Container created"; \
	else \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)Container creation failed"; \
		exit 1; \
	fi

dist: _prerequisites _require-docker-release-tag _require-package-path | pull
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	@ if [[ -s $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
		echo "$(PREFIX_STEP)Saving package"; \
		echo "$(PREFIX_SUB_STEP)Package path: $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Package already exists"; \
	else \
		echo "$(PREFIX_STEP)Saving package"; \
		$(docker) save \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) | \
			$(xz) -9 > \
				$($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz; \
		if [[ $${?} -eq 0 ]]; then \
			echo "$(PREFIX_SUB_STEP)Package path: $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Package saved"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Package save error"; \
			exit 1; \
		fi; \
	fi

distclean: _prerequisites _require-docker-release-tag _require-package-path | clean
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	@ if [[ -e $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
		echo "$(PREFIX_STEP)Deleting package"; \
		echo "$(PREFIX_SUB_STEP)Package path: $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
		find $($@_dist_path) \
			-name $(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz \
			-delete; \
		if [[ ! -e $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Package cleanup complete"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Package cleanup failed"; \
			exit 1; \
		fi; \
	else \
		echo "$(PREFIX_STEP)Package cleanup skipped"; \
	fi

exec: _prerequisites
	@ $(docker) exec -it $(DOCKER_NAME) $(filter-out $@, $(MAKECMDGOALS))
%:; @:

images: _prerequisites
	@ $(docker) images \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG);

help: _usage

install: | _prerequisites terminate create

logs: _prerequisites
	@ $(docker) logs $(DOCKER_NAME)

logs-delayed: _prerequisites
	@ sleep $(STARTUP_TIME)
	@ $(MAKE) logs

load: _prerequisites _require-docker-release-tag _require-package-path
	$(eval $@_dist_path := $(realpath \
		$(DIST_PATH) \
	))
	@ echo "$(PREFIX_STEP)Loading image from package"; \
	echo "$(PREFIX_SUB_STEP)Package path: $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
	if [[ ! -s $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
		echo "$(PREFIX_STEP_NEGATIVE)Package not found"; \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)To create a package try: DOCKER_IMAGE_TAG=\"$(DOCKER_IMAGE_TAG)\" make dist"; \
		exit 1; \
	else \
		$(xz) -dc $($@_dist_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz | \
			$(docker) load; \
		echo "$(PREFIX_SUB_STEP)$$(if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi;)"; \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Image loaded"; \
	fi

pause: _prerequisites _require-docker-container-status-running
	@ echo "$(PREFIX_STEP)Pausing container"
	@ $(docker) pause $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE)Container paused"

pull: _prerequisites _require-docker-image-tag
	@ echo "$(PREFIX_STEP)Pulling image from registry"
	@ $(docker) pull \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG); \
	if [[ $${?} -eq 0 ]]; then \
		echo "$(PREFIX_SUB_STEP)$$(if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi;)"; \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Image pulled"; \
	else \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)Error pulling image"; \
		exit 1; \
	fi

ps: _prerequisites _require-docker-container
	@ $(docker) ps -as --filter "name=$(DOCKER_NAME)";

restart: _prerequisites _require-docker-container _require-docker-container-not-status-paused
	@ echo "$(PREFIX_STEP)Restarting container"
	@ $(docker) restart $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE)Container restarted"

rm: _prerequisites _require-docker-container-not-status-paused
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
		echo "$(PREFIX_STEP)Container removal skipped"; \
	else \
		echo "$(PREFIX_STEP)Removing container"; \
		$(docker) rm -f $(DOCKER_NAME); \
		if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Container removed"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Container removal failed"; \
			exit 1; \
		fi; \
	fi

rmi: _prerequisites _require-docker-image-tag _require-docker-container-not
	@ if [[ -n $$(if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi;) ]]; then \
		echo "$(PREFIX_STEP)Untagging image"; \
		echo "$(PREFIX_SUB_STEP)$$(if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi;) : $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"; \
		$(docker) rmi \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null; \
		if [[ $${?} -eq 0 ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Image untagged"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Error untagging image"; \
			exit 1; \
		fi; \
	else \
		echo "$(PREFIX_STEP)Untagging image skipped"; \
	fi

run: _prerequisites _require-docker-image-tag
	@ echo "$(PREFIX_STEP)Running container"
	@ set -x; \
	$(docker) run \
		--detach \
		$(DOCKER_CONTAINER_PARAMETERS) \
		$(DOCKER_PUBLISH) \
		$(DOCKER_CONTAINER_OPTS) \
		$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
		echo "$(PREFIX_SUB_STEP)$$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running")"; \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Container running"; \
	else \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)Container run failed"; \
		exit 1; \
	fi

start: _prerequisites _require-docker-container _require-docker-container-not-status-paused
	@ echo "$(PREFIX_STEP)Starting container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]] \
		&& [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
		$(docker) start $(DOCKER_NAME) 1> /dev/null; \
	fi
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
		echo "$(PREFIX_SUB_STEP_POSITIVE)Container started"; \
	else \
		echo "$(PREFIX_SUB_STEP_NEGATIVE)Container start failed"; \
		exit 1; \
	fi

stop: _prerequisites _require-docker-container-not-status-paused _require-docker-container-status-running
	@ echo "$(PREFIX_STEP)Stopping container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
		$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
		if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=exited") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Container stopped"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Error stopping container"; \
			exit 1; \
		fi; \
	fi

terminate: _prerequisites
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
		echo "$(PREFIX_STEP)Container termination skipped"; \
	else \
		echo "$(PREFIX_STEP)Terminating container"; \
		if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
			echo "$(PREFIX_SUB_STEP)Unpausing container"; \
			$(docker) unpause $(DOCKER_NAME) 1> /dev/null; \
		fi; \
		if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_SUB_STEP)Stopping container"; \
			$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
		fi; \
		if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP)Removing container"; \
			$(docker) rm -f $(DOCKER_NAME) 1> /dev/null; \
		fi; \
		if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE)Container terminated"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE)Container termination failed"; \
			exit 1; \
		fi; \
	fi

test: _test-prerequisites
	@ if [[ -z $$(if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):latest) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):latest); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):latest); fi;) ]]; then \
		$(MAKE) build; \
	fi;
	@ echo "$(PREFIX_STEP)Functional test";
	@ SHPEC_ROOT=$(SHPEC_ROOT) $(shpec);

unpause: _prerequisites _require-docker-container-status-paused
	@ echo "$(PREFIX_STEP)Unpausing container"
	@ $(docker) unpause $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE)Container unpaused"
