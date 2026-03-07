import React from 'react';

const RETRY_PREFIX = 'lazy-retry:';

function isDynamicImportError(error) {
  const message = error?.message || '';

  return [
    'ChunkLoadError',
    'Failed to fetch dynamically imported module',
    'Importing a module script failed',
    'error loading dynamically imported module',
    'Loading chunk',
  ].some(fragment => message.includes(fragment));
}

export function lazyWithRetry(importer, cacheKey) {
  return React.lazy(async () => {
    const storageKey = `${RETRY_PREFIX}${cacheKey}`;

    try {
      const module = await importer();
      window.sessionStorage.removeItem(storageKey);
      return module;
    } catch (error) {
      const hasRetried = window.sessionStorage.getItem(storageKey) === 'true';

      if (isDynamicImportError(error) && !hasRetried) {
        window.sessionStorage.setItem(storageKey, 'true');
        window.location.reload();

        return new Promise(() => {});
      }

      window.sessionStorage.removeItem(storageKey);
      throw error;
    }
  });
}