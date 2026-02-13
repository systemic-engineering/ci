# Reed's CI Actions

Reusable GitHub Actions for Elixir projects, extracted from production patterns.

## Actions

### `elixir-setup`
Sets up Elixir/OTP environment with intelligent caching for deps, _build, and Dialyzer PLTs.

### `elixir-test`
Runs tests with optional coverage collection across multiple Elixir/OTP versions.

### `elixir-quality`
Runs formatting, Credo linting, and optional Dialyzer type checking.

## Usage

### Basic CI Pipeline

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    uses: reed/ci/.github/workflows/elixir-ci.yml@main
    with:
      elixir-version: "1.17"
      otp-version: "27.0"
```

### Multi-Version Testing

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    uses: reed/ci/.github/workflows/elixir-matrix.yml@main
    with:
      matrix: |
        - elixir: "1.17"
          otp: "27.0"
        - elixir: "1.18"
          otp: "27.0"
```

### Custom Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: reed/ci/actions/elixir-setup@main
        with:
          elixir-version: "1.17"
          otp-version: "27.0"
          cache-prefix: "v1"

      - uses: reed/ci/actions/elixir-test@main
        with:
          coverage: true

      - uses: reed/ci/actions/elixir-quality@main
        with:
          format: true
          credo: true
          dialyzer: false
```

## Features

- **Multi-version matrix testing** - Test across Elixir/OTP/Alpine combinations
- **Intelligent caching** - Separate caches for deps, _build, and Dialyzer PLTs
- **Container-based testing** - Uses official hexpm/elixir images
- **Coverage support** - ExCoveralls with GitHub integration
- **Quality gates** - Format checking, Credo linting, Dialyzer type checking
- **Fast by default** - Parallel execution and smart cache invalidation

## Patterns

### Cache Strategy
- **deps/** - Keyed by mix.lock hash + Elixir/OTP versions
- **_build/** - Keyed by mix.lock hash + Elixir/OTP versions + MIX_ENV
- **.dialyzer/** - Keyed by Elixir/OTP versions only (long-lived)

### Container Images
Uses `hexpm/elixir:${ELIXIR}-erlang-${OTP}-alpine-${ALPINE}` for reproducible builds.

## License

MIT
