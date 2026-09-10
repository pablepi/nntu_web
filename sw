const CACHE_NAME = 'nntu-map-v1';

// Базовые файлы оболочки приложения, которые сохраняются сразу при первой установке
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon.png',
  'https://unpkg.com/@panzoom/panzoom@4.5.1/dist/panzoom.min.js'
];

// Установка: кэшируем оболочку приложения
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(APP_SHELL);
    }).then(() => self.skipWaiting())
  );
});

// Активация: очищаем старые версии кэша, если версия обновилась
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

// Перехват запросов (Стратегия Cache First с фоновым обновлением / Network Fallback)
self.addEventListener('fetch', (event) => {
  // Игнорируем не-GET запросы
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Если ресурс уже в кэше — отдаем его моментально
        return cachedResponse;
      }

      // Если ресурса в кэше нет — грузим из сети и автоматически сохраняем в кэш на будущее
      return fetch(event.request).then((networkResponse) => {
        // Проверяем валидность ответа
        if (!networkResponse || networkResponse.status !== 200) {
          return networkResponse;
        }

        const responseToCache = networkResponse.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });

        return networkResponse;
      }).catch(() => {
        // Если сети нет и ресурса нет в кэше
        return cachedResponse;
      });
    })
  );
});