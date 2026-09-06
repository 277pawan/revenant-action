# Publish Revenant Action to GitHub Marketplace

GitHub **removed** the old URL `github.com/marketplace/actions/new` (404).  
Publishing now happens **from your action repo** when you draft a release.

## You are in the right place

On https://github.com/277pawan/revenant-action you should see a blue banner:

> **You can publish this Action to the GitHub Marketplace** → **Draft a release**

Click that button. (Same as: **Releases** → **Draft a new release**.)

## Prerequisites (done)

- [x] Public repo
- [x] `action.yml` at repo root (must be `.yml`, not `.yaml`)
- [x] `name`, `description`, `branding` in `action.yml`
- [x] README with usage examples
- [x] Tags: `v1.0.0`, `v1.0.1`, `v1.0.2`, `v1.0.3`
- [x] CLI binaries: https://github.com/277pawan/revenant-cli/releases

## Publish steps (follow in order)

### 1. Open draft release

From the repo home page, click **Draft a release** in the blue banner.

Or: **Releases** (right sidebar) → **Draft a new release**

### 2. Choose a tag

- **Option A:** Pick existing tag `v1.0.3` (already on GitHub)
- **Option B:** Create a new tag (e.g. `v1.0.4`) for the next marketplace release

Release title example: `Revenant Action v1.0.3`

### 3. Enable Marketplace

On the release page, find **Release action** and check:

☑ **Publish this Action to the GitHub Marketplace**

If the checkbox is **greyed out**:
1. Click the link to **accept the GitHub Marketplace Developer Agreement**
2. Ensure **2FA** is enabled on your GitHub account
3. Refresh the page

GitHub should show: **Everything looks good!**

### 4. Fill Marketplace fields

| Field | Suggested value |
|-------|-----------------|
| **Primary category** | Continuous integration |
| **Another category** (optional) | Testing |
| **Name** | Revenant Restore Validation |
| **Description** | Prove Postgres backups restore — local checks or AWS RDS snapshot restore in CI. No Go/Node required. |

Icon/color come from `action.yml` (`database` / `blue`).

### 5. Publish

- Add release notes (or **Generate release notes**)
- Click **Publish release**
- Confirm 2FA if prompted

### 6. Verify

After publish, the repo banner changes to **View on Marketplace**.

Your listing will be at a URL like:

**https://github.com/marketplace/actions/revenant-restore-validation**

(Exact slug is assigned by GitHub.)

## After publish — how users install it

```yaml
- uses: 277pawan/revenant-action@v1.0.3
  with:
    version: v0.1.1
    config: revenant.yaml
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

## Updating later

1. Push changes to `main`
2. **Draft a new release** with a new tag (e.g. `v1.0.4`)
3. Check **Publish this Action to the GitHub Marketplace** again
4. **Publish release**

## Official docs

https://docs.github.com/en/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace

## CLI vs Action versions

| What | Version | Repo |
|------|---------|------|
| CLI binary | `v0.1.1`, `v0.2.0`, … | revenant-cli |
| Action wrapper | `v1.0.3`, `v1.1.0`, … | revenant-action |

Users pin the **action** tag; the action downloads the **CLI** via `with: version: v0.1.1`.
