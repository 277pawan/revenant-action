# Revenant GitHub Action

[![GitHub release](https://img.shields.io/github/v/release/277pawan/revenant-action)](https://github.com/277pawan/revenant-action/releases)
[![Marketplace](https://img.shields.io/badge/Marketplace-Revenant-blue?logo=github)](https://github.com/marketplace?type=actions&query=revenant)

Run Revenant in any repository. Without a token, the action downloads only the public **[Revenant Free CLI](https://github.com/277pawan/freerev-cli)**. It never requests the private CLI in this mode.

The free CLI checks a directly reachable PostgreSQL database. The optional authenticated mode is for Revenant-owned workflows that need the private CLI; ordinary users do not need access to that repository.

## Install

Add to `.github/workflows/revenant.yml`:

```yaml
- uses: 277pawan/revenant-action@v1.0.4
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

The default command is `verify`, and the default CLI version is `latest`. `DATABASE_URL` is still required by the CLI and should be stored as a GitHub Actions secret.

**List on GitHub Marketplace:** open your repo → blue banner **Draft a release** → check **Publish this Action to the GitHub Marketplace**. See [MARKETPLACE.md](MARKETPLACE.md) (the old `/marketplace/actions/new` URL no longer works).

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `latest` | CLI release version, resolved independently for the selected distribution |
| `github-token` | empty | Optional token; when supplied, selects the private CLI. Never hardcode a token. |
| `config` | `revenant.yaml` | Config path (for `verify` and `doctor`) |
| `command` | `verify` | Free: `verify`, `doctor`, `init`, `contract`. Private: also `snapshot`, `reap`, `migrate`. |
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
      - uses: 277pawan/revenant-action@v1.0.4
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Internal Revenant workflows

Revenant-owned repositories can explicitly select the private CLI by passing a dedicated secret. Create a fine-grained token restricted to `277pawan/revenant-cli`, with **Contents: Read-only**, then save it as the `REVENANT_CLI_TOKEN` GitHub Actions secret in the consuming private repository.

```yaml
permissions:
  contents: read

steps:
  - uses: actions/checkout@v4
  - uses: 277pawan/revenant-action@v1.0.4
    with:
      version: latest
      github-token: ${{ secrets.REVENANT_CLI_TOKEN }}
      command: init
      args: --plan action-smoke --force -o revenant-action-smoke.yaml
    env:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

The token is only read by the installer, is not passed to the CLI process, and is never printed. A failed private download stops the action; it does not fall back to the free CLI. Do not store this token in the public action repository or commit it to source. Do not rely on the automatically created `GITHUB_TOKEN` for cross-repository access.

Normal users do not need this token or private-repository access. Without `github-token`, only the public free CLI is used.

### Private CLI AWS RDS workflow

```yaml
steps:
  - uses: 277pawan/revenant-action@v1.0.4
    with:
      version: latest
      github-token: ${{ secrets.REVENANT_CLI_TOKEN }}
      config: revenant-aws.yaml
      command: verify
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: us-east-1
      SANDBOX_USER: ${{ secrets.SANDBOX_USER }}
      SANDBOX_PASSWORD: ${{ secrets.SANDBOX_PASSWORD }}
      SANDBOX_DBNAME: postgres

  - uses: 277pawan/revenant-action@v1.0.4
    if: always()
    with:
      version: latest
      github-token: ${{ secrets.REVENANT_CLI_TOKEN }}
      command: reap
      args: --max-age 4h --region us-east-1
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: us-east-1
```

### Scaffold config from a live database

```yaml
- uses: 277pawan/revenant-action@v1.0.4
  with:
    command: init
    args: --plan my-app --force -o revenant.yaml
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

## How it works

1. Without a token, `install.sh` downloads a public free CLI release. With a token, it downloads from the private CLI repository.
2. The action runs `revenant <command>`.
3. CI fails if validation fails.

No Go or Node required on the runner. The free CLI does not create or restore AWS resources; AWS commands require the authenticated private CLI.

## CLI documentation

Free CLI command reference: **[freerev-cli README](https://github.com/277pawan/freerev-cli)**. Private CLI access is for Revenant-owned workflows only.

## License

Apache-2.0 — same as [freerev-cli](https://github.com/277pawan/freerev-cli/blob/main/LICENSE).
