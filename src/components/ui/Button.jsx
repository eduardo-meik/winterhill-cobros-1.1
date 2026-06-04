import React from 'react';
import clsx from 'clsx';

export function Button({ className, children, variant = 'primary', size = 'default', ...props }) {
  return (
    <button
      className={clsx(
        'inline-flex items-center justify-center rounded-xl font-medium transition-colors duration-200',
        {
          'bg-primary hover:bg-primary-light text-white': variant === 'primary',
          'bg-gray-100 hover:bg-gray-200 text-gray-900 dark:bg-gray-700 dark:text-gray-100': variant === 'secondary',
          'border border-gray-300 bg-transparent hover:bg-gray-50 text-gray-700 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-800': variant === 'outline',
          'bg-red-600 hover:bg-red-700 text-white': variant === 'destructive',
          'bg-transparent hover:bg-gray-100 text-gray-700 dark:text-gray-200 dark:hover:bg-gray-800': variant === 'ghost',
        },
        {
          'px-4 h-10 text-sm': size === 'default',
          'px-3 h-8 text-sm': size === 'sm',
          'px-2.5 h-7 text-xs': size === 'xs',
        },
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
}