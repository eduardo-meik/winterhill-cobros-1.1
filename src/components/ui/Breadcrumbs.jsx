import { Link, useLocation } from 'react-router-dom';
import { ChevronRightIcon, HomeIcon } from '@heroicons/react/20/solid';

const routeLabels = {
  dashboard: 'Dashboard',
  students: 'Estudiantes',
  guardians: 'Apoderados',
  payments: 'Pagos',
  reporting: 'Reportes',
  assistant: 'Asistente',
  profile: 'Perfil',
  settings: 'Configuración',
  matricula: 'Matrícula',
  promocion: 'Promoción',
  repactacion: 'Repactación',
  apoderado: 'Portal Apoderado',
  bienvenido: 'Bienvenido',
  portal: 'Portal',
  encuesta: 'Encuesta',
};

export function Breadcrumbs() {
  const location = useLocation();
  const segments = location.pathname.split('/').filter(Boolean);

  if (segments.length === 0) return null;

  const crumbs = segments.map((seg, i) => ({
    label: routeLabels[seg] || seg,
    path: '/' + segments.slice(0, i + 1).join('/'),
    isLast: i === segments.length - 1,
  }));

  return (
    <nav aria-label="Breadcrumb" className="px-4 py-2 text-sm">
      <ol className="flex items-center gap-1 text-gray-500 dark:text-gray-400">
        <li>
          <Link to="/dashboard" className="hover:text-gray-700 dark:hover:text-gray-200">
            <HomeIcon className="h-4 w-4" />
          </Link>
        </li>
        {crumbs.map((crumb) => (
          <li key={crumb.path} className="flex items-center gap-1">
            <ChevronRightIcon className="h-4 w-4 text-gray-400" />
            {crumb.isLast ? (
              <span className="text-gray-700 dark:text-gray-200 font-medium">{crumb.label}</span>
            ) : (
              <Link to={crumb.path} className="hover:text-gray-700 dark:hover:text-gray-200">
                {crumb.label}
              </Link>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}
