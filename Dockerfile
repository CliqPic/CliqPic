FROM ruby:2.4.1-alpine

WORKDIR /data/amdirent/cliq-pic

COPY Gemfile* ./

RUN apk add --no-cache --virtual .build-deps build-base libxslt-dev postgresql-dev &&\
    bundle install &&\
    apk del .build-deps &&\
    apk add --no-cache libpq libxslt nodejs

COPY config.ru start.sh Rakefile ./
COPY bin/ bin/
COPY public/ public/
COPY db/ db/
COPY config/ config/
COPY app/ app/

CMD ["sh", "start.sh"]
