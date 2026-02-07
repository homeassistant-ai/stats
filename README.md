# ha-mcp Statistics Tracking

Weekly statistics for the ha-mcp project.

## Collecting Stats

Run the collection script:

```bash
./collect-stats.sh
```

This will create a dated markdown file (e.g., `2025-12-15.md`) with all available stats.

## Manual Steps Required

GHCR container download counts are **not available via API**. After running the script:

### Option 1: Use Helper Script (Recommended)
```bash
./update-ghcr-counts.sh [YYYY-MM-DD.md]
```
This script provides guidance and opens the packages page in your browser.

### Option 2: Manual Update
1. Visit https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp
2. Note the download counts for each package
3. Update the "GHCR Container Downloads" section in the generated file

### Option 3: Use Claude Code WebFetch
If you have Claude Code available, ask it to fetch the counts:
```
WebFetch(
  url="https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp",
  prompt="Extract download counts for all ha-mcp packages"
)
```

## Prerequisites

- `gh` CLI authenticated with `read:packages` scope
- `curl`, `python3`, `jq`, `bc`

To add the packages scope:
```bash
gh auth refresh -s read:packages
```

## Schedule

Collect stats weekly (e.g., every Sunday) to track growth trends.

## Files

- `collect-stats.sh` - Automated stats collection script
- `update-ghcr-counts.sh` - Helper to update GHCR download counts
- `fetch-ghcr-stats.py` - Experimental Python scraper (currently limited by GitHub's dynamic loading)
- `YYYY-MM-DD.md` - Weekly stat snapshots
- `.github/workflows/collect-stats.yml` - Automated weekly collection via GitHub Actions
