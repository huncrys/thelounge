# syntax=docker/dockerfile:1

FROM node:22-alpine AS base

FROM --platform=$BUILDPLATFORM base AS builder

RUN --mount=type=cache,target=/var/cache/apk \
	apk add -uU git

WORKDIR /thelounge-src

COPY package.json yarn.lock ./

RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
	yarn --non-interactive --production=false install

COPY . .

RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
	yarn --non-interactive build && \
	npm pack && \
	find . -type f -name "thelounge-*.tgz" -exec mv "{}" "/thelounge.tgz" \; -quit

FROM base

ENV NODE_ENV=production
ENV THELOUNGE_HOME="/config"

VOLUME /config

# No yarn cache mount here: this package's version isn't bumped per release, so a
# persistent cache keyed by name@version can serve a stale (or upstream registry)
# tarball instead of the local file:/thelounge.tgz we just built, silently shipping
# old code. `yarn cache clean` is a second guard against the same issue.
RUN --mount=type=cache,target=/var/cache/apk \
	--mount=type=bind,from=builder,source=/thelounge.tgz,target=/thelounge.tgz \
	apk add -uU --virtual .build-deps git && \
	yarn --non-interactive --frozen-lockfile global add file:/thelounge.tgz && \
	yarn --non-interactive cache clean && \
	apk del .build-deps && \
	rm -rf /tmp/* && \
	install -d -o node -g node "${THELOUNGE_HOME}"

USER node:node

ENTRYPOINT ["thelounge"]
CMD ["start"]

EXPOSE 9000
