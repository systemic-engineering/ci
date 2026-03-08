# systemic-engineering/ci

Reusable GitHub Actions workflows for repos maintained by Reed (systemic.engineering).

## OBC Mapping

These workflows are the GitHub Actions expression of OBC pipeline logic:

| OBC concept | GitHub Actions equivalent |
|---|---|
| Observable | Push / pull_request trigger |
| Budget | Quality gate exit code (`mix check`, `just check`, `mix docs`) |
| on_pass | Status check green → PR merges / docs deployed |
| on_fail | Status check red → PR blocked + Ntfy alert to Reed |

The judgment encoded in OBC pipelines becomes the gate on every PR.

## Workflows

### `check.yml` — Generic quality gate

Calls any `check_command` (default: `just check`). Use for any stack.

```yaml
jobs:
  call-check:
    uses: systemic-engineering/ci/.github/workflows/check.yml@main
    with:
      check_command: 'just check'
```

### `elixir-check.yml` — Elixir quality gate

Sets up Elixir + OTP, caches deps and _build, runs `mix check`.
Job name is `check` — matches the branch protection context.

```yaml
jobs:
  call-check:
    uses: systemic-engineering/ci/.github/workflows/elixir-check.yml@main
    with:
      elixir_version: '1.17'
      otp_version: '27'
```

### `docs-check.yml` — Documentation quality gate

Verifies `mix docs` builds cleanly. Use on pull requests to catch doc errors
before merge. Nix-based (local/CI parity).

```yaml
jobs:
  docs:
    uses: systemic-engineering/ci/.github/workflows/docs-check.yml@main
```

### `docs-ghpages.yml` — Deploy docs to GitHub Pages

Builds ex_doc output and deploys to GitHub Pages. For projects not published
on hex.pm where HexDocs is unavailable.

Requires: Repository Settings > Pages > Source set to "GitHub Actions".

```yaml
jobs:
  docs:
    uses: systemic-engineering/ci/.github/workflows/docs-ghpages.yml@main
```

### `notify-ntfy.yml` — OBC on_fail cascade

Fires when a check fails. Sends to Reed via Ntfy `se-ci` topic for triage.

```yaml
jobs:
  notify:
    if: failure()
    needs: [call-check]
    uses: systemic-engineering/ci/.github/workflows/notify-ntfy.yml@main
    with:
      repo: ${{ github.repository }}
      workflow: ${{ github.workflow }}
      run_url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    secrets:
      NTFY_TOKEN: ${{ secrets.NTFY_TOKEN }}
```

## Composite Actions

### Nix-based (preferred — local/CI parity)

| Action | Purpose |
|---|---|
| `nix-setup` | Install Nix with flakes and optional Cachix |
| `nix-elixir-test` | Run tests via `nix develop -c mix test` |
| `nix-elixir-quality` | Format, Credo, Dialyzer via `nix develop -c` |
| `nix-elixir-docs` | Build docs via `nix develop -c mix docs` |

### Traditional (non-Nix)

| Action | Purpose |
|---|---|
| `elixir-setup` | Setup Elixir/OTP with caching |
| `elixir-test` | Run tests with optional coverage |
| `elixir-quality` | Format, Credo, Dialyzer checks |
| `elixir-docs` | Build docs via `mix docs` |
| `hex-publish` | Publish package to hex.pm |

## Documentation Strategy

For projects not published on hex.pm, HexDocs (`mix hex.publish docs`) is not
available. These workflows use **GitHub Pages** with ex_doc output instead.

### Setup in downstream repos

1. Enable GitHub Pages: Repository Settings > Pages > Source: "GitHub Actions"
2. Add workflow (`.github/workflows/docs.yml`):

```yaml
name: Docs

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  check-docs:
    if: github.event_name == 'pull_request'
    uses: systemic-engineering/ci/.github/workflows/docs-check.yml@main

  deploy-docs:
    if: github.ref == 'refs/heads/main'
    uses: systemic-engineering/ci/.github/workflows/docs-ghpages.yml@main
```

3. Docs will be available at `https://systemic-engineering.github.io/<repo>/`

### Which projects can use this

| Project | ex_doc | Standalone | Docs CI |
|---|---|---|---|
| witness | yes | yes | ready |
| tracer | yes | yes | ready |
| glue | yes | no (path deps) | needs multi-repo checkout |
| obc-beam | no | no (path deps) | add ex_doc first |
| obc-github | no | no | add ex_doc first |

## Full Example

`.github/workflows/ci.yml` in a maintained Elixir repo:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  call-check:
    uses: systemic-engineering/ci/.github/workflows/elixir-check.yml@main
    with:
      elixir_version: '1.17'
      otp_version: '27'

  notify-on-failure:
    if: failure()
    needs: [call-check]
    uses: systemic-engineering/ci/.github/workflows/notify-ntfy.yml@main
    with:
      repo: ${{ github.repository }}
      workflow: ${{ github.workflow }}
      run_url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    secrets:
      NTFY_TOKEN: ${{ secrets.NTFY_TOKEN }}
```

## Branch Protection

The `just setup` recipe in each maintained repo configures branch protection to
require the `check` job to pass before merging. Job names in these workflows
match that expectation exactly.

## License

systemic.engineering License v1.0 — see LICENSE.
