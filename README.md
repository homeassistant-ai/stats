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

1. Visit https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp
2. Note the download counts for each package
3. Update the "GHCR Container Downloads" section in the generated file

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

- `collect-stats.sh` - Automated collection script
- `YYYY-MM-DD.md` - Weekly snapshots
