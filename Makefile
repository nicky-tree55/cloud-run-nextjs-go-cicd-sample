.PHONY: build
build:
	docker compose build --no-cache

.PHONY: up
up:
	docker compose up -d

.PHONY: stop
stop:
	docker compose stop

.PHONY: down
down:
	docker compose down

.PHONY: init-start
init-start:
	@make init
	@make start

.PHONY: init
init:
	@make build
	@make front-install

.PHONY: dev
dev:
	@make up
	@make front-install
	@make web-npm-dev

.PHONY: start
start:
	@make web-npm-build
	@make up
	@make web-npm-start

.PHONY: front-init
front-init:
	@make front-build
	@make front-install
	@make front-up

.PHONY: front-restart
front-restart:
	@make front-down
	@make front-up

.PHONY: front-build
front-build:
	docker compose build --no-cache frontend

.PHONY: front-build-with-cache
front-build-with-cache:
	docker compose build frontend

.PHONY: front-up
front-up:
	docker compose up -d frontend

.PHONY: front-stop
front-stop:
	docker compose stop frontend

.PHONY: front-down
front-down:
	docker compose down frontend

.PHONY: npm-install
npm-install:
	docker compose run --rm frontend npm install

.PHONY: front-cache-check
front-cache-check:
	docker compose run --rm frontend yarn check --verify-tree

.PHONY: web-yarn-build
web-yarn-build:
	docker compose run --rm frontend yarn build

.PHONY: web-yarn-start
web-yarn-start:
	docker compose exec frontend yarn start

.PHONY: web-npm-dev
web-npm-dev:
	docker compose exec frontend npm run dev

.PHONY: web-npm-build
web-npm-build:
	docker compose run --rm frontend npm run build

.PHONY: web-npm-start
 web-npm-start:
	docker compose exec frontend npm run start

.PHONY: web-serverjs
web-serverjs:
	docker compose exec frontend node .next/standalone/server.js

.PHONY: back-init
back-init:
	@make back-build
	@make back-up

.PHONY: back-restart
back-restart:
	@make back-down
	@make back-up

.PHONY: back-build
back-build:
	docker compose build --no-cache backend

.PHONY: back-build-with-cache
back-build-with-cache:
	docker compose build backend

.PHONY: go-mod-tidy
go-mod-tidy:
	docker compose run --rm backend go mod tidy

.PHONY: back-up
back-up:
	docker compose up -d backend

.PHONY: back-stop
back-stop:
	docker compose stop backend

.PHONY: back-down
back-down:
	docker compose down backend

include .env
NETWORK_NAME=network-prod

.PHONY: prod-init-start
prod-init-start:
	@make prod-init
	@make prod-start

.PHONY: prod-init
prod-init:
	@make prod-network-create
	@make prod-back-build
	@make prod-front-build

.PHONY: prod-init-with-cache
prod-init-with-cache:
	@make prod-network-create
	@make prod-back-build-with-cache
	@make prod-front-build-with-cache

.PHONY: prod-start
prod-start:
	@make prod-back-run
	@make prod-front-run

.PHONY: prod-stop
prod-stop:
	@make prod-back-stop
	@make prod-front-stop

.PHONY: prod-down
prod-down:
	@make prod-back-stop
	@make prod-front-stop
	@make prod-back-down
	@make prod-front-down
	@make prod-network-remove

.PHONY: prod-back-build
prod-back-build:
	docker build --no-cache -t backend-prod --build-arg API_PORT=${BACKEND_PORT} ./backend
.PHONY: prod-back-build-with-cache
prod-back-build-with-cache:
	docker build -t backend-prod --build-arg API_PORT=${BACKEND_PORT} ./backend
.PHONY: prod-back-run
prod-back-run:
	docker run --rm --name backend-prod -d -p ${BACKEND_PORT}:8080 --network $(NETWORK_NAME) backend-prod
.PHONY: prod-back-stop
prod-back-stop:
	docker stop backend-prod
.PHONY: prod-back-down
prod-back-down:
	docker rmi -f backend-prod

.PHONY: prod-front-build
prod-front-build:
	docker build --no-cache -t frontend-prod --build-arg NEXT_PUBLIC_API_URL=http://backend-prod:8081 ./frontend
.PHONY: prod-front-build-with-cache
prod-front-build-with-cache:
	docker build -t frontend-prod --build-arg NEXT_PUBLIC_API_URL=http://backend-prod:8081 ./frontend
.PHONY: prod-front-run
prod-front-run:
	docker run --rm --init --name frontend-prod -d -p ${FRONTEND_PORT}:3000 --network $(NETWORK_NAME) frontend-prod
.PHONY: prod-front-stop
prod-front-stop:
	docker stop frontend-prod
.PHONY: prod-front-down
prod-front-down:
	docker rmi -f frontend-prod 


.PHONY: prod-network-create
prod-network-create:
	@if [ -z "$$(docker network ls --filter name=^$(NETWORK_NAME)$$ --format='{{ .Name }}')" ]; then \
		docker network create --driver=bridge $(NETWORK_NAME); \
		echo "$(NETWORK_NAME) created"; \
	else \
		echo "$(NETWORK_NAME) already exists"; \
	fi
.PHONY: prod-network-remove
prod-network-remove:
	docker network rm $(NETWORK_NAME)