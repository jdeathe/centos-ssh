export SHELL := /usr/bin/env bash
export PATH := ${PATH}

include make.conf

# UI constants
COLOUR_NEGATIVE := \033[0;31m
COLOUR_POSITIVE := \033[0;32m
COLOUR_RESET := \033[0m
CHARACTER_STEP := --->
PREFIX_STEP := $(shell printf -- '%s ' "$(CHARACTER_STEP)")
PREFIX_SUB_STEP := $(shell printf -- ' %s ' "$(CHARACTER_STEP)")
PREFIX_STEP_NEGATIVE := $(shell printf -- '%b%s%b' "$(COLOUR_NEGATIVE)" "$(PREFIX_STEP)" "$(COLOUR_RESET)")
PREFIX_STEP_POSITIVE := $(shell printf -- '%b%s%b' "$(COLOUR_POSITIVE)" "$(PREFIX_STEP)" "$(COLOUR_RESET)")
PREFIX_SUB_STEP_NEGATIVE := $(shell printf -- '%b%s%b' "$(COLOUR_NEGATIVE)" "$(PREFIX_SUB_STEP)" "$(COLOUR_RESET)")
PREFIX_SUB_STEP_POSITIVE := $(shell printf -- '%b%s%b' "$(COLOUR_POSITIVE)" "$(PREFIX_SUB_STEP)" "$(COLOUR_RESET)")

.DEFAULT_GOAL := build

# Get absolute file paths
PACKAGE_PATH := $(realpath $(PACKAGE_PATH))

# Package prerequisites
docker := $(shell type -p docker)
xz := $(shell type -p xz)

# Used to test docker host is accessible
get-docker-info := $(shell $(docker) info)

# Tag validation
IS_DOCKER_IMAGE_TAG := $(shell if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi)
IS_DOCKER_RELEASE_TAG := $(shell if [[ $(DOCKER_IMAGE_TAG) =~ $(DOCKER_IMAGE_RELEASE_TAG_PATTERN) ]]; then echo $(DOCKER_IMAGE_TAG); else echo ''; fi)

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
	pause \
	prerequisites \
	pull \
	ps \
	require-docker-container \
	require-docker-image-tag \
	require-docker-release-tag \
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

clean: prerequisites | terminate rm rmi

create: prerequisites
	@ echo "$(PREFIX_STEP) Creating container"
	@ set -x; $(docker) create \
			--name $(DOCKER_NAME) \
			--publish $(DOCKER_HOST_PORT_SSH):22 \
			--restart $(DOCKER_RESTART_POLICY) \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created") ]]; then \
			echo "$(PREFIX_SUB_STEP) $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=created")"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container created"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container creation failed"; \
			exit 1; \
		fi

dist: prerequisites require-docker-release-tag | pull
	@ if [[ -s $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP) Saving package"; \
			echo "$(PREFIX_SUB_STEP) Package path: $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Package already exists"; \
		else \
			if [[ ! -d $(PACKAGE_PATH) ]]; then \
				echo "$(PREFIX_STEP) Creating package directory"; \
				mkdir -p $(PACKAGE_PATH); \
			fi; \
			echo "$(PREFIX_STEP) Saving package"; \
			$(docker) save \
				$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) | \
				$(xz) -9 > \
					$(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz; \
				if [[ $${?} -eq 0 ]]; then \
					echo "$(PREFIX_SUB_STEP) Package path: $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
					echo "$(PREFIX_SUB_STEP_POSITIVE) Package saved"; \
				else \
					echo "$(PREFIX_SUB_STEP_NEGATIVE) Package save error"; \
					exit 1; \
				fi; \
		fi

distclean: prerequisites require-docker-release-tag | clean
	@ if [[ -e $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP) Deleting $(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz package"; \
			find $(PACKAGE_PATH) \
				-name $(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz \
				-delete; \
		fi
	@ if [[ -e $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Package cleanup failed"; \
			exit 1; \
		else \
			echo "$(PREFIX_STEP_POSITIVE) Package cleanup complete"; \
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

load: prerequisites require-docker-release-tag
	@ echo "$(PREFIX_STEP) Loading image from package"; \
		echo "$(PREFIX_SUB_STEP) Package path: $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz"; \
		if [[ ! -s $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz ]]; then \
			echo "$(PREFIX_STEP_NEGATIVE) Package not found"; \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) To create a package try: DOCKER_IMAGE_TAG=\"$(DOCKER_IMAGE_TAG)\" make dist"; \
			exit 1; \
		else \
			$(xz) -dc $(PACKAGE_PATH)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tar.xz | \
				$(docker) load; \
			echo "$(PREFIX_SUB_STEP) $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG))"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Image loaded"; \
		fi

pause: prerequisites require-docker-container
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
			echo "$(PREFIX_SUB_STEP) $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG))"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Image pulled"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Error pulling image"; \
			exit 1; \
		fi

ps: prerequisites require-docker-container
	@ $(docker) ps -as --filter "name=$(DOCKER_NAME)";

require-docker-container:
ifeq ($(shell $(docker) ps -aq --filter "name=$(DOCKER_NAME)"),)
	$(error "This operation requires the $(DOCKER_NAME) docker container. Install it with: make install")
endif

require-docker-image-tag:
ifeq ($(IS_DOCKER_IMAGE_TAG),)
	$(error "Invalid DOCKER_IMAGE_TAG value $(DOCKER_IMAGE_TAG).")
endif

require-docker-release-tag:
ifeq ($(IS_DOCKER_RELEASE_TAG),)
	$(error "Invalid DOCKER_IMAGE_TAG value $(DOCKER_IMAGE_TAG). A release tag is required for this operation.")
endif

restart: prerequisites require-docker-container
	@ echo "$(PREFIX_STEP) Restarting container"
	@ $(docker) restart $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE) Container restarted"

rm: prerequisites
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_STEP) Removing container"; \
			$(docker) rm -f $(DOCKER_NAME); \
		fi
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container removed"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container removal failed"; \
			exit 1; \
		fi

rmi: prerequisites require-docker-image-tag
	@ if [[ -n $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) ]]; then \
			echo "$(PREFIX_STEP) Untagging image"; \
			echo "$(PREFIX_SUB_STEP) $$($(docker) images -q $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)) : $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"; \
			$(docker) rmi \
				$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null; \
			if [[ $${?} -eq 0 ]]; then \
				echo "$(PREFIX_SUB_STEP_POSITIVE) Image untagged"; \
			else \
				echo "$(PREFIX_SUB_STEP_NEGATIVE) Error untagging image"; \
				exit 1; \
			fi; \
		fi

run: prerequisites require-docker-image-tag
	@ echo "$(PREFIX_STEP) Running container"
	@ set -x; $(docker) run \
			--detach \
			--name $(DOCKER_NAME) \
			--publish $(DOCKER_HOST_PORT_SSH):22 \
			--restart $(DOCKER_RESTART_POLICY) \
			$(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) 1> /dev/null;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_SUB_STEP) $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running")"; \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container running"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container run failed"; \
			exit 1; \
		fi

start: prerequisites require-docker-container 
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

stop: prerequisites
	@ echo "$(PREFIX_STEP) Stopping container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]] \
			&& [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
		fi;
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]] \
			&& [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=exited") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container stopped"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Error stopping container"; \
			exit 1; \
		fi

terminate: prerequisites
ifneq ($(shell $(docker) ps -aq --filter "name=$(DOCKER_NAME)"),)
	@ echo "$(PREFIX_STEP) Terminating container"
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=paused") ]]; then \
			echo "$(PREFIX_SUB_STEP) Unpausing container"; \
			$(docker) unpause $(DOCKER_NAME) 1> /dev/null; \
		fi
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)" --filter "status=running") ]]; then \
			echo "$(PREFIX_SUB_STEP) Stopping container"; \
			$(docker) stop $(DOCKER_NAME) 1> /dev/null; \
		fi
	@ if [[ -n $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP) Removing container"; \
			$(docker) rm -f $(DOCKER_NAME) 1> /dev/null; \
		fi
	@ if [[ -z $$($(docker) ps -aq --filter "name=$(DOCKER_NAME)") ]]; then \
			echo "$(PREFIX_SUB_STEP_POSITIVE) Container terminated"; \
		else \
			echo "$(PREFIX_SUB_STEP_NEGATIVE) Container termination failed"; \
			exit 1; \
		fi
else
	@ echo "$(PREFIX_STEP) Container termination skipped"
endif

unpause: prerequisites require-docker-container
	@ echo "$(PREFIX_STEP) Unpausing container"
	@ $(docker) unpause $(DOCKER_NAME) 1> /dev/null
	@ echo "$(PREFIX_SUB_STEP_POSITIVE) Container unpaused"
