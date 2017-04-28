FROM ruby:2.4.1-alpine

EXPOSE 3000

WORKDIR /data/amdirent/cliq-pic

COPY Gemfile* ./

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        libxslt-dev \
        postgresql-dev \
    && bundle install \
    && apk del .build-deps \
    && apk add --no-cache curl imagemagick libpq libxslt nodejs postfix zip

RUN apk update && apk add --no-cache fontconfig && \
  mkdir -p /usr/share && \
  cd /usr/share \
  && curl -L https://github.com/Overbryd/docker-phantomjs-alpine/releases/download/2.11/phantomjs-alpine-x86_64.tar.bz2 | tar xj \
  && ln -s /usr/share/phantomjs/phantomjs /usr/bin/phantomjs \
  && phantomjs --version

COPY config.ru start.sh Rakefile ./
COPY bin/ bin/
COPY public/ public/
COPY db/ db/
COPY config/ config/
COPY app/ app/

CMD ["sh", "start.sh"]
