.PHONY: start
start:
	docker compose up -d
	HOST=localhost make migration/up

.PHONY: dev
dev:
	docker compose -f docker-compose.dev.yml up -d
	HOST=localhost make migration/up

.PHONY: attach
attach:
	docker compose exec $(app) sh

.PHONY: stop
stop:
	docker compose down

.PHONY: migration/up
migration/up:
	docker run -t --network=host -v "$(shell pwd)/auth-plus-authentication/db:/db" ghcr.io/amacneil/dbmate:1.16 \
	--url postgres://root:db_password@$(HOST):5432/auth?sslmode=disable \
	--wait \
	--wait-timeout 60s \
	--no-dump-schema up

	docker run -t --network=host -v "$(shell pwd)/auth-plus-billing/db:/db" ghcr.io/amacneil/dbmate:1.16 \
	--url postgres://root:db_password@$(HOST):5433/billing?sslmode=disable \
	--wait \
	--wait-timeout 60s \
	--no-dump-schema up

.PHONY: clean/docker
clean/docker:
	make stop
	docker container prune -f
	docker volume prune -f
	docker image prune -f
	docker network prune -f
	rm -rf db/schema.sql
	rm -f db/schema.sql