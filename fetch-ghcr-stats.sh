#!/bin/bash
# Fetch GHCR download counts from GitHub packages page
#
# Usage: ./fetch-ghcr-stats.sh [--json]

set -e

ORG="homeassistant-ai"
REPO="ha-mcp"
URL="https://github.com/orgs/${ORG}/packages?repo_name=${REPO}"

# Fetch HTML
HTML=$(curl -s -L "$URL")

# Extract package names and download counts
# The HTML structure has package links followed by download icons and counts
PACKAGES=($(echo "$HTML" | grep -o 'packages/container/package/[^"]*' | sed 's/.*\///'))
DOWNLOADS=($(echo "$HTML" | grep -A 3 "octicon-download" | grep -E "^\s+[0-9]+(\.[0-9]+)?[kKmM]?\s*$" | tr -d ' '))

# Convert k/M notation to actual numbers
convert_to_number() {
    local value="$1"
    if [[ $value =~ ^([0-9]+(\.[0-9]+)?)[kK]$ ]]; then
        # Convert k to thousands
        num="${BASH_REMATCH[1]}"
        echo "$num * 1000" | bc | cut -d. -f1
    elif [[ $value =~ ^([0-9]+(\.[0-9]+)?)[mM]$ ]]; then
        # Convert M to millions
        num="${BASH_REMATCH[1]}"
        echo "$num * 1000000" | bc | cut -d. -f1
    else
        echo "$value"
    fi
}

# Format number with commas
format_number() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Output format
if [ "$1" == "--json" ]; then
    # JSON output
    echo "{"
    total=0
    for i in "${!PACKAGES[@]}"; do
        package="${PACKAGES[$i]}"
        download="${DOWNLOADS[$i]}"
        num=$(convert_to_number "$download")
        total=$((total + num))
        echo "  \"$package\": $num,"
    done
    echo "  \"total\": $total"
    echo "}"
else
    # Table output
    echo "GHCR Download Counts for $ORG/$REPO"
    echo "========================================"
    echo ""
    printf "%-30s %15s\n" "Package" "Downloads"
    printf "%-30s %15s\n" "-------" "---------"

    total=0
    for i in "${!PACKAGES[@]}"; do
        package="${PACKAGES[$i]}"
        download="${DOWNLOADS[$i]}"
        num=$(convert_to_number "$download")
        total=$((total + num))
        formatted=$(format_number "$num")
        printf "%-30s %15s\n" "$package" "$formatted"
    done

    echo "========================================"
    formatted_total=$(format_number "$total")
    printf "%-30s %15s\n" "TOTAL" "$formatted_total"
fi
