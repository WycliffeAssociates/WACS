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
export GITEA____RUN_MODE=$DEPLOY_ENV
export GITEA__server__DOMAIN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/domain")
export GITEA__server__SSH_DOMAIN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/ssh-domain")
export GITEA__server__SSH_PORT=22
export GITEA__security__SECRET_KEY=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/secret-key")
export GITEA__security__INTERNAL_TOKEN=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/internal-token")
export GITEA__service__REGISTER_EMAIL_CONFIRM=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/register-email-confirm")
export GITEA__oauth2__JWT_SECRET=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/jwt-secret")
export GITEA__service__CAPTCHA_TYPE=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/GITEA__service__CAPTCHA_TYPE")
export GITEA__service__CF_TURNSTILE_SECRET=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/GITEA__service__CF_TURNSTILE_SECRET")
export GITEA__service__CF_TURNSTILE_SITEKEY=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/GITEA__service__CF_TURNSTILE_SITEKEY")
export GITEA__log__LEVEL=$(op read "op://wacs/wacs-gitea-secrets/$DEPLOY_ENV/GITEA__log__LEVEL")

# Gitea app.ini mailer overrides
if [[ "$DEPLOY_ENV" = "prod" ]]; then
  export GITEA__mailer__ENABLED=true
  export GITEA__mailer__SMTP_ADDR=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/server")
  export GITEA__mailer__SMTP_PORT=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/port number")
  export GITEA__mailer__USER=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/username")
  export GITEA__mailer__FROM=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/username")
  export GITEA__mailer__PASSWD=$(op read "op://Shared-IT-Development/d52sfisg5cry5yfpj2lynfq3ru/password")
  export READER_BASE_LINK=read.bibletranslationtools.org
fi

# Docker-compose vars
export IMAGE_TAG=$DEPLOY_ENV
export EXTERNAL_DATA_BOOL=true

docker compose down
docker compose pull gitea
docker compose up -d

#Log out of 1password CLI

unset OP_SERVICE_ACCOUNT_TOKEN