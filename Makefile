export SHELL := /usr/bin/env bash
export PATH := ${PATH}

include environment.mk
include default.mk

# UI constants
COLOUR_NEGATIVE := \033[1;31m
COLOUR_POSITIVE := \033[1;32m
COLOUR_RESET := \033[0m
CHARACTER_STEP := --->
PREFIX_STEP := $(shell printf -- '%s ' "$(CHARACTER_STEP)")
PREFIX_SUB_STEP := $(shell printf -- ' %s ' "$(CHARACTER_STEP)")
PREFIX_STEP_NEGATIVE := $(shell printf -- '%b%s%b' "$(COLOUR_NEGATIVE)" "$(PREFIX_STEP)" "$(COLOUR_RESET)")
PREFIX_STEP_POSITIVE := $(shell printf -- '%b%s%b' "$(COLOUR_POSITIVE)" "$(PREFIX_STEP)" "$(COLOUR_RESET)")
PREFIX_SUB_STEP_NEGATIVE := $(shell printf -- '%b%s%b' "$(COLOUR_NEGATIVE)" "$(PREFIX_SUB_STEP)" "$(COLOUR_RESET)")
PREFIX_SUB_STEP_POSITIVE := $(shell printf -- '%b%s%b' "$(COLOUR_POSITIVE)" "$(PREFIX_SUB_STEP)" "$(COLOUR_RESET)")

.DEFAULT_GOAL := build

# Package prerequisites
docker := $(shell type -p docker)
xz := $(shell type -p xz)

# Used to test docker host is accessible
get-docker-info := $(shell $(docker) info)

.PHONY: \
	all \
	build \
	clean \
	create \
	dist \
	distclean \
	exec \
	install \
	images \
	load \
	logs \
	logs-delayed \
	pause \
	prerequisites \
	pull \
	ps \
	require-docker-container \
	require-docker-container-not \
	require-docker-container-not-status-paused \
	require-docker-container-status-created \
	require-docker-container-status-exited \
	require-docker-container-status-paused \
	require-docker-container-status-running \
	require-docker-image-tag \
	require-docker-release-tag \
	require-package-path \
	restart \
	rm \
	rmi \
	run \
	start \
	stop \
	terminate \
	unpause

all: prerequisites | build images install start ps

# build NO_CACHE=[{false,true}]
build: prerequisites require-docker-image-tag
	@ echo "$(PREFIX_STEP) Building $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"
	@ if [[ $(NO_CACHE) == true ]]; then \
			echo "$(PREFIX_SUB_STEP) Skipping cache"; \
		fi
	@ $(docker) build \
			--no-cache=$(NO_CACHE) \
			-t $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
			.; \
		if [[ $${?} -eq 0 ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Build complete"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Build error"; \
			exit 1; \
		fi

clean: prerequisites | terminate rmi

create: prerequisites require-docker-container-not
	@ echo "$(PREFIX_STEP) Creating container"
	@ set -x; \
		$(docker) create \
			$(DOCKER_CONTAINER_PARAMETERS) \
			$(DOCKER_CONTAINER_PARAMETERS_APPEND) \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created") ]]; then \
			echo "$(PREFIX_SUB_STEP) $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created")"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container created"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container creation failed"; \
			exit 1; \
		fi

dist: prerequisites require-docker-release-tag require-package-path | pull
	$(eval $@_package_path := $(realpath \
		$(PACKAGE_PATH) \
	))
	@ if [[ -s $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP) Saving package"; \
			echo "$(PREFIX_SUB_STEP) Package path: $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Package already exists"; \
		else \
			echo "$(PREFIX_STEP) Saving package"; \
			$(docker) save \
				$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) | \
				$(xz) -9 > \
					$($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz; \
				if [[ $${?} -eq 0 ]]; then \
					echo "$(PREFIX_SUB_STEP) Package path: $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
					echo "$(PREFIX_SUB_STEP_POSITIVE) Package saved"; \
				else \
					echo "$(PREFIX_SUB_STEP_NEGATIVE) Package save error"; \
					exit 1; \
				fi; \
		fi

distclean: prerequisites require-docker-release-tag require-package-path | clean
	$(eval $@_package_path := $(realpath \
		$(PACKAGE_PATH) \
	))
	@ if [[ -e $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP) Deleting package"; \
			echo "$(PREFIX_SUB_STEP) Package path: $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
			find $($@_package_path) \
				-name $(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz \
				-delete; \
			if [[ ! -e $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
				echo "$(PREFIX_SUB_STEP_POSITIVE) Package cleanup complete"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Package cleanup failed"; \
				exit 1; \
			fi; \
		else \
			echo "$(PREFIX_STEP) Package cleanup skipped"; \
		fi

exec: prerequisites
	@ $(docker) exec -it $(DOCKER_NAME) $(filter-out $@, $(MAKECMDGOALS))
%:; @:

images: prerequisites
	@ $(docker) images \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG);

install: | prerequisites terminate create

logs: prerequisites
	@ $(docker) logs $(DOCKER_NAME)

logs-delayed: prerequisites
	@ sleep 2
	@ $(MAKE) logs

load: prerequisites require-docker-release-tag require-package-path
	$(eval $@_package_path := $(realpath \
		$(PACKAGE_PATH) \
	))
	@ echo "$(PREFIX_STEP) Loading image from package"; \
		echo "$(PREFIX_SUB_STEP) Package path: $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
		if [[ ! -s $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Package not found"; \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) To create a package try: DOCKER_IMAGE_TAG=\"$(DOCKER_IMAGE_TAG)\" make dist"; \
			exit 1; \
		else \
			$(xz) -dc $($@_package_path)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz | \
				$(docker) load; \
			echo "$(PREFIX_SUB_STEP) $$( if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi; )"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Image loaded"; \
		fi

pause: prerequisites require-docker-container-status-running
	@ echo "$(PREFIX_STEP) Pausing container"
	@ $(docker) pause $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE) Container paused"

prerequisites:
ifeq ($(docker),)
	$(error "Please install the docker (docker-engine) package.")
endif

ifeq ($(xz),)
	$(error "Please install the xz package.")
endif

ifeq ($(get-docker-info),)
	$(error "Unable to connect to docker host.")
endif

pull: prerequisites require-docker-image-tag
	@ echo "$(PREFIX_STEP) Pulling image from registry"
	@ $(docker) pull \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG); \
		if [[ $${?} -eq 0 ]]; then \
			echo "$(PREFIX_SUB_STEP) $$( if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi; )"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Image pulled"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Error pulling image"; \
			exit 1; \
		fi

ps: prerequisites require-docker-container
	@ $(docker) ps -as --filter "name=$(DOCKER_NAME)";

require-docker-container:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container."; \
			echo "$(PREFIX_SUB_STEP) Try installing it with: make install"; \
			exit 1; \
		fi

require-docker-container-not:
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container be removed (or renamed)."; \
			echo "$(PREFIX_SUB_STEP) Try removing it with: make rm"; \
			exit 1; \
		fi

require-docker-container-not-status-paused:
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container to be unpaused."; \
			echo "$(PREFIX_SUB_STEP) Try unpausing it with: make unpause"; \
			exit 1; \
		fi

require-docker-container-status-created:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container to be created."; \
			echo "$(PREFIX_SUB_STEP) Try installing it with: make install"; \
			exit 1; \
		fi

require-docker-container-status-exited:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=exited") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container to be exited."; \
			echo "$(PREFIX_SUB_STEP) Try stopping it with: make stop"; \
			exit 1; \
		fi

require-docker-container-status-paused:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container to be paused."; \
			echo "$(PREFIX_SUB_STEP) Try pausing it with: make pause"; \
			exit 1; \
		fi

require-docker-container-status-running:
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) This operation requires the $(DOCKER_NAME) docker container to be running."; \
			echo "$(PREFIX_SUB_STEP) Try starting it with: make start"; \
			exit 1; \
		fi

require-docker-image-tag:
	@ if [[ -z $$(if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi) ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Invalid DOCKER_IMAGE_TAG value: $(DOCKER_IMAGE_TAG)"; \
			exit 1; \
		fi

require-docker-release-tag:
	@ if [[ -z $$(if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_RELEASE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi) ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Invalid DOCKER_IMAGE_TAG value: $(DOCKER_IMAGE_TAG)"; \
			echo "$(PREFIX_SUB_STEP) A release tag is required for this operation."; \
			exit 1; \
		fi

require-package-path:
	@ if [[ -n $(PACKAGE_PATH) ]] && [[ ! -d $(PACKAGE_PATH) ]]; then \
			echo "$(PREFIX_STEP) Creating package directory"; \
			mkdir -p $(PACKAGE_PATH); \
		fi; \
		if [[ ! $${?} -eq 0 ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Failed to make package path: $(PACKAGE_PATH)"; \
			exit 1; \
		elif [[ -z $(PACKAGE_PATH) ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Undefined PACKAGE_PATH"; \
			exit 1; \
		fi

restart: prerequisites require-docker-container require-docker-container-not-status-paused
	@ echo "$(PREFIX_STEP) Restarting container"
	@ $(docker) restart $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE) Container restarted"

rm: prerequisites require-docker-container-not-status-paused
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_STEP) Container removal skipped"; \
		else \
		  echo "$(PREFIX_STEP) Removing container"; \
			$(docker) rm -f $(DOCKER_NAME); \
			if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
					echo "$(PREFIX_SUB_STEP_POSITIVE) Container removed"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Container removal failed"; \
				exit 1; \
			fi; \
		fi

rmi: prerequisites require-docker-image-tag require-docker-container-not
	@ if [[ -n $$( if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi; ) ]]; then \
			echo "$(PREFIX_STEP) Untagging image"; \
			echo "$(PREFIX_SUB_STEP) $$( if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then echo $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); else echo $$($(docker) images -q docker.io/$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)); fi; ) : $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"; \
			$(docker) rmi \
				$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null; \
			if [[ $${?} -eq 0 ]]; then \
				echo "$(PREFIX_SUB_STEP_POSITIVE) Image untagged"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Error untagging image"; \
				exit 1; \
			fi; \
		else \
			echo "$(PREFIX_STEP) Untagging image skipped"; \
		fi

run: prerequisites require-docker-image-tag
	@ echo "$(PREFIX_STEP) Running container"
	@ set -x; \
		$(docker) run \
			--detach \
			$(DOCKER_CONTAINER_PARAMETERS) \
			$(DOCKER_CONTAINER_PARAMETERS_APPEND) \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_SUB_STEP) $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running")"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container running"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container run failed"; \
			exit 1; \
		fi

start: prerequisites require-docker-container require-docker-container-not-status-paused
	@ echo "$(PREFIX_STEP) Starting container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]] \
			&& [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			$(docker) start $(DOCKER_NAME) 1> /dev/null; \
		fi
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container started"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container start failed"; \
			exit 1; \
		fi

stop: prerequisites require-docker-container-not-status-paused require-docker-container-status-running
	@ echo "$(PREFIX_STEP) Stopping container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
			if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=exited") ]]; then \
				echo "$(PREFIX_SUB_STEP_POSITIVE) Container stopped"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Error stopping container"; \
				exit 1; \
			fi; \
		fi

terminate: prerequisites
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_STEP) Container termination skipped"; \
		else \
			echo "$(PREFIX_STEP) Terminating container"; \
			if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
				echo "$(PREFIX_SUB_STEP) Unpausing container"; \
				$(docker) unpause $(DOCKER_NAME) 1> /dev/null; \
			fi; \
			if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
				echo "$(PREFIX_SUB_STEP) Stopping container"; \
				$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
			fi; \
			if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
				echo "$(PREFIX_SUB_STEP) Removing container"; \
				$(docker) rm -f $(DOCKER_NAME) 1> /dev/null; \
			fi; \
			if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
				echo "$(PREFIX_SUB_STEP_POSITIVE) Container terminated"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Container termination failed"; \
				exit 1; \
			fi; \
		fi

unpause: prerequisites require-docker-container-status-paused
	@ echo "$(PREFIX_STEP) Unpausing container"
	@ $(docker) unpause $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE) Container unpaused"
