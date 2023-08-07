FROM node:20.18.0-alpine

ENV NODE_ENV=production
ENV THELOUNGE_HOME="/config"
ENV PORT=9000

VOLUME /config

COPY . /thelounge-src

RUN apk add --update --no-cache --virtual .build-deps \
	python3 \
	make \
	g++ \
	git && \
	cd /thelounge-src && \
	yarn --non-interactive --production=false install && \
	yarn --non-interactive build && \
	npm pack && \
	find . -type f -name "thelounge-*.tgz" -exec mv "{}" "thelounge.tgz" \; -quit && \
	yarn --non-interactive --frozen-lockfile global add file:/thelounge-src/thelounge.tgz && \
	yarn --non-interactive cache clean && \
	cd / && \
	rm -rf /thelounge-src /root/.cache /tmp && \
	apk del .build-deps

CMD ["thelounge", "start"]
