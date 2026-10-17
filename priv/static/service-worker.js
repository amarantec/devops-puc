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

// Push Notificaition 
self.addEventListener('push', function (event) {
    const data = event.data ? event.data.json() : {};
    const title = data.title || 'Nova mensagem';
    const options = {
        body: data.body || '',
        icon: data.icon || '/images/icon.png',
        badge: '/images/badge.png',
        data: { url: data.url || '/chats' }
    };
    
    event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
    event.notification.close();
    event.waitUntil(
        clients.openWindow(event.notification.data.url)
    );
});

