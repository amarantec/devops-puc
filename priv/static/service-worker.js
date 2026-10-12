const CACHE_NAME = "phx-app-v1";
const ASSETS_TO_CACHE = [
  '/',
'/assets/js/app.js',
'/assets/css/app.css',
'/manifest.json'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
});

self.addEventListener('fetch', event => {
  const url =new URL(event.request.url);
  if (url.pathname.startsWith('/live/')) {
    return;
  }
  if (url.pathname.startsWith('/users/') || event.request.method !== 'GET') {
    return;
  }

  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
})
