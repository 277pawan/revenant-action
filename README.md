# Revenant GitHub Action

[![GitHub release](https://img.shields.io/github/v/release/277pawan/revenant-action)](https://github.com/277pawan/revenant-action/releases)
[![Marketplace](https://img.shields.io/badge/Marketplace-Revenant-blue?logo=github)](https://github.com/marketplace?type=actions&query=revenant)

Run **[Revenant](https://github.com/277pawan/revenant-cli)** restore validation in **any** repository.

Works with Node, Python, Go, Rails, Java, or anything else — Revenant only connects to PostgreSQL / AWS RDS. It never reads your application source code.

## Install

Add to `.github/workflows/revenant.yml`:

```yaml
- uses: 277pawan/revenant-action@v1.0.2
  with:
    version: v0.1.0
    config: revenant.yaml
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

**List on GitHub Marketplace:** [Publish steps](MARKETPLACE.md) · [Marketplace search](https://github.com/marketplace?type=actions&query=revenant)

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `v0.1.0` | CLI release from [revenant-cli releases](https://github.com/277pawan/revenant-cli/releases) |
| `repo` | `277pawan/revenant-cli` | Repo that publishes CLI binaries |
| `config` | `revenant.yaml` | Config path (for `verify`) |
| `command` | `verify` | `verify`, `init`, `reap`, or `snapshot` |
| `args` | | Extra CLI flags |

## Examples

### Local / CI Postgres

```yaml
name: Prove backup restores
on:
  schedule:
    - cron: '0 3 * * 0'
  workflow_dispatch:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: 277pawan/revenant-action@v1.0.2
        with:
          version: v0.1.0
          config: revenant.yaml
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### AWS RDS snapshot restore

```yaml
- uses: 277pawan/revenant-action@v1.0.2
  with:
    version: v0.1.0
    config: revenant-aws.yaml
    command: verify
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION: us-east-1
    SANDBOX_USER: ${{ secrets.SANDBOX_USER }}
    SANDBOX_PASSWORD: ${{ secrets.SANDBOX_PASSWORD }}
    SANDBOX_DBNAME: postgres

- uses: 277pawan/revenant-action@v1.0.2
  if: always()
  with:
    version: v0.1.0
    command: reap
    args: --max-age 4h --region us-east-1
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION: us-east-1
```

### Scaffold config from a live database

```yaml
- uses: 277pawan/revenant-action@v1.0.2
  with:
    version: v0.1.0
    command: init
    args: --plan my-app --force -o revenant.yaml
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

## How it works

1. `install.sh` downloads the correct OS/arch binary from GitHub Releases.
2. The action runs `revenant <command>`.
3. CI fails if validation fails.

No Go or Node required in your project.

## CLI documentation

Full command reference, check types, and AWS setup: **[revenant-cli README](https://github.com/277pawan/revenant-cli)**

## License

Apache-2.0 — same as [revenant-cli](https://github.com/277pawan/revenant-cli/blob/main/LICENSE).
