// sw.js — UniManager Service Worker
//
// ⚠️ Bump CACHE_VERSION in lockstep with APP_VERSION in index.html when deploying.
// CI's check-versions.mjs enforces this — but if you're editing this file by
// hand, remember: forgetting to bump here means returning users see stale code
// indefinitely (the SW keeps serving old index.html from cache).

const CACHE_VERSION = 'v1.3.0';
const CACHE_NAME = `unimanager-${CACHE_VERSION}`;

// Files to pre-cache on install. Anything not listed here is fetched on demand
// and only cached after first successful fetch.
const PRECACHE_URLS = [
  '/unimanager/',
  '/unimanager/index.html',
  '/unimanager/manifest.json',
  '/unimanager/icons/icon-192.png',
  '/unimanager/icons/icon-512.png',
  '/unimanager/icons/apple-touch-icon-180.png',
];

// Supabase/realtime requests should NEVER be served from cache — they're
// dynamic data. We use network-first for these and don't even attempt to
// cache the response.
const RUNTIME_BYPASS_PATTERNS = [
  /supabase\.co/,
  /supabase\.in/,
  /\/auth\/v1\//,
  /\/realtime\/v1\//,
];

// On install: pre-cache the app shell.
// NOTE: No skipWaiting() here — the new SW enters waiting state so the
// in-app update banner can appear. skipWaiting() is triggered only by
// the banner button via postMessage('SKIP_WAITING').
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
  );
});

// On activate: delete any old caches whose name doesn't match the current version.
// This is the cleanup that DOES NOT happen if you forget to bump CACHE_VERSION.
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim()) // take control of open tabs immediately
  );
});

// Fetch strategy:
//   1. Skip non-GET requests (we don't cache POST/PUT/DELETE)
//   2. Bypass cache entirely for Supabase requests
//   3. Cache-first for everything else, with network fallback + cache update
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Only handle GET. POST/PUT/DELETE go straight to network.
  if (request.method !== 'GET') return;

  // Skip Supabase endpoints — they're realtime data, never cache.
  if (RUNTIME_BYPASS_PATTERNS.some((pattern) => pattern.test(request.url))) {
    return; // let the browser handle it normally
  }

  // Cache-first with revalidation (stale-while-revalidate pattern).
  event.respondWith(
    caches.match(request).then((cached) => {
      const networkFetch = fetch(request)
        .then((response) => {
          // Only cache successful, basic (same-origin) responses.
          if (response && response.status === 200 && response.type === 'basic') {
            const responseClone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, responseClone));
          }
          return response;
        })
        .catch(() => cached); // offline + nothing cached → return whatever cached has (might be undefined)

      // Return cached immediately if available; the network update happens in background.
      return cached || networkFetch;
    })
  );
});

// Allow page to trigger immediate SW update (e.g., after bumping versions in dev).
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Handle push notifications
self.addEventListener('push', (event) => {
  if (!event.data) return;
  
  try {
    const payload = event.data.json();
    const options = {
      body: payload.body || 'UniManager notification',
      icon: '/unimanager/icons/icon-192.png',
      badge: '/unimanager/icons/icon-192.png',
      tag: payload.tag || 'unimanager-notification',
      requireInteraction: payload.requireInteraction || false,
      data: payload.data || {}
    };
    
    event.waitUntil(
      self.registration.showNotification(payload.title || 'UniManager', options)
    );
  } catch (e) {
    console.error('[SW] Push notification error:', e);
  }
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  // Open/focus the app window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (let client of clientList) {
        if (client.url === '/' || client.url.includes('/unimanager/')) {
          return client.focus();
        }
      }
      return clients.openWindow('/unimanager/');
    })
  );
});