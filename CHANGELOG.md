# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

#### Composite Actions
- **hex-publish** - Publish packages to Hex.pm
  - `HEX_API_KEY` passed securely via action input
  - Optional `hex-organization` for scoped/private packages
  - Configurable `mix-env` (defaults to `dev` for `ex_doc` compatibility)

#### Reusable Workflows
- **hex-publish.yml** - Full release workflow (setup → publish)
  - Chains `elixir-setup` + `hex-publish` actions
  - `hex-api-key` secret forwarding via `workflow_call`
  - Optional `write-version-file` for projects that read version from a file
  - Optional organization support

#### Examples
- **release.yml** - Publish to Hex.pm on GitHub release published event

#### Dev Tooling
- **flake.nix** - Nix dev shell with `actionlint` and `shellcheck`
- **Justfile** - `check` recipe runs actionlint; `pre-push` aliases it

### Fixed
- Reusable workflows referenced `./.github/actions/xxx` (non-existent path);
  corrected to `./actions/xxx` to match actual action locations

---

## [0.1.0] - 2026-02-13

### Added

#### Composite Actions
- **elixir-setup** - Set up Elixir/OTP with intelligent caching
  - Supports deps/, _build/, and .dialyzer/ caching
  - Configurable cache prefixes for versioning
  - Automatic dependency installation
  - Cache hit outputs for downstream steps

- **elixir-test** - Run tests with optional coverage
  - Compilation with warnings-as-errors
  - ExCoveralls integration
  - Support for coveralls.github, coveralls.json, coveralls.html
  - Additional test arguments support

- **elixir-quality** - Quality checks
  - Format checking
  - Credo linting (normal and strict modes)
  - Dialyzer type checking
  - Configurable warnings-as-errors

#### Reusable Workflows
- **elixir-ci.yml** - Single-version CI pipeline
  - Configurable Elixir/OTP/Alpine versions
  - Optional test, coverage, quality, and Dialyzer jobs
  - Flexible caching configuration

- **elixir-matrix.yml** - Multi-version matrix testing
  - JSON-based matrix configuration
  - Fail-fast control
  - Parallel testing across versions

#### Examples
- **basic-ci.yml** - Simple setup using composite actions
- **matrix-ci.yml** - Multi-version testing with separate quality and coverage jobs
- **knigge-style.yml** - Comprehensive container-based testing
  - Multiple Elixir/OTP/Alpine combinations
  - Separate coverage, quality, and Dialyzer jobs
  - Direct container usage with hexpm/elixir images

### Features
- **Intelligent caching** - Separate caches for deps, _build, Dialyzer PLTs
- **Container support** - Works with hexpm/elixir Docker images
- **Flexible configuration** - All major options exposed as inputs
- **Coverage integration** - ExCoveralls with GitHub integration
- **Production patterns** - Extracted from knigge's battle-tested CI

### Documentation
- Comprehensive README with usage examples
- Detailed action descriptions
- Multiple example workflows for different use cases
- MIT license

## Patterns Extracted

### From knigge
- Multi-version matrix testing across Elixir 1.7-1.12, OTP 20-24
- Container-based testing with hexpm/elixir images
- Separate jobs for tests, coverage, style, and type checking
- Smart cache invalidation based on mix.lock + versions
- Long-lived Dialyzer PLT caching (version-only keying)

### Improvements
- Updated to modern Elixir/OTP versions (1.16-1.18, OTP 26-27)
- Updated to actions/cache@v4 and actions/checkout@v4
- More flexible input configuration
- Composite actions for better reusability
- Alpine 3.18-3.20 support
