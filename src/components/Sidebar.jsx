import React, { useEffect } from 'react';
import { House, UsersThree, ChatDots, Money, ChartPie, Guardian } from './Icons';
import clsx from 'clsx';

/**
 * Navigation menu items configuration
 * Each item defines an id, icon component, and display text
 */
const menuItems = [
  { id: 'dashboard', icon: House, text: 'Inicio' },
  { id: 'students', icon: UsersThree, text: 'Estudiantes' },
  { id: 'guardians', icon: Guardian, text: 'Apoderados' }, // Changed from UsersThree to Bell
  { id: 'payments', icon: Money, text: 'Aranceles' }, // Changed from Megaphone to ShoppingCart
  { id: 'reporting', icon: ChartPie, text: 'Reportes' },
  { id: 'assistant', icon: ChatDots, text: 'Asistente' }
];

/**
 * Sidebar component that contains navigation menu
 * Handles both desktop and mobile layouts
 */
export default function Sidebar({ isOpen, onClose, currentPage, onMenuItemClick, isCollapsed, onToggleCollapse }) {
  // Handle escape key to close mobile sidebar
  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  return (
    <aside className={clsx(
      'fixed inset-y-0 left-0 z-40 bg-white dark:bg-dark-card border-r border-gray-100 dark:border-gray-800 lg:static transform transition-all duration-300 ease-in-out flex-shrink-0',
      isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
      isCollapsed ? 'w-20' : 'w-80'
    )}>
      <div className="flex h-full flex-col min-h-[calc(100vh-4rem)] overflow-hidden">
        {/* Mobile header */}
        <div className={clsx(
          "flex items-center p-4 flex-shrink-0",
          isCollapsed ? "justify-center" : "justify-between",
          "lg:border-b lg:border-gray-100 lg:dark:border-gray-800"
        )}>
          {!isCollapsed && (
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Menu</h2>
          )}
          <button
            onClick={onToggleCollapse}
            className="hidden lg:block p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-dark-hover rounded-lg transition-colors"
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              width="20" 
              height="20" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
              className={clsx("transform transition-transform", isCollapsed ? "rotate-180" : "")}
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
            </svg>
          </button>
          <button
            onClick={onClose}
            className="lg:hidden p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-dark-hover rounded-lg transition-colors"
            aria-label="Close sidebar"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        <div className="flex-1 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-200 dark:scrollbar-thumb-gray-700 scrollbar-track-transparent">
          {/* Navigation menu */}
          <nav className={clsx(
            "flex flex-col gap-1 flex-shrink-0",
            isCollapsed ? "p-2" : "p-4"
          )}>
            {menuItems.map((item) => (
              <button
                key={item.id}
                onClick={() => onMenuItemClick(item.id)}
                className={clsx(
                  'flex items-center gap-3 px-3 py-2 rounded-xl transition-all duration-200 relative group',
                  currentPage === item.id
                    ? 'bg-primary bg-opacity-15 text-primary dark:bg-opacity-20'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-dark-hover'
                )}
                aria-label={item.text}
              >
                <item.icon />
                {!isCollapsed && <span className="text-sm font-medium">{item.text}</span>}
                {isCollapsed && (
                  <div className="absolute left-full ml-2 px-2 py-1 bg-gray-900 dark:bg-gray-700 text-white text-sm rounded opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 whitespace-nowrap z-50">
                    {item.text}
                  </div>
                )}
              </button>
            ))}
          </nav>
        </div>
      </div>
    </aside>
  );
}