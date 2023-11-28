ARG GITEA_VERSION=1.21

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

ENV GITEA_CUSTOM=/custom
# This ENV is functional, but it is here as an example of what the value should be at runtime
ENV READER_BASE_LINK=https://read-dev.bibleineverylanguage.org/

# COPY's need permissions set for rootless
COPY --chown=git:git --from=LOCALE_BUILDER /output-locale/*.ini /custom/options/locale/
COPY --chown=git:git ./custom/templates /custom/templates
COPY --chown=git:git ./custom/public /custom/public

# dumb-init for clean startup and shutdown as per the parent image.
# Startup is done this way to still use dumb-init like the partent image; this is how dumb-init suggests to do it.
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Cat feeds the extra_tabs.tmpl file into envsubst
# envsubst replaces the env vars in the file with the values from the environment and writes out a temp file
# Temp file is then moved to the real location
# Gitea entrypoint starts gitea
CMD ["sh", "-c", "cat /custom/templates/custom/extra_tabs.tmpl | envsubst > /tmp/extra_tabs.tmpl && mv /tmp/extra_tabs.tmpl /custom/templates/custom/extra_tabs.tmpl && /usr/local/bin/docker-entrypoint.sh"]