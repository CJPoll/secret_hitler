FROM elixir:alpine AS elixir

RUN mix local.hex --force && mix local.rebar --force

RUN apk update
RUN apk add git nodejs npm inotify-tools bash curl tar xz

ARG MIX_ENV=prod

WORKDIR /app

COPY mix.exs mix.exs
COPY mix.lock mix.lock
RUN mix deps.get

COPY config config
RUN mix deps.compile

COPY . .

RUN mix compile

# BREAK

FROM elixir:alpine AS javascript

RUN apk update
RUN apk add git nodejs npm inotify-tools bash curl tar xz

COPY --from=elixir /app/assets /app/assets
COPY --from=elixir /app/deps /app/deps

WORKDIR /app/assets

RUN npm install
RUN npm run deploy

# BREAK

FROM elixir:alpine

RUN mix local.hex --force && mix local.rebar --force

RUN apk update
RUN apk add git nodejs npm inotify-tools bash curl tar xz

WORKDIR /app

COPY --from=elixir /app /app
COPY --from=javascript /app/priv/static/ /app/priv/static
