SHELL := /bin/sh

COMPOSE_FILE := srcs/docker-compose.yml
ENV_FILE := srcs/.env
LOGIN ?= $(shell id -un)
DATA_DIR := /home/$(LOGIN)/data

COMPOSE := LOGIN=$(LOGIN) docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

.DEFAULT_GOAL := up

.PHONY: all prepare build up start stop restart down logs ps config clean fclean re

all: up

prepare:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

build: prepare
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d

start: prepare
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

config:
	$(COMPOSE) config

clean: down

fclean: down
	$(COMPOSE) down --rmi all --volumes --remove-orphans

re: fclean build