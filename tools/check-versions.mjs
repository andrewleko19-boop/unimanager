// tools/check-versions.mjs
//
// Enforces that the version constants in index.html and sw.js are in sync.
// Reason: when CACHE_VERSION in sw.js doesn't change between releases, the
// Service Worker keeps serving stale cached files — including stale index.html
// itself. Returning users get the OLD app for days. This was a real bug we hit
// twice during initial development.
//
// Strategy: extract both constants via regex, compare, fail with a clear
// message if they differ or are missing.
//
// Exit codes: 0 = match, 1 = mismatch or missing constant

import { readFileSync } from 'node:fs';

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';

function readText(path) {
  try {
    return readFileSync(path, 'utf8');
  } catch (err) {
    console.error(`${RED}✗ Could not read ${path}: ${err.message}${RESET}`);
    process.exit(1);
  }
}

// Parse: const APP_VERSION = 'v1.0.0';   (single OR double quotes, any whitespace)
function extractVersion(source, constName, file) {
  const re = new RegExp(`const\\s+${constName}\\s*=\\s*['"]([^'"]+)['"]`);
  const match = source.match(re);
  if (!match) {
    console.error(`${RED}✗ ${constName} not found in ${file}${RESET}`);
    console.error(`  Expected a line like: const ${constName} = 'v1.2.3';`);
    process.exit(1);
  }
  return match[1];
}

const indexHtml = readText('index.html');
const swJs = readText('sw.js');

const appVersion = extractVersion(indexHtml, 'APP_VERSION', 'index.html');
const cacheVersion = extractVersion(swJs, 'CACHE_VERSION', 'sw.js');

if (appVersion !== cacheVersion) {
  console.error(`${RED}${BOLD}✗ Version mismatch${RESET}`);
  console.error(`  index.html  APP_VERSION   = ${appVersion}`);
  console.error(`  sw.js       CACHE_VERSION = ${cacheVersion}`);
  console.error(``);
  console.error(`  These MUST be identical. When you deploy a new version, bump`);
  console.error(`  both. Otherwise the Service Worker won't invalidate its cache`);
  console.error(`  and returning users will see the old app indefinitely.`);
  process.exit(1);
}

console.log(`${GREEN}✓ Versions synced: ${appVersion}${RESET}`);
