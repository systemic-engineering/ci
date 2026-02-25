# Nix-Based Workflows

Use Nix-based CI workflows to match your local development environment exactly.

## Philosophy: CI Should Match Local

**Problem**: Traditional CI uses `erlef/setup-beam` while local development uses `nix develop`.
**Result**: Environment drift, "works on my machine" issues.

**Solution**: Run CI in the same Nix environment as local development.

## Benefits

1. **Perfect parity** - CI runs exactly what you run locally
2. **Reproducible** - Same Elixir/OTP/dependency versions
3. **Fast** - Nix caching + Magic Nix Cache or Cachix
4. **Simple** - No version management, Nix handles it

## Quick Start

### Prerequisites

Your project has a `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          elixir_1_18
          erlang_27
        ];
      };
    };
}
```

### Basic Nix CI

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/nix-setup@main
      - uses: reed/ci/actions/nix-elixir-test@main
      - uses: reed/ci/actions/nix-elixir-quality@main
```

This runs the same commands as local: `nix develop -c mix test`

## Nix Installers

### Determinate Nix (Recommended)

```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    nix-installer: determinate
```

**Pros:**
- Magic Nix Cache (free binary cache)
- Faster installation
- Better error messages
- Commercial support

**Cons:**
- Requires trust in Determinate Systems

### Official Nix

```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    nix-installer: official
```

**Pros:**
- Official NixOS installer
- No third-party dependencies

**Cons:**
- Slower
- Less caching by default

## Caching Strategies

### Magic Nix Cache (Determinate)

Free, automatic caching from Determinate Systems:

```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    nix-installer: determinate  # Magic cache enabled automatically
```

### Cachix

Public or private binary cache:

```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    enable-cachix: true
    cachix-name: your-project
    cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

Setup:
1. Create account at https://cachix.org
2. Create cache: `cachix create your-project`
3. Add auth token to GitHub secrets
4. Push from CI: happens automatically

## Actions Reference

### nix-setup

Set up Nix with caching.

```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    install-nix: true                    # Install Nix (default: true)
    nix-installer: determinate           # or 'official' (default: determinate)
    enable-cachix: false                 # Enable Cachix (default: false)
    cachix-name: ''                      # Cachix cache name
    cachix-auth-token: ''                # From secrets.CACHIX_AUTH_TOKEN
    extra-nix-config: ''                 # Extra nix.conf options
```

### nix-elixir-test

Run tests using Nix dev shell.

```yaml
- uses: reed/ci/actions/nix-elixir-test@main
  with:
    coverage: false                      # Collect coverage (default: false)
    coverage-tool: coveralls.github      # Coverage tool (default: coveralls.github)
    warnings-as-errors: true             # Fail on warnings (default: true)
    nix-command: 'nix develop -c'        # Nix command prefix (default: 'nix develop -c')
    additional-test-args: ''             # Extra test args
```

### nix-elixir-quality

Run quality checks using Nix dev shell.

```yaml
- uses: reed/ci/actions/nix-elixir-quality@main
  with:
    format: true                         # Check formatting (default: true)
    credo: true                          # Run Credo (default: true)
    credo-strict: true                   # Strict mode (default: true)
    dialyzer: false                      # Run Dialyzer (default: false)
    warnings-as-errors: true             # Fail on warnings (default: true)
    nix-command: 'nix develop -c'        # Nix command prefix
```

## Workflow Patterns

### Pattern 1: Pure Nix

Best for: Projects where all developers use Nix.

```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/nix-setup@main
      - uses: reed/ci/actions/nix-elixir-test@main
        with:
          coverage: true
      - uses: reed/ci/actions/nix-elixir-quality@main
```

**Pros:**
- Perfect local/CI parity
- Simple workflow
- Fast with caching

**Cons:**
- Only tests one Elixir/OTP combination
- Requires Nix knowledge

### Pattern 2: Hybrid (Recommended)

Best for: Most projects.

```yaml
jobs:
  # Primary: Nix (matches local)
  test-nix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/nix-setup@main
      - uses: reed/ci/actions/nix-elixir-test@main
        with:
          coverage: true
      - uses: reed/ci/actions/nix-elixir-quality@main

  # Secondary: Matrix (version coverage)
  test-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        elixir: ["1.17", "1.18"]
        otp: ["26.2", "27.0"]
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/elixir-setup@main
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
      - uses: reed/ci/actions/elixir-test@main
```

**Pros:**
- Local parity (Nix)
- Version coverage (matrix)
- Best of both worlds

**Cons:**
- Longer CI time
- More complex

### Pattern 3: Nix + Dialyzer Caching

Best for: Projects using Dialyzer (slow type checking).

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/nix-setup@main
      - uses: reed/ci/actions/nix-elixir-test@main
      - uses: reed/ci/actions/nix-elixir-quality@main

  dialyzer:
    runs-on: ubuntu-latest
    # Only on main or with 'dialyzer' label
    if: github.ref == 'refs/heads/main' || contains(github.event.pull_request.labels.*.name, 'dialyzer')
    steps:
      - uses: actions/checkout@v4
      - uses: reed/ci/actions/nix-setup@main
        with:
          enable-cachix: true
          cachix-name: your-project
          cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
      - uses: reed/ci/actions/nix-elixir-quality@main
        with:
          format: false
          credo: false
          dialyzer: true
```

**Pros:**
- Fast Dialyzer (cached PLTs)
- Runs only when needed
- Nix handles caching

## Local Development Workflow

### With Nix

```bash
# Enter dev shell
nix develop

# Run tests (same as CI)
mix test

# Run quality checks (same as CI)
mix format --check-formatted
mix credo --strict

# Run coverage (same as CI)
mix coveralls
```

### With direnv

Add `.envrc`:
```bash
use flake
```

Then:
```bash
direnv allow
# Shell automatically loads Nix environment
mix test
```

## Comparison: Nix vs Traditional

| Aspect | Nix CI | Traditional CI |
|--------|--------|----------------|
| **Local parity** | ✅ Exact match | ❌ Different setup |
| **Reproducible** | ✅ Guaranteed | ⚠️ Best effort |
| **Version management** | ✅ In flake.nix | ❌ Manual updates |
| **Caching** | ✅ Binary cache | ⚠️ Source cache |
| **Setup time** | ⚠️ Slower first run | ✅ Fast |
| **Flexibility** | ⚠️ Nix knowledge needed | ✅ Well-known |

## Migration Guide

### From Traditional to Nix

1. **Add flake.nix** to your project:
   ```nix
   # See template: ~/dev/projects/_templates/elixir/flake.nix
   ```

2. **Test locally**:
   ```bash
   nix develop -c mix test
   nix develop -c mix credo
   ```

3. **Update CI**:
   ```diff
   - - uses: erlef/setup-beam@v1
   + - uses: reed/ci/actions/nix-setup@main

   - - run: mix test
   + - uses: reed/ci/actions/nix-elixir-test@main
   ```

4. **Verify** CI matches local

### From Nix to Hybrid

Keep Nix for primary testing, add matrix for coverage:

```yaml
jobs:
  test-nix:
    # Your existing Nix job

  test-matrix:
    # Add matrix testing
    strategy:
      matrix:
        elixir: ["1.17", "1.18"]
```

## Troubleshooting

### "Nix command not found"

Ensure `nix-setup` action runs first:
```yaml
- uses: reed/ci/actions/nix-setup@main
- uses: reed/ci/actions/nix-elixir-test@main  # Will fail without setup
```

### Slow builds

Enable caching:
```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    nix-installer: determinate  # Enables Magic Nix Cache
```

Or use Cachix:
```yaml
- uses: reed/ci/actions/nix-setup@main
  with:
    enable-cachix: true
    cachix-name: your-cache
```

### Different results locally vs CI

Check:
1. Same `flake.lock` committed
2. CI uses `nix develop -c` (not different shell)
3. No extra dependencies in local shell

Run this to debug:
```bash
nix develop -c env | sort > local-env.txt
# Compare with CI environment
```

## Best Practices

1. **Commit flake.lock** - Ensures exact versions
2. **Use Cachix** - Especially for Dialyzer
3. **Hybrid approach** - Nix primary + matrix secondary
4. **direnv locally** - Automatic environment loading
5. **Document flake.nix** - Help non-Nix users

## Examples

See `examples/` directory:
- `nix-ci.yml` - Pure Nix workflow
- `hybrid-ci.yml` - Nix + matrix testing
