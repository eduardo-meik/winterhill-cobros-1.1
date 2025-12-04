import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { Button } from '../ui/Button';
import { listGuardianEnrollments } from '../../services/matricula';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

export function EnrollmentDashboard({ guardian, onContinue, onNewEnrollment }) {
  const [enrollments, setEnrollments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (guardian?.id) {
      loadEnrollments();
    }
  }, [guardian]);

  const loadEnrollments = async () => {
    setLoading(true);
    const data = await listGuardianEnrollments(guardian.id);
    setEnrollments(data);
    setLoading(false);
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'completed':
      case 'matriculado':
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">Matriculado</span>;
      case 'pending':
      case 'in_progress':
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 border border-yellow-200">Borrador</span>;
      default:
        return <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">{status}</span>;
    }
  };

  const getStudentsList = (enrollment) => {
    if (!enrollment.enrollment_students || enrollment.enrollment_students.length === 0) {
      return <span className="text-gray-400 italic">Sin estudiantes</span>;
    }
    return (
      <div className="flex flex-col gap-1">
        {enrollment.enrollment_students.map((es, idx) => (
          <div key={idx} className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center text-xs font-bold">
              {es.students?.whole_name?.charAt(0) || '?'}
            </div>
            <span className="text-sm">{es.students?.whole_name || 'Estudiante desconocido'}</span>
          </div>
        ))}
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-8 text-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
        <p className="text-gray-500">Cargando sus matrículas...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Welcome Header */}
      <div className="bg-white dark:bg-dark-card rounded-lg p-6 shadow-sm border border-gray-100 dark:border-gray-800">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
          Hola, {guardian.first_name} 👋
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Bienvenido al portal de matrículas. Aquí puedes gestionar los procesos de matrícula de tus estudiantes.
        </p>
      </div>

      {/* Enrollments List */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div>
              <h2 className="text-lg font-semibold">Mis Matrículas</h2>
              <p className="text-xs text-gray-500">Historial de procesos de matrícula</p>
            </div>
            <Button onClick={onNewEnrollment}>
              + Iniciar Nueva Matrícula
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {enrollments.length === 0 ? (
            <div className="text-center py-12 bg-gray-50 dark:bg-dark/50 rounded-lg border border-dashed border-gray-300 dark:border-gray-700">
              <p className="text-gray-500 mb-4">No tienes procesos de matrícula registrados.</p>
              <Button variant="outline" onClick={onNewEnrollment}>Comenzar ahora</Button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-gray-700 text-xs uppercase text-gray-500 font-semibold bg-gray-50 dark:bg-dark/50">
                    <th className="p-4">Año</th>
                    <th className="p-4">Estudiantes</th>
                    <th className="p-4">Estado</th>
                    <th className="p-4">Última Modificación</th>
                    <th className="p-4 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {enrollments.map((enrollment) => (
                    <tr key={enrollment.id} className="hover:bg-gray-50 dark:hover:bg-dark/30 transition-colors">
                      <td className="p-4 font-medium text-gray-900 dark:text-white">
                        {enrollment.year}
                      </td>
                      <td className="p-4">
                        {getStudentsList(enrollment)}
                      </td>
                      <td className="p-4">
                        {getStatusBadge(enrollment.status)}
                      </td>
                      <td className="p-4 text-sm text-gray-500">
                        {enrollment.updated_at ? format(new Date(enrollment.updated_at), "d MMM yyyy, HH:mm", { locale: es }) : '-'}
                      </td>
                      <td className="p-4 text-right">
                        {enrollment.status === 'completed' || enrollment.status === 'matriculado' ? (
                          <Button 
                            size="sm" 
                            variant="outline" 
                            onClick={() => onContinue(enrollment)}
                          >
                            Ver Detalles
                          </Button>
                        ) : (
                          <Button 
                            size="sm" 
                            onClick={() => onContinue(enrollment)}
                          >
                            Continuar ➝
                          </Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
