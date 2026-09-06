# Publish Revenant Action to GitHub Marketplace

The action is ready to list. Final publish steps require your GitHub account in the browser (Marketplace Developer Agreement).

## Prerequisites (done)

- [x] Public repo: https://github.com/277pawan/revenant-action
- [x] `action.yml` at repo root with `name`, `description`, `branding`, `inputs`
- [x] README with usage examples
- [x] Tagged releases: `v1.0.0`, `v1.0.1`
- [x] CLI binaries published: https://github.com/277pawan/revenant-cli/releases

## Publish (one-time, ~5 minutes)

1. Open **https://github.com/marketplace/actions/new**
2. Select repository: **277pawan/revenant-action**
3. Fill in the listing:

| Field | Suggested value |
|-------|-----------------|
| **Name** | Revenant Restore Validation |
| **Tagline** | Prove your Postgres backup actually restores |
| **Category** | Continuous integration |
| **Primary category** | Testing |
| **Description** | Run Revenant in any repo — validate Postgres or restore AWS RDS snapshots, no Go/Node required. |
| **Icon** | Upload a simple logo (optional) or use default |

4. Accept the **GitHub Marketplace Developer Agreement**
5. Click **Publish release** (publish the action listing)

## After publish

Users find it at:

**https://github.com/marketplace/actions/revenant-restore-validation**

(or similar slug GitHub assigns)

They add it with:

```yaml
- uses: 277pawan/revenant-action@v1.0.2
```

## Updating the listing

When you ship a new action version:

```bash
git tag v1.0.2
git push origin v1.0.2
```

Then in Marketplace → your action → **Draft a new release** (if GitHub prompts for listing updates).

## CLI vs Action versions

| What | Version | Repo |
|------|---------|------|
| CLI binary | `v0.1.0`, `v0.2.0`, … | revenant-cli |
| Action wrapper | `v1.0.1`, `v1.1.0`, … | revenant-action |

Users pin the **action** tag; the action downloads the **CLI** version via `with: version: v0.1.0`.
