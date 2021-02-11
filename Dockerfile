FROM library/elixir:alpine

COPY . .

RUN mix local.hex --force \
    && mix deps.get \
    && mix escript.build

FROM library/elixir:alpine

COPY --from=0 ci_automatic_test_timing_splitter /cats

ENTRYPOINT [ "/cats" ]
