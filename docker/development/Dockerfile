FROM ruby:2.6.2-alpine3.9

ENV BUILD_PACKAGES bash curl wget curl-dev build-base git
ENV BUILD_DEP_PACKAGES postgresql-dev nodejs-dev
ENV RUNTIME_PACKAGES bash libc6-compat nodejs gettext libintl yarn
ENV DEV_PACKAGES busybox-extras
ENV RAILS_ENV development

RUN set -euox pipefail \
        ; apk update \
        ; apk add $BUILD_PACKAGES \
        ; apk add $BUILD_DEP_PACKAGES \
        ; apk add $DEV_PACKAGES \
        ; apk add --no-cache $RUNTIME_PACKAGES \
        ; rm -rf /var/cache/apk/*

# Install Gems first for docker cache
WORKDIR /srv/primero/application
COPY [ "docker/sub.sh", "docker/development/root/", "/" ]

VOLUME /srv/primero/application
VOLUME /usr/local/bundle
CMD [ "primero-start" ]
ENTRYPOINT [ "/entrypoint.sh" ]
