// tools/check-js-syntax.mjs
//
// Extracts every inline <script> block from index.html (skipping external
// src= references) and runs `node --check` on each to catch syntax errors.
//
// Why this matters: a single-file app means a typo in script #2 silently
// breaks the WHOLE app at parse time. Browsers fail differently than Node,
// but the overlap of pure-syntax errors is huge. Catching them in CI saves
// you from "deployed, white screen, frantic git revert" cycles.
//
// We deliberately use Node's parser (modern, permissive) rather than a third-
// party lint tool. The goal is "is this parseable JavaScript?", not style.

import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const DIM = '\x1b[2m';
const RESET = '\x1b[0m';

const html = readFileSync('index.html', 'utf8');

// Match <script>...</script> blocks but skip ones with src="..." (external).
// The (?![^>]*\bsrc=) negative lookahead handles `<script src="...">` and
// `<script type="..." src="...">` alike.
const scriptRegex = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;

const scripts = [];
let m;
while ((m = scriptRegex.exec(html)) !== null) {
  scripts.push({
    body: m[1],
    // Approximate line number where this script starts in index.html — useful
    // for error messages.
    startLine: html.slice(0, m.index).split('\n').length,
  });
}

if (scripts.length === 0) {
  console.error(`${RED}✗ No inline <script> blocks found in index.html${RESET}`);
  console.error(`  Either the file is misnamed or the regex needs updating.`);
  process.exit(1);
}

const tmp = join(tmpdir(), `unimanager-syntax-check-${process.pid}`);
mkdirSync(tmp, { recursive: true });

let failed = 0;

for (const [i, { body, startLine }] of scripts.entries()) {
  const file = join(tmp, `script-${i}.mjs`);
  writeFileSync(file, body);
  try {
    // --check parses without executing. Catches every syntax error,
    // doesn't run any of your code (so no Supabase calls etc.).
    execSync(`node --check "${file}"`, { stdio: 'pipe' });
    console.log(`${GREEN}✓${RESET} script #${i + 1} (starts ~line ${startLine}) ${DIM}— ${body.length.toLocaleString()} chars${RESET}`);
  } catch (err) {
    failed++;
    console.error(`${RED}✗ script #${i + 1} (starts ~line ${startLine}) — syntax error:${RESET}`);
    // Node prints the error to stderr; surface it.
    console.error(err.stderr?.toString() || err.message);
  }
}

// Clean up temp files even if checks failed.
rmSync(tmp, { recursive: true, force: true });

if (failed > 0) {
  console.error(`\n${RED}${failed} script block(s) failed syntax check${RESET}`);
  process.exit(1);
}

console.log(`\n${GREEN}All ${scripts.length} inline script(s) parse cleanly${RESET}`);
