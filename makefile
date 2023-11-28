.PHONY: build
build:
	export IMAGE_TAG="local" \
	&& cd wacs-gitea \
	&& docker build -t wycliffeassociates/wacs:$${IMAGE_TAG} .

.PHONY: build-nocache
build:
	export IMAGE_TAG="local" \
	&& cd wacs-gitea \
	&& docker build --no-cache -t wycliffeassociates/wacs:$${IMAGE_TAG} .

.PHONY: run
run:
	export IMAGE_TAG="local" \
	&& docker compose up -d

.PHONY: build-run
build-run: build
	export IMAGE_TAG="local" \
	&& docker compose up -d

# Use this when started locally to create a user that you can log in as. username: admin2 password: 1234
.PHONY: admin-user
admin-user:
	docker compose exec gitea /usr/local/bin/gitea -c '/etc/gitea/app.ini' admin user create --username admin2 --password 1234 --email asdf@example.com --admin

.PHONY: down
down: 
	docker compose down

.PHONY: clean
clean:
	docker compose down -v

.PHONY: logs
logs:
	docker compose logs -f

# Rebuild and restart gitea container only
.PHONY: reload-gitea
reload-gitea: build
	export IMAGE_TAG="local" \
	&& docker compose stop gitea \
	&& docker compose up gitea -d