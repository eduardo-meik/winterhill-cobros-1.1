import React from 'react';
import clsx from 'clsx';

export function TabsContainer({ children }) {
  return (
    <div className="flex border-b border-gray-200 dark:border-gray-800">
      {children}
    </div>
  );
}

export function TabButton({ children, isActive, onClick }) {
  return (
    <button
      className={clsx(
        'px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
        isActive 
          ? 'border-primary text-primary dark:border-primary dark:text-primary' 
          : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
      )}
      onClick={onClick}
    >
      {children}
    </button>
  );
}