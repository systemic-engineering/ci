# Workflow Constraints

Operating principles for Reed's CI actions development and usage.

## Core Constraint: Local/CI Parity

**CI must reflect local development as closely as possible.**

### Rationale

Environment drift between local and CI causes:
- "Works on my machine" failures
- Wasted debugging time
- False confidence in passing tests
- Different behavior in production

### Implementation

1. **Use the same tools locally and in CI**
   - Local: `nix develop -c mix test`
   - CI: `nix develop -c mix test`
   - NOT Local: `nix develop` → CI: `erlef/setup-beam`

2. **Same dependency versions**
   - Commit `flake.lock` and `mix.lock`
   - CI uses exact same locked versions
   - No "latest" or floating versions

3. **Same environment**
   - Nix flake defines environment once
   - Both local and CI source from same flake
   - No CI-specific setup that can't run locally

4. **Verifiable parity**
   - Can run CI commands locally: `nix develop -c mix test`
   - Can replicate CI environment: `nix develop`
   - No hidden CI configuration

### Workflow Actions

#### Nix-Based (Preferred)
Use when local development uses Nix:
- `nix-setup` + `nix-elixir-test` + `nix-elixir-quality`
- Runs `nix develop -c mix <command>`
- Perfect local/CI match

#### Traditional (Compatibility)
Use when local development doesn't use Nix:
- `elixir-setup` + `elixir-test` + `elixir-quality`
- Uses `erlef/setup-beam`
- Document exact versions in README

#### Hybrid (Pragmatic)
Use for transition or broad compatibility:
- Primary job: Nix (matches local)
- Secondary jobs: Matrix (version coverage)
- Best of both worlds

### Acceptable Deviations

Only deviate when absolutely necessary:

1. **OS differences** (local: macOS, CI: Linux)
   - Document in README
   - Test both if critical

2. **Performance optimizations** (CI caching)
   - Must not change behavior
   - Must be reproducible locally

3. **Security constraints** (CI secrets)
   - Use same secret mechanism locally (sops, 1Password)
   - Document access method

### Anti-Patterns

❌ **Don't:**
- Use different Elixir/OTP versions in CI vs local
- Add CI-only dependencies
- Skip tests locally that run in CI
- Use `latest` tags in CI
- Configure CI-specific behavior

✅ **Do:**
- Run exact same commands locally and in CI
- Use Nix flakes for environment definition
- Commit lock files
- Test CI workflow locally before pushing
- Document environment setup

### Verification

Before pushing CI changes, verify locally:

```bash
# Clone the repo fresh
cd /tmp
git clone <repo>
cd <repo>

# Run CI commands exactly
nix develop -c mix deps.get
nix develop -c mix test
nix develop -c mix format --check-formatted
nix develop -c mix credo --strict

# Should match CI results exactly
```

### Template Integration

Templates generated from this repo must:
1. Include `flake.nix` for reproducible environments
2. Provide Nix-based CI workflow by default
3. Document how to run CI commands locally
4. Commit both `flake.lock` and `mix.lock`

### Enforcement

- All new workflows must follow local/CI parity
- Pull requests should include "tested locally" confirmation
- Document any necessary deviations
- Prefer rejecting features that break parity

### Examples

#### ✅ Good: Nix Workflow
```yaml
steps:
  - uses: actions/checkout@v4
  - uses: reed/ci/actions/nix-setup@main
  - uses: reed/ci/actions/nix-elixir-test@main
```

Local: `nix develop -c mix test` ← Same command CI runs

#### ⚠️ Acceptable: Hybrid
```yaml
jobs:
  test-nix:  # Primary: matches local
    steps:
      - uses: reed/ci/actions/nix-setup@main
      - uses: reed/ci/actions/nix-elixir-test@main

  test-matrix:  # Secondary: version coverage
    strategy:
      matrix:
        elixir: ["1.17", "1.18"]
    steps:
      - uses: reed/ci/actions/elixir-setup@main
      - uses: reed/ci/actions/elixir-test@main
```

Nix job matches local, matrix provides extra coverage.

#### ❌ Bad: Different Environments
```yaml
# CI
- uses: erlef/setup-beam@v1
  with:
    elixir-version: "1.18"

# Local: nix develop (Elixir 1.17)
```

Version mismatch breaks parity.

## Secondary Constraints

### Composability
Actions should be small, focused, and composable.

### Documentation
Every action needs:
- Clear description
- Input/output documentation
- Usage example
- Branding (icon, color)

### Maintainability
- Keep actions simple
- Prefer composite over JavaScript
- Use official actions when possible

### Performance
- Enable caching by default
- Use parallel jobs
- Optimize for common case

## Constraint Hierarchy

1. **Local/CI parity** (must have)
2. **Composability** (should have)
3. **Performance** (nice to have)

When in conflict, prioritize parity over performance.

## Review Checklist

Before merging workflow changes:
- [ ] Can run CI commands locally
- [ ] Uses same environment locally and in CI
- [ ] Lock files committed
- [ ] Documentation updated
- [ ] Examples provided
- [ ] Deviations documented and justified
