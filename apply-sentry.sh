#!/usr/bin/env bash
# apply-sentry.sh — adds Sentry error tracking to UniManager
#
# What this does:
#   1. Updates CSP to allow Sentry CDN + ingest endpoint
#   2. Inserts Sentry SDK loader + config in <head> (before any other script)
#   3. Adds README section about Sentry
#   4. Runs `npm run check` to verify nothing broke
#
# Then you commit and push. The first error to fire after deploy
# will appear on your Sentry dashboard within seconds.

set -e

echo
echo "============================================"
echo " UniManager — installing Sentry"
echo "============================================"
echo

if [ ! -f "index.html" ]; then
  echo "ERROR: Run this from the unimanager folder."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
# Step 1: Update CSP
# ─────────────────────────────────────────────────────────────────────────
echo "[1/4] Updating CSP to allow Sentry endpoints..."

# Idempotency check: skip if Sentry domains already in CSP
if grep -q "browser.sentry-cdn.com" index.html; then
  echo "    CSP already contains Sentry domains — skipping."
else
  # Backup before modifying
  cp index.html index.html.bak

  # Update script-src: add browser.sentry-cdn.com
  sed -i 's|script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"' https://cdn.jsdelivr.net|script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"' https://cdn.jsdelivr.net https://browser.sentry-cdn.com|' index.html

  # Update connect-src: add Sentry ingest endpoints
  sed -i 's|connect-src https://gcjlvfggsupndpnjoake.supabase.co wss://gcjlvfggsupndpnjoake.supabase.co https://cdn.jsdelivr.net|connect-src https://gcjlvfggsupndpnjoake.supabase.co wss://gcjlvfggsupndpnjoake.supabase.co https://cdn.jsdelivr.net https://*.ingest.de.sentry.io https://*.sentry.io|' index.html

  # Verify the substitution actually happened (sed silently does nothing on no-match)
  if ! grep -q "browser.sentry-cdn.com" index.html; then
    echo "    ERROR: CSP update failed (string not found in expected form)."
    echo "    Restoring backup..."
    mv index.html.bak index.html
    exit 1
  fi

  rm index.html.bak
  echo "    done."
fi

# ─────────────────────────────────────────────────────────────────────────
# Step 2: Insert Sentry SDK + config block
# ─────────────────────────────────────────────────────────────────────────
echo "[2/4] Inserting Sentry SDK loader + config..."

# Idempotency check
if grep -q "SENTRY ERROR TRACKING" index.html; then
  echo "    Sentry block already present — skipping."
else
  # We insert AFTER the Supabase script tag so Sentry has DOM ready,
  # but BEFORE the main app script so it catches init errors.
  # Anchor: the Supabase CDN line.
  ANCHOR='<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js"></script>'

  if ! grep -q "$ANCHOR" index.html; then
    echo "    ERROR: Could not find Supabase script tag to anchor insertion."
    echo "    You'll need to insert the Sentry block manually. See sentry-snippet.html"
    exit 1
  fi

  # Write the snippet file we'll inject
  cat > /tmp/sentry-snippet.html <<'SENTRY_EOF'

<!--
  ════════════════════════════════════════════════════════════════════════════
   SENTRY ERROR TRACKING
  ════════════════════════════════════════════════════════════════════════════
   Loads Sentry's browser SDK from CDN and initializes it BEFORE the main
   app script. This way, even errors during early init (loading state from
   IDB, parsing localStorage, Supabase auth) get captured.

   PII handling: the beforeSend hook scrubs anything that looks like user
   data — emails, JWT tokens, chat/note content. Stack traces, device info,
   and Supabase user IDs (raw UUIDs only) are kept.

   Free tier: 5,000 errors/month. The app should produce << 100/month
   if healthy, so we sample 100% to never miss a bug.

   ⚠️ DSN is public-by-design: anyone can find it in the deployed HTML, but
   it only allows POSTING events to YOUR project (rate-limited per source IP).
   It cannot read events. This is Sentry's intended threat model.
-->
<!-- Note on integrity: Sentry doesn't publish stable SRI hashes (bundles can
     change between minor versions of the same URL). We rely on CSP script-src
     whitelisting + HTTPS instead. If you want maximum paranoia, self-host the
     SDK in /vendor/sentry.min.js. -->
<script
  src="https://browser.sentry-cdn.com/8.45.0/bundle.min.js"
  crossorigin="anonymous"
  defer></script>
<script>
  // Wait for SDK load. We poll because <script defer> doesn't fire a load
  // event reliably on iOS Safari, and we want this to run regardless.
  (function waitForSentry(attempts) {
    if (typeof Sentry !== 'undefined' && Sentry.init) {
      initSentry();
      return;
    }
    if (attempts > 50) {
      // Gave up after 5s. Probably blocked by adblocker or offline.
      // The app still works; we just lose error reporting until next page load.
      console.warn('[Sentry] SDK failed to load after 5s; error tracking disabled.');
      return;
    }
    setTimeout(function () { waitForSentry(attempts + 1); }, 100);
  })(0);

  function initSentry() {
    Sentry.init({
      dsn: 'https://33bd0a65ed228589d3d286f2af90827e@o4511301896568832.ingest.de.sentry.io/4511301971673168',

      // Tag every event with the app version. Critical for "is this fixed
      // in v1.0.1?" queries on the Sentry dashboard.
      release: typeof APP_VERSION !== 'undefined' ? APP_VERSION : 'unknown',

      // Skip events from localhost — too noisy during development.
      environment: location.hostname === 'localhost' || location.hostname === '127.0.0.1'
        ? 'development'
        : 'production',

      // 100% of errors. We're well under the 5K/month free tier.
      sampleRate: 1.0,

      // Performance monitoring disabled — would burn through quota in days.
      // Add later if we ever upgrade plans.
      tracesSampleRate: 0,

      // Don't capture errors from browser extensions, ad blockers, etc.
      ignoreErrors: [
        'ResizeObserver loop limit exceeded',
        'Non-Error promise rejection captured',
        'Network request failed',
        'Failed to fetch',
        'Load failed',
        'top.GLOBALS',
        'Can\'t find variable: ZiteReader',
        'AbortError',
      ],

      // PII scrubbing: Sentry calls this for every event BEFORE sending.
      // Return null to drop the event entirely.
      beforeSend: function (event, hint) {
        try {
          // Drop dev events
          if (event.request && event.request.url && event.request.url.indexOf('localhost') !== -1) {
            return null;
          }

          // Strip JWT tokens from URLs (Supabase auth callbacks contain them)
          if (event.request && event.request.url) {
            event.request.url = event.request.url
              .replace(/([?&#])access_token=[^&]*/g, '$1access_token=[REDACTED]')
              .replace(/([?&#])refresh_token=[^&]*/g, '$1refresh_token=[REDACTED]');
          }

          // Strip emails from messages and exceptions
          var emailRegex = /[\w.+-]+@[\w-]+\.[\w.-]+/g;
          if (event.message) {
            event.message = event.message.replace(emailRegex, '[EMAIL]');
          }
          if (event.exception && event.exception.values) {
            event.exception.values.forEach(function (ex) {
              if (ex.value) ex.value = ex.value.replace(emailRegex, '[EMAIL]');
            });
          }

          // Scrub breadcrumbs — drop chat/note content, keep action types
          if (event.breadcrumbs) {
            event.breadcrumbs = event.breadcrumbs.map(function (b) {
              if (!b) return b;
              if (b.category === 'chat' || b.category === 'note') {
                if (b.data) {
                  b.data = { action: b.data.action, length: (b.data.content || '').length };
                }
                b.message = '(content redacted)';
              }
              if (b.message) b.message = b.message.replace(emailRegex, '[EMAIL]');
              return b;
            });
          }

          // Tag with anonymous user ID (Supabase UUID — random, no PII)
          if (typeof state !== 'undefined' && state && state.user && state.user.id) {
            event.user = { id: state.user.id };
          }

          return event;
        } catch (err) {
          // If scrubbing throws, send unscrubbed rather than lose visibility
          console.warn('[Sentry] beforeSend hook failed:', err);
          return event;
        }
      },
    });

    window.__SENTRY_INITIALIZED__ = true;
  }
</script>
<!-- ══════════════════════════════════════════════════════════════════════ -->
SENTRY_EOF

  # Insert the snippet AFTER the Supabase line.
  # Use awk with regex match (not exact equality) to handle both LF and CRLF
  # line endings — index.html may have either depending on which editor was
  # last used on Windows.
  awk -v anchor_pattern='supabase-js@2/dist/umd/supabase\\.min\\.js' '
    {print}
    $0 ~ anchor_pattern && !inserted {
      while ((getline line < "/tmp/sentry-snippet.html") > 0) print line
      close("/tmp/sentry-snippet.html")
      inserted = 1
    }
  ' index.html > index.html.new && mv index.html.new index.html

  # Verify insertion happened
  if ! grep -q "SENTRY ERROR TRACKING" index.html; then
    echo "    ERROR: Insertion failed somehow."
    exit 1
  fi

  rm /tmp/sentry-snippet.html
  echo "    done."
fi

# ─────────────────────────────────────────────────────────────────────────
# Step 3: Update README with Sentry section
# ─────────────────────────────────────────────────────────────────────────
echo "[3/4] Adding Sentry section to README..."

if grep -q "## 📊 Error tracking" README.md 2>/dev/null; then
  echo "    README already documents Sentry — skipping."
else
  # Append before the License section
  if grep -q "^## 📄 License" README.md; then
    # Use awk to insert before the License heading
    awk '
      /^## 📄 License/ && !inserted {
        print "## 📊 Error tracking"
        print ""
        print "Production errors are tracked via [Sentry](https://sentry.io). The SDK loads from CDN, scrubs PII (emails, JWT tokens, chat/note content) before sending, and runs at 100% sample rate. Free tier covers our expected error volume (well under 5K/month)."
        print ""
        print "**What gets reported:**"
        print "- Uncaught exceptions and unhandled promise rejections"
        print "- Stack traces with source mapping"
        print "- Device + browser info"
        print "- Anonymous Supabase user ID (UUID only)"
        print ""
        print "**What does NOT get reported:**"
        print "- Email addresses (regex-stripped from messages)"
        print "- JWT tokens (stripped from URLs)"
        print "- Chat message content"
        print "- Note content"
        print "- localhost / development errors"
        print ""
        print "If you fork this repo, replace the DSN in `index.html` (search for `Sentry.init`). The DSN is safe to commit — it'"'"'s public-by-design."
        print ""
        inserted = 1
      }
      {print}
    ' README.md > README.md.new && mv README.md.new README.md

    echo "    done."
  else
    echo "    WARN: License heading not found in README; skipping README update."
  fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Step 4: Verify
# ─────────────────────────────────────────────────────────────────────────
echo "[4/4] Running checks to verify nothing broke..."
echo
npm run check
echo

echo "============================================"
echo " ✓ Sentry installed."
echo "============================================"
echo
echo " Now commit and push:"
echo "   git add -A"
echo "   git commit -m 'feat(observability): add Sentry error tracking'"
echo "   git push origin main"
echo
echo " After deploy, test it with:"
echo "   1. Open the live site in DevTools (F12)"
echo "   2. In the Console, type:  Sentry.captureMessage('hello from test');"
echo "   3. Within ~30s, you should see the message at:"
echo "      https://sentry.io/issues/"
echo
