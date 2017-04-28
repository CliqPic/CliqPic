FROM ruby:2.4.1-alpine

EXPOSE 3000

WORKDIR /data/amdirent/cliq-pic

COPY Gemfile* ./

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        libxslt-dev \
        postgresql-dev \
        phantomjs \
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
