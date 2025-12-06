import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { Button } from '../ui/Button';
import { listAllRecentEnrollments } from '../../services/matricula';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { getStatusLabel } from '../../constants/statusLabels';

export function GlobalEnrollmentsTable({ onSelectEnrollment }) {
  const [enrollments, setEnrollments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadEnrollments();
  }, []);

  const loadEnrollments = async () => {
    setLoading(true);
    const data = await listAllRecentEnrollments();
    setEnrollments(data);
    setLoading(false);
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'completed':
      case 'matriculado':
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">Matriculado</span>;
      case 'pre_matriculado':
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">Pre Matrícula</span>;
      case 'pending':
      case 'in_progress':
      case 'draft':
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 border border-yellow-200">Borrador</span>;
      default:
        return (
          <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">
            {getStatusLabel(status)}
          </span>
        );
    }
  };

  if (loading) {
    return (
      <Card className="mt-6">
        <CardContent className="p-6 text-center text-gray-500">
          Cargando historial reciente...
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="mt-6">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Actividad Reciente (Últimos 6 meses)</h3>
            <p className="text-sm text-gray-500">Monitor de procesos de matrícula en curso y completados.</p>
          </div>
          <Button variant="outline" size="sm" onClick={loadEnrollments}>
            ↻ Actualizar
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead className="bg-gray-50 dark:bg-dark-hover text-gray-600 dark:text-gray-300 font-medium border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th className="px-4 py-3">Fecha</th>
                <th className="px-4 py-3">Apoderado</th>
                <th className="px-4 py-3">Estudiantes</th>
                <th className="px-4 py-3">Estado</th>
                <th className="px-4 py-3 text-right">Acción</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {enrollments.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-4 py-8 text-center text-gray-500">
                    No hay movimientos recientes.
                  </td>
                </tr>
              ) : (
                enrollments.map((enr) => (
                  <tr key={enr.id} className="hover:bg-gray-50 dark:hover:bg-dark-hover/50 transition-colors">
                    <td className="px-4 py-3 whitespace-nowrap text-gray-600 dark:text-gray-400">
                      {format(new Date(enr.created_at), 'dd/MM/yyyy HH:mm', { locale: es })}
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900 dark:text-white">
                        {enr.guardians?.first_name} {enr.guardians?.last_name}
                      </div>
                      <div className="text-xs text-gray-500">{enr.guardians?.run}</div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        {enr.enrollment_students?.length > 0 ? (
                          enr.enrollment_students.map((es, idx) => (
                            <span key={idx} className="text-xs bg-blue-50 text-blue-700 px-1.5 py-0.5 rounded w-fit">
                              {es.students?.whole_name}
                            </span>
                          ))
                        ) : (
                          <span className="text-xs text-gray-400 italic">Sin estudiantes</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      {getStatusBadge(enr.status)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Button 
                        size="xs" 
                        variant="secondary"
                        onClick={() => onSelectEnrollment(enr, enr.guardians)}
                      >
                        Gestionar
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}
