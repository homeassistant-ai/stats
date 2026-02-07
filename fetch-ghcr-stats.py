#!/usr/bin/env python3
"""
Fetch GHCR (GitHub Container Registry) download counts.

GitHub doesn't expose container download counts via API, so this script
attempts to scrape them from the packages UI page.
"""

import re
import sys
import json
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


def fetch_ghcr_stats(org: str, repo: str) -> dict[str, int]:
    """
    Fetch GHCR download counts by scraping the packages page.

    Args:
        org: GitHub organization name
        repo: Repository name

    Returns:
        Dictionary mapping package names to download counts
    """
    url = f"https://github.com/orgs/{org}/packages?repo_name={repo}"

    # Create request with headers to mimic a browser
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
    }

    try:
        request = Request(url, headers=headers)
        with urlopen(request, timeout=10) as response:
            html = response.read().decode('utf-8')

        # Parse download counts from HTML
        # Pattern: package name followed by download count
        # The page structure: <a href="...">package-name</a> ... <span>123,456 downloads</span>

        packages = {}

        # Find all package containers
        # Look for patterns like: <a href="/orgs/.../packages/container/package-name">
        package_pattern = r'packages/container/([^"]+)"[^>]*>.*?(\d[\d,]*)\s*(?:total\s+)?downloads?'

        matches = re.finditer(package_pattern, html, re.DOTALL | re.IGNORECASE)

        for match in matches:
            package_name = match.group(1)
            download_count_str = match.group(2).replace(',', '')
            download_count = int(download_count_str)
            packages[package_name] = download_count

        return packages

    except (URLError, HTTPError) as e:
        print(f"Error fetching data: {e}", file=sys.stderr)
        return {}
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return {}


def format_number(num: int) -> str:
    """Format number with thousands separator."""
    return f"{num:,}"


def main():
    """Main entry point."""
    org = "homeassistant-ai"
    repo = "ha-mcp"

    print(f"Fetching GHCR stats for {org}/{repo}...", file=sys.stderr)

    packages = fetch_ghcr_stats(org, repo)

    if not packages:
        print("Failed to fetch GHCR stats", file=sys.stderr)
        print("Please update manually from:", file=sys.stderr)
        print(f"https://github.com/orgs/{org}/packages?repo_name={repo}", file=sys.stderr)
        sys.exit(1)

    # Print as JSON for easy parsing by shell script
    print(json.dumps(packages, indent=2))

    # Also print formatted table to stderr for human viewing
    print("\nGHCR Download Counts:", file=sys.stderr)
    print("-" * 50, file=sys.stderr)

    total = 0
    for package, count in sorted(packages.items()):
        print(f"  {package:30s} {format_number(count):>15s}", file=sys.stderr)
        total += count

    print("-" * 50, file=sys.stderr)
    print(f"  {'TOTAL':30s} {format_number(total):>15s}", file=sys.stderr)


if __name__ == "__main__":
    main()
