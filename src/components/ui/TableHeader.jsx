import React from 'react';

export function TableHeader({ children, className = '' }) {
  return (
    <thead className={`sticky top-0 bg-white dark:bg-dark-card z-10 ${className}`}>
      {children}
    </thead>
  );
}