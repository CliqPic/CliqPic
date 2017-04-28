FROM ruby:2.4.1-alpine

EXPOSE 3000

WORKDIR /data/amdirent/cliq-pic

COPY Gemfile* ./

ENV PHANTOMJS_VERSION 1.9.8

RUN apk add --no-cache openssl \
    && wget -O /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 https://github.com/Medium/phantomjs/releases/download/v2.1.1/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
    && md5sum /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
        | grep -q "1c947d57fce2f21ce0b43fe2ed7cd361" \
    && tar -xjf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /tmp \
    && rm -rf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
    && mv /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs \
    && rm -rf /tmp/phantomjs-2.1.1-linux-x86_64
    && ln -s /usr/local/bin/phantomjs /root/.phantomjs/2.1.1/x86_64-linux/bin/phantomjs

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
