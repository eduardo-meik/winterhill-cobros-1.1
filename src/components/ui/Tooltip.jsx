import React, { useState } from 'react';

export function Tooltip({ children, content, position = 'top' }) {
  const [isVisible, setIsVisible] = useState(false);

  const positionClasses = {
    top: 'bottom-full mb-2',
    bottom: 'top-full mt-2',
    left: 'right-full mr-2',
    right: 'left-full ml-2'
  };

  return (
    <div className="relative inline-block">
      <div
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
      >
        {children}
      </div>
      {isVisible && (
        <div
          className={`absolute z-50 px-2 py-1 text-xs text-white bg-gray-900 dark:bg-gray-700 rounded pointer-events-none whitespace-nowrap ${positionClasses[position]}`}
          style={{ transform: 'translateX(-50%)', left: '50%' }}
        >
          {content}
          <div
            className={`absolute w-2 h-2 bg-gray-900 dark:bg-gray-700 transform rotate-45 ${
              position === 'top' ? 'top-full -mt-1' : 'bottom-full -mb-1'
            }`}
            style={{ left: '50%', marginLeft: '-4px' }}
          />
        </div>
      )}
    </div>
  );
}