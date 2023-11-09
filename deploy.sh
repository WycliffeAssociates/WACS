#!/bin/bash

if [ -z "$DEPLOY_ENV" ]; then
  echo "Error: Please set the 'DEPLOY_ENV' environment variable."
  exit 1
fi

if [ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
  echo "Error: Please set the 'OP_SERVICE_ACCOUNT_TOKEN' environment variable."
  exit 1
fi

shopt -s expand_aliases
set -x

alias op="docker run -e OP_SERVICE_ACCOUNT_TOKEN 1password/op:2 op"

# Log in to 1password CLI

export OP_SERVICE_ACCOUNT_TOKEN=$OP_SERVICE_ACCOUNT_TOKEN

# Config vars via 1password secret refs

# MariaDB vars
export MARIADB_ROOT_PASSWORD=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/root_password")
export MARIADB_USER=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/username")
export MARIADB_PASSWORD=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/password")
export MARIADB_DATABASE=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/database")
export MARIADB_INNODB_BUFFER_POOL_SIZE=2G

# Gitea app.ini database overrides
export GITEA__database__NAME=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/database")
export GITEA__database__USER=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/username")
export GITEA__database__PASSWD=$(op read "op://wacs/wacs-mariadb/$DEPLOY_ENV/password")

# Gitea app.ini server and secret overrides
export GITEA__DEFAULT__RUN_MODE=$DEPLOY_ENV
export GITEA__server__DOMAIN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/domain")
export GITEA__server__SSH_DOMAIN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/ssh-domain")
export GITEA__server__SSH_PORT=22
export GITEA__security__SECRET_KEY=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/secret-key")
export GITEA__security__INTERNAL_TOKEN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/internal-token")
export GITEA__service__REGISTER_EMAIL_CONFIRM=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/register-email-confirm")
export GITEA__oauth2__JWT_SECRET=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/jwt-secret")

# Gitea app.ini mailer overrides
if [[ "$DEPLOY_ENV" = "prod" ]]; then
  export GITEA__mailer__ENABLED=true
  export GITEA__mailer__HOST=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/server"):$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/port number")
  export GITEA__mailer__USER=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/username")
  export GITEA__mailer__PASSWD=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/password")
fi

# Docker-compose vars
export IMAGE_TAG=$DEPLOY_ENV
export EXTERNAL_DATA_BOOL=true

docker compose down
docker compose pull gitea
docker compose up -d

#Log out of 1password CLI

unset OP_SERVICE_ACCOUNT_TOKEN