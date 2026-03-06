import React from 'react';
import clsx from 'clsx';

/**
 * Base skeleton pulse element.
 * @param {'text'|'circle'|'rect'} variant
 * @param {string} className  — override w/h via Tailwind classes
 */
export function Skeleton({ variant = 'text', className }) {
  const base = 'animate-pulse bg-gray-200 dark:bg-gray-700 rounded';
  const variants = {
    text: 'h-4 w-full rounded',
    circle: 'rounded-full h-10 w-10',
    rect: 'h-24 w-full rounded-lg',
  };
  return <div className={clsx(base, variants[variant], className)} />;
}

/** Skeleton matching StatCard layout — icon box + 2 text lines. */
export function StatCardSkeleton() {
  return (
    <div className="bg-white dark:bg-dark-card rounded-xl border border-gray-200 dark:border-gray-700 p-6 flex items-start gap-4">
      <Skeleton variant="rect" className="h-12 w-12 rounded-lg shrink-0" />
      <div className="flex-1 space-y-2">
        <Skeleton className="h-3 w-24" />
        <Skeleton className="h-7 w-32" />
      </div>
    </div>
  );
}

/**
 * Skeleton matching a chart card — title bar + placeholder area.
 * @param {string} title — optional visible title while loading
 * @param {string} className
 */
export function ChartSkeleton({ title, className }) {
  return (
    <div className={clsx('bg-white dark:bg-dark-card rounded-xl border border-gray-200 dark:border-gray-700', className)}>
      <div className="px-6 py-4 border-b border-gray-100 dark:border-gray-700">
        {title ? (
          <h2 className="text-gray-900 dark:text-white text-lg font-semibold">{title}</h2>
        ) : (
          <Skeleton className="h-5 w-40" />
        )}
      </div>
      <div className="p-6">
        <div className="h-[300px] flex flex-col justify-end gap-2">
          <div className="flex items-end gap-3 h-full">
            {[65, 45, 80, 55, 70, 40, 90, 60, 75, 50, 85, 55].map((h, i) => (
              <Skeleton key={i} variant="rect" className="flex-1 rounded-t-md rounded-b-none" style={{ height: `${h}%` }} />
            ))}
          </div>
          <Skeleton className="h-px w-full" />
        </div>
      </div>
    </div>
  );
}

/**
 * Skeleton for table rows.
 * @param {number} rows — number of skeleton rows (default 5)
 * @param {number} cols — columns per row (default 4)
 */
export function TableSkeleton({ rows = 5, cols = 4 }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="flex items-center gap-4 p-4 rounded-lg bg-gray-50 dark:bg-dark-hover">
          {Array.from({ length: cols }).map((_, c) => (
            <Skeleton
              key={c}
              className={clsx('h-4', c === 0 ? 'w-1/3' : 'w-1/5')}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
