import { useCallback, useEffect, useRef, useState } from 'react';

interface UseIdleSessionTimeoutOptions {
  enabled?: boolean;
  isActive: boolean;
  timeoutMs: number;
  minTimeoutMs?: number;
  onTimeout: () => Promise<void> | void;
  /** share activity across tabs via storage events */
  syncTabs?: boolean;
  /** storage key used when syncing activity */
  storageKey?: string;
  /** avoid counting down while the tab/document is hidden */
  pauseWhenHidden?: boolean;
}

const DEFAULT_ACTIVITY_EVENTS: Array<keyof WindowEventMap> = [
  'mousemove',
  'keydown',
  'click',
  'scroll',
  'touchstart',
];

const DEFAULT_STORAGE_KEY = 'wh_idle_last_activity';

const now = () => Date.now();

const createTabId = () => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `tab-${now()}-${Math.random().toString(36).slice(2)}`;
};

/**
 * Tracks browser activity and triggers the provided callback after the user has been idle
 * for the configured timeout while authenticated. Designed for AuthContext but kept generic
 * so we can cover the logic with unit tests.
 */
export function useIdleSessionTimeout({
  enabled = true,
  isActive,
  timeoutMs,
  minTimeoutMs = 5_000,
  onTimeout,
  syncTabs = true,
  storageKey = DEFAULT_STORAGE_KEY,
  pauseWhenHidden = true,
}: UseIdleSessionTimeoutOptions) {
  const [lastActivity, setLastActivity] = useState(() => now());
  const timeoutIdRef = useRef<number | null>(null);
  const isActiveRef = useRef(enabled && isActive);
  const lastSharedRef = useRef(0);
  const tabIdRef = useRef(createTabId());
  const [documentVisible, setDocumentVisible] = useState(() => {
    if (typeof document === 'undefined') return true;
    return !document.hidden;
  });
  const documentVisibleRef = useRef(documentVisible);

  const clearTimer = useCallback(() => {
    if (timeoutIdRef.current !== null) {
      window.clearTimeout(timeoutIdRef.current);
      timeoutIdRef.current = null;
    }
  }, []);

  const markActivity = useCallback(() => {
    if (!enabled || !isActiveRef.current) return;
    const timestamp = now();
    setLastActivity(timestamp);
    if (!syncTabs) return;
    if (typeof window === 'undefined' || !window.localStorage) return;
    if (timestamp - lastSharedRef.current < 1_000) return;
    lastSharedRef.current = timestamp;
    try {
      window.localStorage.setItem(
        storageKey,
        JSON.stringify({ timestamp, tabId: tabIdRef.current })
      );
    } catch {
      /* ignore quota errors */
    }
  }, [enabled, storageKey, syncTabs]);

  useEffect(() => {
    if (!enabled) return;
    if (typeof window === 'undefined') return;
    const events = DEFAULT_ACTIVITY_EVENTS;
    events.forEach((event) => window.addEventListener(event, markActivity, { passive: true }));
    return () => {
      events.forEach((event) => window.removeEventListener(event, markActivity));
    };
  }, [enabled, markActivity]);

  useEffect(() => {
    if (!enabled || !syncTabs) return;
    if (typeof window === 'undefined') return;
    const handleStorage = (event: StorageEvent) => {
      if (event.key !== storageKey || !event.newValue) return;
      try {
        const payload = JSON.parse(event.newValue);
        if (!payload || payload.tabId === tabIdRef.current) return;
        if (typeof payload.timestamp === 'number') {
          setLastActivity((prev) => (payload.timestamp > prev ? payload.timestamp : prev));
        }
      } catch {
        /* ignore malformed payload */
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, [enabled, storageKey, syncTabs]);

  useEffect(() => {
    if (!enabled || !pauseWhenHidden) return;
    if (typeof document === 'undefined') return;
    const handleVisibility = () => {
      const visible = !document.hidden;
      documentVisibleRef.current = visible;
      setDocumentVisible(visible);
      if (visible && isActiveRef.current) {
        markActivity();
      } else if (!visible) {
        clearTimer();
      }
    };
    document.addEventListener('visibilitychange', handleVisibility);
    return () => document.removeEventListener('visibilitychange', handleVisibility);
  }, [enabled, pauseWhenHidden, markActivity, clearTimer]);

  useEffect(() => {
    const nextActiveState = enabled && isActive;
    const becameActive = nextActiveState && !isActiveRef.current;
    isActiveRef.current = nextActiveState;

    if (becameActive) {
      markActivity();
    }

    if (!nextActiveState) {
      clearTimer();
    }
  }, [enabled, isActive, clearTimer, markActivity]);

  useEffect(() => {
    if (!enabled || !isActive || (pauseWhenHidden && !documentVisible)) {
      clearTimer();
      return;
    }

    clearTimer();

    const currentTime = now();
    const elapsed = currentTime - lastActivity;
    const remaining = timeoutMs - elapsed;
    const delay = remaining > minTimeoutMs ? remaining : minTimeoutMs;

    timeoutIdRef.current = window.setTimeout(async () => {
      if (!isActiveRef.current) return;
      if (pauseWhenHidden && !documentVisibleRef.current) return;
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
  }, [enabled, isActive, documentVisible, pauseWhenHidden, lastActivity, timeoutMs, minTimeoutMs, onTimeout, clearTimer]);
}
