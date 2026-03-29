# We use the HexPM image to strictly pin Elixir + Erlang + Debian Bookworm
FROM hexpm/elixir:1.18.1-erlang-27.2-debian-bookworm-20251229-slim AS build

RUN apt-get update -y && \
    apt-get install -y build-essential git ca-certificates && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /app

COPY app/mix.exs app/mix.lock ./
RUN mix deps.get --only prod

COPY app/config config

COPY app/assets assets
COPY app/priv priv
COPY app/lib lib

RUN mix assets.deploy

RUN mix compile
RUN mix release

FROM debian:bookworm-slim AS app

WORKDIR /app

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV MIX_ENV=prod
ENV PHX_SERVER=true

COPY --from=build /app/_build/prod/rel/auth ./

EXPOSE 4000

CMD ["bin/auth", "start"]