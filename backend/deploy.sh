#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v railway >/dev/null 2>&1; then
  echo "Install Railway CLI: brew install railway"
  exit 1
fi

if ! railway whoami >/dev/null 2>&1; then
  echo "Run 'railway login' first, then re-run this script."
  exit 1
fi

echo "Deploying SalesCoach API to Railway..."
railway up --detach

echo "Done. Verify with: curl \$(railway domain)/health"
