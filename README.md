# DogExceptex

Elixir `Logger` backend for Datadog. Funnels exceptions and error-level logging into
datadog error events via the Datadog statsd agent.

## Running tests
Clone the repository, then,

`mix deps.get`

`mix test`

## Installation

The package can be installed by adding `dog_exceptex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dog_exceptex, "~> 0.0.1"}
  ]
end
```

To add `DogExceptex` as a logger backend, in your `config/config.exs` add (or change):

```elixir
config :logger, :backends, [:console, DogExceptex.Logger]
```

And configure with

```elixir
config :logger, :dog_exceptex,
  statsd_host: "host",
  statsd_port: port,
  event_opts: [
    priority: "normal",
    tags: [ # Tags in this list should have a string value, and are arbitrary.
      environment: System.get_env("MIX_ENV"),
      app: "some-app",
    ]
  ]
```

If you wish to start a `Dogstatsd` process yourself, you may configure with `statsd_pid`.
`Logger.configure_backend/2` is supported.

## Docs

Documentation can be generated with `mix docs`
