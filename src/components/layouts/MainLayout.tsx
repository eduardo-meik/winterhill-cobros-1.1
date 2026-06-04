import { useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '../ui/Header';
import Sidebar from '../Sidebar';
import { MobileMenu } from '../ui/MobileMenu';
import { Breadcrumbs } from '../ui/Breadcrumbs';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';
import { isGuardianRole } from '../../constants/roles';

export function MainLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [currentPage, setCurrentPage] = useState('dashboard');
  const navigate = useNavigate();
  const { user } = useAuth();
  const { checking } = useGuardianIntakeGate();
  const guardianUser = isGuardianRole(user?.role);

  const restrictedForGuardian = new Set(['students','guardians','reporting','assistant']);

  useEffect(() => {
    if (guardianUser && restrictedForGuardian.has(currentPage)) {
      navigate('/apoderado/bienvenido', { replace: true });
      setCurrentPage('dashboard');
    }
  }, [guardianUser, currentPage, navigate]);

  const handleMenuItemClick = (page: string) => {
    if (guardianUser) {
      if (restrictedForGuardian.has(page)) {
        page = 'dashboard';
      }
      if (page === 'dashboard') {
        setCurrentPage('dashboard');
        setIsSidebarOpen(false);
        navigate('/apoderado/bienvenido');
        return;
      }
      if (page === 'payments') {
        setCurrentPage('payments');
        setIsSidebarOpen(false);
        navigate('/apoderado/portal');
        return;
      }
      if (page === 'matricula') {
        setCurrentPage('matricula');
        setIsSidebarOpen(false);
        navigate('/matricula');
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
            <div className="flex-1 flex flex-col overflow-auto">
              <Breadcrumbs />
              <Outlet />
            </div>
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