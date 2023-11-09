ARG GITEA_VERSION=1.20

FROM gitea/gitea:${GITEA_VERSION} as SOURCE

FROM node:19 as LOCALE

COPY --from=SOURCE /var/lib/gitea/custom/options/locale /locale-vanilla

RUN some-script-to-edit-the-locales.js #outputs files to /locale/*.ini

FROM gitea/gitea:${GITEA_VERSION}

COPY --from=LOCALE /locale /custom/options/locale





