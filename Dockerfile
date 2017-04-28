FROM ruby:2.4.1-alpine

EXPOSE 3000

WORKDIR /data/amdirent/cliq-pic

COPY Gemfile* ./

ENV PHANTOMJS_VERSION 1.9.8

RUN apk update && apk add ca-certificates && update-ca-certificates && apk add openssl && mkdir -p /srv/var && \
  wget -q -O /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  tar -xjf /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 -C /tmp && \
  rm -f /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  mv /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/ /srv/var/phantomjs && \
  ln -s /srv/var/phantomjs/bin/phantomjs /usr/bin/phantomjs

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        libxslt-dev \
        postgresql-dev \
    && bundle install \
    && apk del .build-deps \
    && apk add --no-cache curl imagemagick libpq libxslt nodejs postfix zip


COPY config.ru start.sh Rakefile ./
COPY bin/ bin/
COPY public/ public/
COPY db/ db/
COPY config/ config/
COPY app/ app/

CMD ["sh", "start.sh"]
