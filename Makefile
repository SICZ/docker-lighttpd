### BASE_IMAGE #################################################################

BASE_IMAGE_NAME		?= $(DOCKER_PROJECT)/baseimage-alpine
BASE_IMAGE_TAG		?= 3.8

### DOCKER_IMAGE ###############################################################

LIGHTTPD_VERSION	?= 1.4.49

DOCKER_PROJECT		?= sicz
DOCKER_PROJECT_DESC	?= A lighttpd web server based on Alpine Linux
DOCKER_PROJECT_URL	?= https://www.lighttpd.net

DOCKER_NAME		?= lighttpd
DOCKER_IMAGE_TAG	?= $(LIGHTTPD_VERSION)
DOCKER_IMAGE_TAGS	?= latest

### BUILD ######################################################################

# Docker image build variables
BUILD_VARS		+= LIGHTTPD_VERSION

### DOCKER_EXECUTOR ############################################################

# Use the Docker Compose executor
DOCKER_EXECUTOR		?= compose

# Variables used in the Docker Compose file
COMPOSE_VARS		+= SERVER_CRT_HOST \
			   SERVICE_NAME \
			   SIMPLE_CA_IMAGE

# Certificate subject aletrnative names
SERVER_CRT_HOST		?= $(SERVICE_NAME).local

### SIMPLE_CA ##################################################################

# Docker image dependencies
DOCKER_IMAGE_DEPENDENCIES += $(SIMPLE_CA_IMAGE)

# Simple CA image
SIMPLE_CA_NAME		?= simple-ca
SIMPLE_CA_IMAGE_NAME	?= $(DOCKER_PROJECT)/$(SIMPLE_CA_NAME)
SIMPLE_CA_IMAGE_TAG	?= latest
SIMPLE_CA_IMAGE		?= $(SIMPLE_CA_IMAGE_NAME):$(SIMPLE_CA_IMAGE_TAG)

# Simple CA service name in Docker Compose file
SIMPLE_CA_SERVICE_NAME	?= $(shell echo $(SIMPLE_CA_NAME) | sed -E -e "s/[^[:alnum:]_]+/_/g")

### MAKE_VARS ##################################################################

# Display the make variables
MAKE_VARS		?= GITHUB_MAKE_VARS \
			   BASE_IMAGE_MAKE_VARS \
			   DOCKER_IMAGE_MAKE_VARS \
			   BUILD_MAKE_VARS \
			   EXECUTOR_MAKE_VARS \
			   CONFIG_MAKE_VARS \
			   SHELL_MAKE_VARS \
			   DOCKER_REGISTRY_MAKE_VARS

define CONFIG_MAKE_VARS
LIGHTTPD_VERSION:	$(LIGHTTPD_VERSION)

SIMPLE_CA_IMAGE_NAME:	$(SIMPLE_CA_IMAGE_NAME)
SIMPLE_CA_IMAGE_TAG:	$(SIMPLE_CA_IMAGE_TAG)
SIMPLE_CA_IMAGE:	$(SIMPLE_CA_IMAGE)

SERVER_CRT_HOST:	$(SERVER_CRT_HOST)
endef
export CONFIG_MAKE_VARS

### MAKE_TARGETS ###############################################################

# Build a new image and run the tests
.PHONY: all
all: clean build start wait logs test

# Build a new image and run the tests
.PHONY: ci
ci: all
	@$(MAKE) clean

### BUILD_TARGETS ##############################################################

# Build a new image with using the Docker layer caching
.PHONY: build
build: docker-build

# Build a new image without using the Docker layer caching
.PHONY: rebuild
rebuild: docker-rebuild

### EXECUTOR_TARGETS ###########################################################

# Display the configuration file
.PHONY: config-file
config-file: display-config-file

# Display the make variables
.PHONY: makevars vars
makevars vars: display-makevars

# Remove the containers and then run them fresh
.PHONY: run up
run up: docker-up

# Create the containers
.PHONY: create
create: docker-create .docker-$(DOCKER_EXECUTOR)-create-www

.docker-$(DOCKER_EXECUTOR)-create-www:
	@$(ECHO) "Copying spec/fixtures/www to $(CONTAINER_NAME):/var/www"
	@docker cp $(TEST_DIR)/spec/fixtures/www/index.html $(CONTAINER_NAME):/var/www
	@$(ECHO) $(CONTAINER_NAME) > $@

# Start the containers
.PHONY: start
start: create docker-start

# Wait for the start of the containers
.PHONY: wait
wait: start docker-wait

# Display running containers
.PHONY: ps
ps: docker-ps

# Display the container logs
.PHONY: logs
logs: docker-logs

# Follow the container logs
.PHONY: logs-tail tail
logs-tail tail: docker-logs-tail

# Run shell in the container
.PHONY: shell sh
shell sh: start docker-shell

# Run the tests
.PHONY: test
test: start docker-test

# Run the shell in the test container
.PHONY: test-shell tsh
test-shell tsh:
	@$(MAKE) test TEST_CMD=/bin/bash

# Stop the containers
.PHONY: stop
stop: docker-stop

# Restart the containers
.PHONY: restart
restart: stop start

# Remove the containers
.PHONY: down rm
down rm: docker-rm

# Remove all containers and work files
.PHONY: clean
clean: docker-clean

### MK_DOCKER_IMAGE ############################################################

PROJECT_DIR		?= $(CURDIR)
MK_DIR			?= $(PROJECT_DIR)/../Mk
include $(MK_DIR)/docker.image.mk

################################################################################
