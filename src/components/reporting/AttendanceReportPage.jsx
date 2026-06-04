import React, { useState } from 'react';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { useAttendanceConciliacionQuery } from '../../hooks/queries/useAttendanceConciliacionQuery';

function statusClass(estado) {
  switch (estado) {
    case 'cumplimiento':
      return 'text-green-700 bg-green-100 dark:text-green-300 dark:bg-green-900/30';
    case 'atraso':
    case 'salida_anticipada':
      return 'text-red-700 bg-red-100 dark:text-red-300 dark:bg-red-900/30';
    default:
      return 'text-amber-700 bg-amber-100 dark:text-amber-300 dark:bg-amber-900/30';
  }
}

export function AttendanceReportPage() {
  const [fechaFiltro, setFechaFiltro] = useState('');
  const { data, isLoading, error } = useAttendanceConciliacionQuery(fechaFiltro || undefined);

  return (
    <div className="p-4 md:p-6 space-y-4">
      <Card>
        <CardHeader>
          <div>
            <h1 className="text-xl font-semibold text-gray-900 dark:text-white">AttendanceReport</h1>
            <p className="text-sm text-gray-600 dark:text-gray-300">Cruce de horas efectivas vs planificadas por docente.</p>
          </div>
          <input
            type="date"
            value={fechaFiltro}
            onChange={(event) => setFechaFiltro(event.target.value)}
            className="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-bg px-3 py-2 text-sm"
          />
        </CardHeader>
        <CardContent>
          {isLoading && <div className="text-sm text-gray-500">Cargando conciliaciones...</div>}
          {error && <div className="text-sm text-red-600">No se pudo cargar conciliaciones: {String(error.message || error)}</div>}

          {!isLoading && !error && (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead>
                  <tr className="text-left border-b border-gray-200 dark:border-gray-700">
                    <th className="py-2 pr-4">Fecha</th>
                    <th className="py-2 pr-4">RUT Docente</th>
                    <th className="py-2 pr-4">Estado</th>
                    <th className="py-2 pr-4">Planificado (min)</th>
                    <th className="py-2 pr-4">Efectivo (min)</th>
                    <th className="py-2 pr-4">Atraso</th>
                    <th className="py-2 pr-4">Salida anticipada</th>
                  </tr>
                </thead>
                <tbody>
                  {(data ?? []).map((row) => (
                    <tr key={row.id} className="border-b border-gray-100 dark:border-gray-800">
                      <td className="py-2 pr-4">{row.fecha}</td>
                      <td className="py-2 pr-4">{row.rut_docente}</td>
                      <td className="py-2 pr-4">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusClass(row.estado)}`}>
                          {row.estado}
                        </span>
                      </td>
                      <td className="py-2 pr-4">{row.minutos_planificados}</td>
                      <td className="py-2 pr-4">{row.minutos_efectivos}</td>
                      <td className="py-2 pr-4">{row.minutos_atraso}</td>
                      <td className="py-2 pr-4">{row.minutos_salida_anticipada}</td>
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
