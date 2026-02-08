#!/bin/bash
# ha-mcp Statistics Collection Script
# Run weekly to track project growth
#
# Usage: ./collect-stats.sh
#
# Prerequisites:
#   - gh cli authenticated with read:packages scope
#   - curl, python3, jq
#
# Note: GHCR download counts must be added manually from:
#   https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp

set -e

DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$(dirname "$0")/${DATE}.md"

echo "Collecting ha-mcp statistics for ${DATE}..."

# Get repo info
echo "Fetching GitHub repo stats..."
REPO_STATS=$(gh api repos/homeassistant-ai/ha-mcp --jq '{stars: .stargazers_count, forks: .forks_count, open_issues: .open_issues_count, created_at: .created_at}')
STARS=$(echo "$REPO_STATS" | jq -r '.stars')
FORKS=$(echo "$REPO_STATS" | jq -r '.forks')
OPEN_ISSUES=$(echo "$REPO_STATS" | jq -r '.open_issues')

# Get traffic (clones)
echo "Fetching GitHub traffic..."
CLONES_DATA=$(gh api repos/homeassistant-ai/ha-mcp/traffic/clones)
TOTAL_CLONES=$(echo "$CLONES_DATA" | jq '.count')
UNIQUE_CLONERS=$(echo "$CLONES_DATA" | jq '.uniques')

# Get traffic (views)
VIEWS_DATA=$(gh api repos/homeassistant-ai/ha-mcp/traffic/views)
TOTAL_VIEWS=$(echo "$VIEWS_DATA" | jq '.count')
UNIQUE_VISITORS=$(echo "$VIEWS_DATA" | jq '.uniques')

# Get release info
echo "Fetching release stats..."
TOTAL_RELEASES=$(gh api repos/homeassistant-ai/ha-mcp/releases --paginate --jq '. | length' | paste -sd+ | bc)
BINARY_DOWNLOADS=$(gh api repos/homeassistant-ai/ha-mcp/releases --paginate --jq '[.[].assets[].download_count] | add')

# Get issue/PR counts
TOTAL_ISSUES=$(gh issue list -R homeassistant-ai/ha-mcp --state all --json number --jq 'length')
TOTAL_PRS=$(gh pr list -R homeassistant-ai/ha-mcp --state all --json number --jq 'length')

# Get PyPI stats
echo "Fetching PyPI stats..."
PYPI_JSON=$(curl -s "https://pypi.org/pypi/ha-mcp/json")
CURRENT_VERSION=$(echo "$PYPI_JSON" | jq -r '.info.version')
PYPI_RELEASES=$(echo "$PYPI_JSON" | jq '.releases | keys | length')

# PyPI downloads (may be rate limited)
PYPI_DOWNLOADS="Check pypistats.org manually if rate limited"
PYPI_OVERALL=$(curl -s "https://pypistats.org/api/packages/ha-mcp/overall?mirrors=false" 2>/dev/null)
if echo "$PYPI_OVERALL" | jq -e '.data' > /dev/null 2>&1; then
    PYPI_DOWNLOADS=$(echo "$PYPI_OVERALL" | jq '[.data[].downloads] | add')
fi

# Calculate 7-day traffic
WEEK_CLONES=$(echo "$CLONES_DATA" | jq '[.clones[-7:][].count] | add // 0')
WEEK_UNIQUE_CLONERS=$(echo "$CLONES_DATA" | jq '[.clones[-7:][].uniques] | add // 0')
WEEK_VIEWS=$(echo "$VIEWS_DATA" | jq '[.views[-7:][].count] | add // 0')
WEEK_UNIQUE_VISITORS=$(echo "$VIEWS_DATA" | jq '[.views[-7:][].uniques] | add // 0')

# Fetch GHCR download counts
echo "Fetching GHCR download counts..."
SCRIPT_DIR="$(dirname "$0")"
if [ -x "$SCRIPT_DIR/fetch-ghcr-stats.sh" ]; then
    GHCR_JSON=$("$SCRIPT_DIR/fetch-ghcr-stats.sh" --json 2>/dev/null || echo "{}")
    GHCR_HA_MCP=$(echo "$GHCR_JSON" | jq -r '."ha-mcp" // "TODO"' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
    GHCR_AMD64=$(echo "$GHCR_JSON" | jq -r '."ha-mcp-addon-amd64" // "TODO"' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
    GHCR_AARCH64=$(echo "$GHCR_JSON" | jq -r '."ha-mcp-addon-aarch64" // "TODO"' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
    GHCR_DEV_AMD64=$(echo "$GHCR_JSON" | jq -r '."ha-mcp-addon-dev-amd64" // "TODO"')
    GHCR_DEV_AARCH64=$(echo "$GHCR_JSON" | jq -r '."ha-mcp-addon-dev-aarch64" // "TODO"')
    GHCR_TOTAL=$(echo "$GHCR_JSON" | jq -r '.total // "TODO"' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
else
    GHCR_HA_MCP="TODO"
    GHCR_AMD64="TODO"
    GHCR_AARCH64="TODO"
    GHCR_DEV_AMD64="TODO"
    GHCR_DEV_AARCH64="TODO"
    GHCR_TOTAL="TODO"
fi

# Write report
cat > "$OUTPUT_FILE" << EOF
# ha-mcp Statistics - ${DATE}

## Project Overview

| Metric | Value |
|--------|-------|
| Repo Created | September 14, 2025 |
| First PyPI Release | November 6, 2025 |
| Current Version | ${CURRENT_VERSION} |
| Total PyPI Releases | ${PYPI_RELEASES} |
| Total GitHub Releases | ${TOTAL_RELEASES} |

---

## PyPI Downloads

| Period | Downloads |
|--------|-----------|
| Total (since inception) | ${PYPI_DOWNLOADS} |

---

## GitHub Traffic (14-day rolling window)

| Metric | Last 14 days | Last 7 days |
|--------|--------------|-------------|
| Clones | ${TOTAL_CLONES} | ${WEEK_CLONES} |
| Unique cloners | ${UNIQUE_CLONERS} | ${WEEK_UNIQUE_CLONERS} |
| Page views | ${TOTAL_VIEWS} | ${WEEK_VIEWS} |
| Unique visitors | ${UNIQUE_VISITORS} | ${WEEK_UNIQUE_VISITORS} |

---

## GitHub Repository

| Metric | Count |
|--------|-------|
| Stars | ${STARS} |
| Forks | ${FORKS} |
| Open issues | ${OPEN_ISSUES} |
| Total issues | ${TOTAL_ISSUES} |
| Total PRs | ${TOTAL_PRS} |
| Binary downloads | ${BINARY_DOWNLOADS} |

---

## GHCR Container Downloads

Visit: https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp

| Package | Downloads |
|---------|-----------|
| ha-mcp | ${GHCR_HA_MCP} |
| ha-mcp-addon-amd64 | ${GHCR_AMD64} |
| ha-mcp-addon-aarch64 | ${GHCR_AARCH64} |
| ha-mcp-addon-dev-amd64 | ${GHCR_DEV_AMD64} |
| ha-mcp-addon-dev-aarch64 | ${GHCR_DEV_AARCH64} |
| **Total** | **${GHCR_TOTAL}** |

---

## Notes

- GitHub traffic API only retains 14 days of data
- GHCR download counts are not available via API (must check UI manually)
- PyPI stats from pypistats.org API (may be rate limited)
EOF

echo ""
echo "Stats written to: ${OUTPUT_FILE}"

if [ "$GHCR_HA_MCP" == "TODO" ]; then
    echo ""
    echo "⚠️  GHCR download counts could not be fetched automatically."
    echo "   Run ./fetch-ghcr-stats.sh to try again, or update manually:"
    echo "   https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp"
else
    echo ""
    echo "✅ GHCR download counts fetched successfully!"
fi
