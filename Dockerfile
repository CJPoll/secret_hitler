FROM elixir:alpine

RUN mix local.hex --force && mix local.rebar --force

RUN apk update
RUN apk add git nodejs npm inotify-tools bash curl tar xz

ARG MIX_ENV=prod

WORKDIR /app

COPY mix.exs mix.exs
COPY mix.lock mix.lock
COPY config config

RUN mix do deps.get, deps.compile

COPY . .

RUN mix compile
