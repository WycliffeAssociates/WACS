ARG GITEA_VERSION=1.23.7

# Grab the locale files from the gitea binary in the image
FROM gitea/gitea:${GITEA_VERSION}-rootless as LOCALE_SOURCE
RUN gitea embedded extract --destination /var/lib/gitea/ options/locale/**.*

# Build locale files from gitea, with WA's overrides and new keys
FROM golang:1.20 as LOCALE_BUILDER
WORKDIR /merge-locale
COPY --from=LOCALE_SOURCE /var/lib/gitea/options/locale /gitea-locale
COPY merge-locale /merge-locale
COPY custom/options/locale /wa-locale
RUN mkdir /output-locale
RUN go build -o localeMerger
RUN /merge-locale/localeMerger

FROM gitea/gitea:${GITEA_VERSION}-rootless
USER root
RUN deluser \
        git && \
    addgroup \
        -S -g 1002 \
        git && \
    adduser \
        -S -H -D \
        -h /var/lib/gitea/git \
        -s /bin/bash \
        -u 1001 \
        -G git \
        git

# create the dirs that gitea needs and make our user owner. /config is where the gitea config file will live.
RUN mkdir -p /var/lib/gitea /etc/gitea /config
RUN chown git:git /var/lib/gitea /etc/gitea /config

# git:git
USER 1001:1002

# The parent image makes /etc/gitea a volume. We don't want to store the config in a volume, so we put it in /config
# The docker-compose.yml should have a gitea-config volume mapped to /etc/gitea, but there won't be anything in it.
ENV GITEA_APP_INI /config/app.ini
ENV GITEA_CUSTOM=/custom
# This ENV is functional, but it is here as an example of what the value should be at runtime
ENV READER_BASE_LINK=https://read-dev.bibleineverylanguage.org/

# COPY's need permissions set for rootless
COPY --chown=1001:1002 --from=LOCALE_BUILDER /output-locale/*.ini /custom/options/locale/
COPY --chown=1001:1002 ./custom/templates /custom/templates
COPY --chown=1001:1002 ./custom/public /custom/public

# dumb-init for clean startup and shutdown as per the parent image.
# Startup is done this way to still use dumb-init like the parent image; this is how dumb-init suggests to do it.
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Cat feeds the extra_tabs.tmpl file into envsubst
# envsubst replaces the env vars in the file with the values from the environment and writes out a temp file
# Temp file is then moved to the real location
# Gitea entrypoint starts gitea
CMD ["sh", "-c", "cat /custom/templates/custom/extra_tabs.tmpl | envsubst > /tmp/extra_tabs.tmpl && mv /tmp/extra_tabs.tmpl /custom/templates/custom/extra_tabs.tmpl && /usr/local/bin/docker-entrypoint.sh"]
