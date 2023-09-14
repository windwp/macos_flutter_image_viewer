import type { Handle } from "@sveltejs/kit";

export const handle: Handle = async ({ event, resolve }) => {
  event.request.headers.set(
    "Content-Security-Policy",
    "default-src 'self' *;frame-ancestors 'self' *;frame-src 'self' *;img-src 'self' *;script-src 'self' *;style-src 'self' *;"
  );
  return resolve(event);
};
