#!/usr/bin/env bash
# publish.sh — generate a new blog post and push it to origin/main.
#
# Usage:
#   ./publish.sh                 Run once manually
#   ./publish.sh --dry-run       Run pipeline but do not save or push
#
# Crontab setup (run every day at 08:00):
#   1. Open your crontab:  crontab -e
#   2. Add the line below (adjust path and time as needed):
#
#      0 8 * * * /bin/bash /path/publish.sh >> /path/to/logs/publish.log 2>&1
#
#   Common cron time expressions:
#     0 8 * * *     — daily at 08:00
#     0 8 * * 1     — every Monday at 08:00
#     0 8 1 * *     — first day of every month at 08:00
#     0 8 * * 1,3,5 — Mon/Wed/Fri at 08:00
#
# Notes:
#   - The script must be executable: chmod +x publish.sh
#   - Ensure the cron environment can find bloggerai (use full path if needed).
#   - API keys must be available in the environment or in .env in this directory.
#   - Git must be configured with push access (SSH key or credential helper).

set -euo pipefail

BLOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=""

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="--dry-run"
  echo "[publish] dry-run mode — no files will be saved or pushed"
fi

echo "[publish] $(date '+%Y-%m-%d %H:%M:%S') — starting post generation"

# Load .env if present
if [[ -f "$BLOG_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$BLOG_DIR/.env"; set +a
fi

# Generate the post
bloggerai post generate --blog-dir "$BLOG_DIR" $DRY_RUN

if [[ -n "$DRY_RUN" ]]; then
  echo "[publish] dry-run complete — skipping git commit/push"
  exit 0
fi

# Commit and push
cd "$BLOG_DIR"

if [[ -z "$(git status --porcelain)" ]]; then
  echo "[publish] nothing to commit — post may already exist"
  exit 0
fi

git add -A
git commit -m "Publish new post"
git push origin main

echo "[publish] $(date '+%Y-%m-%d %H:%M:%S') — done"
