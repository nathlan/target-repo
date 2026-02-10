---
name: Sync shared-standards Files
description: Sync Copilot files and GitHub Actions workflows from nathlan/shared-standards into this repository
on:
  schedule: daily
permissions: read-all
steps:
  - name: Generate a token
    id: generate-token
    uses: actions/create-github-app-token@v2
    with:
      app-id: ${{ vars.SOURCE_REPO_SYNC_APP_ID }}
      private-key: ${{ secrets.SOURCE_REPO_SYNC_APP_PRIVATE_KEY }}
      owner: nathlan
      repositories: shared-standards
  - name: Export GH_TOKEN
    env:
      GH_TOKEN: ${{ steps.generate-token.outputs.token }}
    run: echo "GH_TOKEN=$GH_TOKEN" >> $GITHUB_ENV
network:
  allowed:
    - "github.com"
safe-outputs:
  create-pull-request:
    title-prefix: "[shared-standards-sync] "
    labels: [standards, automation]
    draft: false
---

# Sync Shared Standards Files

Sync Copilot files and GitHub Actions workflows from nathlan/shared-standards@main into this repository.

This workflow automatically syncs:
- **Copilot Files**: Prompts, local agents, and instructions from `.github/copilot/`
- **GitHub Actions Workflows**: Terraform plan, deploy, and other workflows from `.github/workflows/`

Files are merged into the local repository (no deletions of local-only files) and a pull request is opened with the changes.

## What Gets Synced

### 1. Copilot Files (from `.github/copilot/` in shared-standards)
- `*.md` - Copilot prompts and instructions
- Agent definitions and configurations

### 2. GitHub Actions Workflows (from `.github/workflows/` in shared-standards)
- `terraform-plan.yml` - Terraform plan workflow
- `terraform-deploy.yml` - Terraform deploy workflow
- `terraform-validate.yml` - Terraform validate workflow
- Other standard workflows

These files are synced into corresponding directories in your repository.

## Sync Process

### Step 1: Clone shared-standards with Sparse Checkout

Use bash to clone nathlan/shared-standards@main with sparse-checkout for the `/` directory structure using the GH app token (in `GH_TOKEN`):

```bash
git clone --depth 1 --filter=blob:none --sparse "https://x-access-token:${GH_TOKEN}@github.com/nathlan/shared-standards.git" /tmp/shared-standards

cd /tmp/shared-standards
git sparse-checkout add .github/copilot .github/workflows
```

### Step 2: Sync Copilot Files

Merge the Copilot files from shared-standards into `.github/copilot/` (do not delete local-only files):

```bash
rsync -av --ignore-existing "/tmp/shared-standards/.github/copilot/" "$GITHUB_WORKSPACE/.github/copilot/"
```

Print what Copilot files were synced:
```bash
echo "📋 Synced Copilot files:"
find "$GITHUB_WORKSPACE/.github/copilot/" -type f -name "*.md" | head -10
```

### Step 3: Sync Workflows

Merge the GitHub Actions workflows from shared-standards into `.github/workflows/` (do not delete local-only files):

```bash
rsync -av --ignore-existing "/tmp/shared-standards/.github/workflows/" "$GITHUB_WORKSPACE/.github/workflows/"
```

Print what workflows were synced:
```bash
echo "⚙️ Synced GitHub Actions workflows:"
find "$GITHUB_WORKSPACE/.github/workflows/" -type f \( -name "terraform-*.yml" -o -name "terraform-*.yaml" \) | head -10
```

### Step 4: Summarize Changes

Count and report what was synced:
```bash
COPILOT_COUNT=$(find "$GITHUB_WORKSPACE/.github/copilot/" -type f -name "*.md" 2>/dev/null | wc -l)
WORKFLOW_COUNT=$(find "$GITHUB_WORKSPACE/.github/workflows/" -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | wc -l)

echo "📊 Sync Summary:"
echo "- Copilot files: $COPILOT_COUNT"
echo "- Workflows: $WORKFLOW_COUNT"
```

### Step 5: Open Pull Request

Summarize the changes and let the safe output job create the pull request with:
- Title: `[shared-standards-sync] Sync Copilot files and workflows`
- Label: `standards`, `automation`
- Description: List of synced files and directories

## Files and Directories

After sync, your repository will have:

```
.github/
├── copilot/
│   ├── prompts/
│   ├── agents/
│   └── instructions/
├── workflows/
│   ├── terraform-plan.yml
│   ├── terraform-deploy.yml
│   ├── terraform-validate.yml
│   └── [other workflows]
└── [other existing files]
```

Local files in these directories are preserved. Only files from shared-standards that don't exist locally are synced.

## Schedule

This workflow runs daily automatically on the default branch.

## Notes

- Files are synced without overwriting existing local versions (`--ignore-existing`)
- Only `.github/copilot/` and `.github/workflows/` directories from shared-standards are synced
- A pull request is created for review before changes are merged
- Uses GitHub App token for secure authentication
