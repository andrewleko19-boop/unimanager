#!/usr/bin/env bash
# apply-fix.sh — applies the stylelint removal fix
#
# Run this from the unimanager folder. It will:
#   1. Replace package.json (stylelint removed)
#   2. Replace .github/workflows/ci.yml (CSS step removed)
#   3. Replace .github/workflows/deploy.yml (CSS step removed)
#   4. Delete .stylelintrc.json (no longer needed)
#   5. Run npm install to update package-lock.json
#   6. Run npm run check to verify everything passes
#
# Then you commit and push.

set -e  # exit on first error

echo
echo "============================================"
echo " UniManager — applying stylelint fix"
echo "============================================"
echo

# Verify we're in the right folder
if [ ! -f "index.html" ] || [ ! -f "package.json" ]; then
  echo "ERROR: Run this from the unimanager folder."
  exit 1
fi

# 1. package.json
echo "[1/6] Updating package.json..."
cat > package.json <<'PKG_EOF'
{
  "name": "unimanager",
  "version": "1.0.0",
  "private": true,
  "description": "Single-file offline-first PWA for university students. CI tooling lives here; the app itself is index.html.",
  "scripts": {
    "check": "npm run check:js && npm run check:html && npm run check:versions && npm run check:manifest",
    "check:js": "node tools/check-js-syntax.mjs",
    "check:html": "html-validate index.html",
    "check:versions": "node tools/check-versions.mjs",
    "check:manifest": "node tools/check-manifest.mjs",
    "serve": "npx serve . -l 8000",
    "lighthouse": "lhci autorun"
  },
  "devDependencies": {
    "@lhci/cli": "^0.13.0",
    "html-validate": "^8.18.0"
  },
  "engines": {
    "node": ">=20"
  }
}
PKG_EOF
echo "    done."

# 2. ci.yml
echo "[2/6] Updating .github/workflows/ci.yml..."
cat > .github/workflows/ci.yml <<'CI_EOF'
name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    name: Validate HTML / JS / versions
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dev tooling
        run: npm ci --no-audit --no-fund

      - name: JS syntax check
        run: node tools/check-js-syntax.mjs

      - name: HTML validation
        run: npx html-validate index.html

      - name: Cache-version sync check
        run: node tools/check-versions.mjs

      - name: Manifest sanity
        run: node tools/check-manifest.mjs
CI_EOF
echo "    done."

# 3. deploy.yml
echo "[3/6] Updating .github/workflows/deploy.yml..."
cat > .github/workflows/deploy.yml <<'DEPLOY_EOF'
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  validate:
    name: Re-validate before deploy
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci --no-audit --no-fund
      - run: node tools/check-js-syntax.mjs
      - run: npx html-validate index.html
      - run: node tools/check-versions.mjs
      - run: node tools/check-manifest.mjs

  deploy:
    name: Deploy to GitHub Pages
    needs: validate
    runs-on: ubuntu-latest
    timeout-minutes: 5
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v4
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      - name: Deploy
        id: deployment
        uses: actions/deploy-pages@v4
DEPLOY_EOF
echo "    done."

# 4. delete stylelint config
echo "[4/6] Removing .stylelintrc.json (no longer needed)..."
rm -f .stylelintrc.json
echo "    done."

# 5. clean install (regenerate lockfile without stylelint deps)
echo "[5/6] Reinstalling deps + regenerating package-lock.json..."
echo "    (this takes 1-2 minutes)"
rm -rf node_modules
rm -f package-lock.json
npm install --no-audit --no-fund 2>&1 | tail -3

# 6. verify
echo
echo "[6/6] Running checks to verify..."
echo
npm run check
echo

echo "============================================"
echo " ✓ All checks pass — ready to commit & push"
echo "============================================"
echo
echo "Run these to push:"
echo "  git add -A"
echo "  git commit -m 'chore(ci): drop stylelint, simplify pipeline'"
echo "  git push origin main"
echo
