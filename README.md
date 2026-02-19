# systemic-engineer/ci

Reusable GitHub Actions workflows for repos maintained by Reed (systemic.engineering).

## OBC Mapping

These workflows are the GitHub Actions expression of OBC pipeline logic:

| OBC concept | GitHub Actions equivalent |
|---|---|
| Observable | Push / pull_request trigger |
| Budget | Quality gate exit code (`mix check`, `just check`) |
| on_pass | Status check green → PR merges |
| on_fail | Status check red → PR blocked + Ntfy alert to Reed |

The judgment encoded in OBC pipelines becomes the gate on every PR.

## Workflows

### `check.yml` — Generic quality gate

Calls any `check_command` (default: `just check`). Use for any stack.

```yaml
jobs:
  call-check:
    uses: systemic-engineer/ci/.github/workflows/check.yml@main
    with:
      check_command: 'just check'
```

### `elixir-check.yml` — Elixir quality gate

Sets up Elixir + OTP, caches deps and _build, runs `mix check`.
Job name is `check` — matches the branch protection context.

```yaml
jobs:
  call-check:
    uses: systemic-engineer/ci/.github/workflows/elixir-check.yml@main
    with:
      elixir_version: '1.17'
      otp_version: '27'
```

### `notify-ntfy.yml` — OBC on_fail cascade

Fires when a check fails. Sends to Reed via Ntfy `se-ci` topic for triage.

```yaml
jobs:
  notify:
    if: failure()
    needs: [call-check]
    uses: systemic-engineer/ci/.github/workflows/notify-ntfy.yml@main
    with:
      repo: ${{ github.repository }}
      workflow: ${{ github.workflow }}
      run_url: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    secrets:
      NTFY_TOKEN: ${{ secrets.NTFY_TOKEN }}
```

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
    uses: systemic-engineer/ci/.github/workflows/elixir-check.yml@main
    with:
      elixir_version: '1.17'
      otp_version: '27'

  notify-on-failure:
    if: failure()
    needs: [call-check]
    uses: systemic-engineer/ci/.github/workflows/notify-ntfy.yml@main
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

Systemic Engineering License v1.0 — see LICENSE.
