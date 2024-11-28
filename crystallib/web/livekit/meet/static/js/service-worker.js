const MAX_RETRIES = 3;

self.addEventListener('fetch', (event) => {
    if (event.request.url.endsWith('.js')) {
        event.respondWith(fetchWithRetry(event.request, MAX_RETRIES));
    }
});

async function fetchWithRetry(request, retries) {
    try {
        return await fetch(request);
    } catch (error) {
        if (retries > 0) {
            console.log(`Retrying ${request.url} (${retries} retries left)`);
            return fetchWithRetry(request, retries - 1);
        } else {
            console.error(`Failed to fetch ${request.url} after several retries.`);
            throw error;
        }
    }
}