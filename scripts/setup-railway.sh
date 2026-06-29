#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"

echo "=== Sales Coach Railway Setup ==="
echo ""

if ! command -v railway >/dev/null 2>&1; then
  echo "Installing Railway CLI..."
  npm install -g @railway/cli
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required. Install from https://nodejs.org"
  exit 1
fi

cd "$BACKEND"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created backend/.env — add your OPENAI_API_KEY and API_SECRET before deploying."
fi

echo "Installing backend dependencies..."
npm install

echo ""
echo "Step 1: Log in to Railway (opens browser)"
railway login

echo ""
echo "Step 2: Create/link Railway project in backend/"
railway init --name salescoach-api

echo ""
echo "Step 3: Set secrets on Railway"
read -r -p "Paste your OpenAI API key: " OPENAI_KEY
read -r -p "Create an API secret for the iOS app (or press Enter for random): " API_SECRET
if [ -z "$API_SECRET" ]; then
  API_SECRET=$(openssl rand -hex 24)
  echo "Generated API_SECRET: $API_SECRET"
fi

railway variables set OPENAI_API_KEY="$OPENAI_KEY"
railway variables set API_SECRET="$API_SECRET"
railway variables set OPENAI_MODEL="gpt-4o-mini"

echo ""
echo "Step 4: Deploy to Railway"
railway up --detach

echo ""
echo "Step 5: Get your public URL"
RAILWAY_URL=$(railway domain 2>/dev/null || true)
if [ -z "$RAILWAY_URL" ]; then
  echo "Generate a domain in Railway dashboard, then run:"
  echo "  cd backend && railway domain"
else
  echo "API URL: https://$RAILWAY_URL"
fi

echo ""
echo "=== iOS app configuration ==="
echo "In Xcode, edit SalesCoach scheme → Run → Environment Variables:"
echo "  RAILWAY_API_URL = https://YOUR-APP.up.railway.app"
echo "  RAILWAY_API_KEY = $API_SECRET"
echo ""
echo "Or add to SalesCoach/Config/AppConfig.swift production URL after deploy."
echo "Done."
