#!/bin/bash
# Helper script to update GHCR download counts in stats files
#
# GitHub does not expose container download counts via API.
# This script helps you update them manually or via Claude Code WebFetch.
#
# Usage:
#   ./update-ghcr-counts.sh [YYYY-MM-DD.md]
#
# If no file specified, uses today's date.

set -e

# Determine stats file
if [ -n "$1" ]; then
    STATS_FILE="$1"
else
    STATS_FILE="$(date +%Y-%m-%d).md"
fi

if [ ! -f "$STATS_FILE" ]; then
    echo "Error: Stats file not found: $STATS_FILE" >&2
    echo "Run ./collect-stats.sh first to generate the file." >&2
    exit 1
fi

echo "Updating GHCR counts in: $STATS_FILE"
echo ""
echo "GitHub does not expose container download counts via API."
echo "You have two options:"
echo ""
echo "Option 1: Manual Update"
echo "  1. Visit: https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp"
echo "  2. Note the download counts for each package"
echo "  3. Edit $STATS_FILE and update the GHCR section"
echo ""
echo "Option 2: Use Claude Code WebFetch (if available)"
echo "  Ask Claude Code to run:"
echo "    WebFetch("
echo "      url=\"https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp\","
echo "      prompt=\"Extract download counts for: ha-mcp, ha-mcp-addon-amd64,"
echo "              ha-mcp-addon-aarch64, ha-mcp-addon-dev-amd64, ha-mcp-addon-dev-aarch64\""
echo "    )"
echo ""
echo "Option 3: Use this script to open the URL"
read -p "Open URL in browser? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp"
    elif command -v open >/dev/null 2>&1; then
        open "https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp"
    elif command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp"
    else
        echo "Could not detect browser opener. Visit URL manually."
    fi
fi

echo ""
echo "Template for updating $STATS_FILE:"
echo ""
cat << 'EOF'
## GHCR Container Downloads

Visit: https://github.com/orgs/homeassistant-ai/packages?repo_name=ha-mcp

| Package | Downloads |
|---------|-----------|
| ha-mcp | XXX,XXX |
| ha-mcp-addon-amd64 | X,XXX |
| ha-mcp-addon-aarch64 | X,XXX |
| ha-mcp-addon-dev-amd64 | X |
| ha-mcp-addon-dev-aarch64 | X |
| **Total** | **XXX,XXX** |
EOF

echo ""
echo "Edit $STATS_FILE to update the counts."
