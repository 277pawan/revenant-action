# Revenant GitHub Action

Run [Revenant](https://github.com/277pawan/revenant-cli) restore validation in **any** repository — Node, Python, Go, Rails, etc. Revenant only talks to Postgres / AWS RDS; it does not read your application code.

## Quick start

1. Add `revenant.yaml` to your repo root (or run `revenant init` locally once).
2. Add a workflow:

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

      - uses: 277pawan/revenant-action@v1
        with:
          version: v0.1.0
          config: revenant.yaml
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

3. Add `DATABASE_URL` (or AWS secrets) in **Settings → Secrets**.

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `v0.1.0` | Release tag from [revenant-cli releases](https://github.com/277pawan/revenant-cli/releases) |
| `repo` | `277pawan/revenant-cli` | Where binaries are published |
| `config` | `revenant.yaml` | Config path for `verify` |
| `command` | `verify` | `verify`, `init`, `reap`, `snapshot` |
| `args` | | Extra flags, e.g. `--max-age 4h --region us-east-1` for `reap` |

## AWS restore example

```yaml
- uses: 277pawan/revenant-action@v1
  with:
    version: v0.1.0
    config: revenant-aws.yaml
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    SANDBOX_USER: ${{ secrets.SANDBOX_USER }}
    SANDBOX_PASSWORD: ${{ secrets.SANDBOX_PASSWORD }}
    SANDBOX_DBNAME: postgres
```

## How it works

1. `install.sh` downloads the correct OS/arch binary from GitHub Releases.
2. The action runs `revenant <command>` with your env vars.
3. CI fails if validation fails.

No Go or Node required in your project.

## Publishing this action

Tag this repo for users to pin:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Users reference `277pawan/revenant-action@v1` (major) or `@v1.0.0` (exact).
