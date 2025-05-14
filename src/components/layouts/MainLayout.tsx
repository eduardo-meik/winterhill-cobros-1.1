import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '../ui/Header';
import Sidebar from '../Sidebar';
import { MobileMenu } from '../ui/MobileMenu';
import { useNavigate } from 'react-router-dom';

export function MainLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [currentPage, setCurrentPage] = useState('dashboard');
  const navigate = useNavigate();

  const handleMenuItemClick = (page: string) => {
    setCurrentPage(page);
    setIsSidebarOpen(false);
    navigate(`/${page}`);
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-dark-bg dark:text-gray-100 transition-colors duration-200 flex flex-col">
      <Header 
        onMenuClick={() => setIsSidebarOpen(true)} 
        onNavigate={handleMenuItemClick}
      />
      <div className="flex-1 flex overflow-hidden">
        <div className="max-w-[1440px] w-full mx-auto flex">
          <Sidebar 
            isOpen={isSidebarOpen} 
            onClose={() => setIsSidebarOpen(false)}
            currentPage={currentPage}
            onMenuItemClick={handleMenuItemClick}
            isCollapsed={isSidebarCollapsed}
            onToggleCollapse={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
          />
          <Outlet />
        </div>
      </div>
      <MobileMenu 
        isOpen={isSidebarOpen} 
        onClose={() => setIsSidebarOpen(false)}
        currentPage={currentPage}
        onNavigate={handleMenuItemClick}
      />
    </div>
  );
}