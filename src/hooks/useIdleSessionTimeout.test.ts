import { renderHook } from '@testing-library/react';
import { useIdleSessionTimeout } from './useIdleSessionTimeout';

describe('useIdleSessionTimeout', () => {
  const TIMEOUT = 30 * 60 * 1000; // 30 min

  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2024-01-01T00:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('does not immediately log out when a new session starts after long inactivity', () => {
    const onTimeout = jest.fn();
    const { rerender, unmount } = renderHook((props) => useIdleSessionTimeout(props), {
      initialProps: {
        isActive: false,
        timeoutMs: TIMEOUT,
        minTimeoutMs: 5_000,
        onTimeout,
      },
    });

    // Simulate more than 30 minutes passing before the user authenticates
    jest.advanceTimersByTime(TIMEOUT + 60_000);

    rerender({
      isActive: true,
      timeoutMs: TIMEOUT,
      minTimeoutMs: 5_000,
      onTimeout,
    });

    // Wait 10 seconds – previously this would trigger the forced sign out
    jest.advanceTimersByTime(10_000);

    expect(onTimeout).not.toHaveBeenCalled();

    unmount();
  });

  it('logs out after the configured idle window when the session stays active', () => {
    const onTimeout = jest.fn();
    const { rerender, unmount } = renderHook((props) => useIdleSessionTimeout(props), {
      initialProps: {
        isActive: true,
        timeoutMs: TIMEOUT,
        minTimeoutMs: 5_000,
        onTimeout,
      },
    });

    jest.advanceTimersByTime(TIMEOUT + 100);
    expect(onTimeout).toHaveBeenCalledTimes(1);

    onTimeout.mockClear();

    // Once session is inactive we should not schedule more timers
    rerender({
      isActive: false,
      timeoutMs: TIMEOUT,
      minTimeoutMs: 5_000,
      onTimeout,
    });

    jest.advanceTimersByTime(TIMEOUT);
    expect(onTimeout).not.toHaveBeenCalled();

    unmount();
  });
});
