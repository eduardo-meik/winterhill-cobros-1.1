import { useCallback, useEffect, useRef, useState } from 'react';

interface UseIdleSessionTimeoutOptions {
  isActive: boolean;
  timeoutMs: number;
  minTimeoutMs?: number;
  onTimeout: () => Promise<void> | void;
}

const DEFAULT_ACTIVITY_EVENTS: Array<keyof WindowEventMap> = [
  'mousemove',
  'keydown',
  'click',
  'scroll',
  'touchstart',
];

/**
 * Tracks browser activity and triggers the provided callback after the user has been idle
 * for the configured timeout while authenticated. Designed for AuthContext but kept generic
 * so we can cover the logic with unit tests.
 */
export function useIdleSessionTimeout({
  isActive,
  timeoutMs,
  minTimeoutMs = 5_000,
  onTimeout,
}: UseIdleSessionTimeoutOptions) {
  const [lastActivity, setLastActivity] = useState(() => Date.now());
  const timeoutIdRef = useRef<number | null>(null);
  const isActiveRef = useRef(isActive);

  const clearTimer = useCallback(() => {
    if (timeoutIdRef.current !== null) {
      window.clearTimeout(timeoutIdRef.current);
      timeoutIdRef.current = null;
    }
  }, []);

  const markActivity = useCallback(() => {
    if (!isActiveRef.current) return;
    setLastActivity(Date.now());
  }, []);

  useEffect(() => {
    const events = DEFAULT_ACTIVITY_EVENTS;
    events.forEach((event) => window.addEventListener(event, markActivity, { passive: true }));
    return () => {
      events.forEach((event) => window.removeEventListener(event, markActivity));
    };
  }, [markActivity]);

  useEffect(() => {
    const becameActive = isActive && !isActiveRef.current;
    isActiveRef.current = isActive;

    if (becameActive) {
      setLastActivity(Date.now());
    }

    if (!isActive) {
      clearTimer();
    }
  }, [isActive, clearTimer]);

  useEffect(() => {
    clearTimer();

    if (!isActive) {
      return;
    }

    const now = Date.now();
    const elapsed = now - lastActivity;
    const remaining = timeoutMs - elapsed;
    const delay = remaining > minTimeoutMs ? remaining : minTimeoutMs;

    timeoutIdRef.current = window.setTimeout(async () => {
      if (!isActiveRef.current) return;
      try {
        await onTimeout();
      } catch (error) {
        // Surface errors for easier debugging but do not break the app
        console.error('useIdleSessionTimeout onTimeout handler failed', error);
      }
    }, delay);

    return () => {
      clearTimer();
    };
  }, [isActive, lastActivity, timeoutMs, minTimeoutMs, onTimeout, clearTimer]);
}
