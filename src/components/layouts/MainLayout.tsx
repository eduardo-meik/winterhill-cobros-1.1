import { useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '../ui/Header';
import Sidebar from '../Sidebar';
import { MobileMenu } from '../ui/MobileMenu';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';

export function MainLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [currentPage, setCurrentPage] = useState('dashboard');
  const navigate = useNavigate();
  const { user } = useAuth();
  const { checking } = useGuardianIntakeGate();

  const restrictedForGuardian = new Set(['students','guardians','reporting','assistant']);

  useEffect(() => {
  if (user?.role && user.role.toLowerCase() === 'guardian' && restrictedForGuardian.has(currentPage)) {
      navigate('/apoderado/bienvenido', { replace: true });
      setCurrentPage('dashboard');
    }
  }, [user?.role, currentPage, navigate]);

  const handleMenuItemClick = (page: string) => {
  if (user?.role && user.role.toLowerCase() === 'guardian') {
      if (restrictedForGuardian.has(page)) {
        page = 'dashboard';
      }
      // Force dashboard menu to guardian welcome page
      if (page === 'dashboard') {
        setCurrentPage('dashboard');
        setIsSidebarOpen(false);
        navigate('/apoderado/bienvenido');
        return;
      }
    }
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
          {checking ? (
            <div className="flex-1 flex items-center justify-center">
              <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary"></div>
            </div>
          ) : (
            <Outlet />
          )}
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