ARG GITEA_VERSION=1.20

# Grab the locale files from the gitea binary in the image
FROM gitea/gitea:${GITEA_VERSION}-rootless as LOCALE_SOURCE
RUN gitea embedded extract --destination /var/lib/gitea/ options/locale/**.*

# Build locale files from gitea, with WA's overrides and new keys
FROM golang:1.20 as LOCALE_BUILDER
# copy gitea's locale files
WORKDIR /merge-locale
COPY --from=LOCALE_SOURCE /var/lib/gitea/options/locale /gitea-locale
COPY merge-locale /merge-locale
COPY custom/options/locale /wa-locale
# output files to /output-locale/*.ini
RUN mkdir /output-locale
RUN go build -o localeMerger

# RUN npm install -ci
# RUN node localeMerge.js

FROM gitea/gitea:${GITEA_VERSION}-rootless

ENV GITEA_CUSTOM=/custom
COPY --from=LOCALE_BUILDER /merge-locale/localeMerger /merge-locale/localeMerger
COPY --from=LOCALE_SOURCE /var/lib/gitea/options/locale /gitea-locale
COPY merge-locale /merge-locale
COPY custom/options/locale /wa-locale

# COPY --from=LOCALE_BUILDER /output-locale/*.ini /custom/options/locale/
COPY --chown=git:git ./custom/templates /custom/templates
COPY --chown=git:git ./custom/options/locale /custom/options/locale
COPY ./custom/public /custom/public


ENV READER_BASE_LINK=read-dev.bibleineverylanguage.org

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bash", "-c", "cat /custom/templates/custom/extra_tabs.tmpl | envsubst > /tmp/extra_tabs.tmpl && mv /tmp/extra_tabs.tmpl /custom/templates/custom/extra_tabs.tmpl && /merge-locale/localeMerger && /usr/local/bin/docker-entrypoint.sh"]
