import React, { useMemo, useState } from 'react';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { useSchedulingQuery } from '../../hooks/queries/useSchedulingQuery';

export function SchedulingBoardPage() {
  const [fechaFiltro, setFechaFiltro] = useState('');
  const { data, isLoading, error } = useSchedulingQuery(fechaFiltro || undefined);

  const totalBloques = data?.length ?? 0;
  const totalDocentes = useMemo(() => new Set((data ?? []).map((item) => item.rut_docente)).size, [data]);

  return (
    <div className="p-4 md:p-6 space-y-4">
      <Card>
        <CardHeader>
          <div>
            <h1 className="text-xl font-semibold text-gray-900 dark:text-white">SchedulingBoard</h1>
            <p className="text-sm text-gray-600 dark:text-gray-300">Bloques planificados y control de colisiones.</p>
          </div>
          <input
            type="date"
            value={fechaFiltro}
            onChange={(event) => setFechaFiltro(event.target.value)}
            className="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-bg px-3 py-2 text-sm"
          />
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 md:grid-cols-2 mb-4">
            <div className="rounded-lg border border-gray-100 dark:border-gray-800 p-3">
              <div className="text-xs uppercase tracking-wide text-gray-500">Bloques</div>
              <div className="text-2xl font-semibold">{totalBloques}</div>
            </div>
            <div className="rounded-lg border border-gray-100 dark:border-gray-800 p-3">
              <div className="text-xs uppercase tracking-wide text-gray-500">Docentes</div>
              <div className="text-2xl font-semibold">{totalDocentes}</div>
            </div>
          </div>

          {isLoading && <div className="text-sm text-gray-500">Cargando horarios...</div>}
          {error && <div className="text-sm text-red-600">No se pudo cargar horarios: {String(error.message || error)}</div>}

          {!isLoading && !error && (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead>
                  <tr className="text-left border-b border-gray-200 dark:border-gray-700">
                    <th className="py-2 pr-4">Fecha</th>
                    <th className="py-2 pr-4">RUT Docente</th>
                    <th className="py-2 pr-4">Inicio</th>
                    <th className="py-2 pr-4">Fin</th>
                    <th className="py-2 pr-4">Sala</th>
                    <th className="py-2 pr-4">Curso</th>
                    <th className="py-2 pr-4">Asignatura</th>
                  </tr>
                </thead>
                <tbody>
                  {(data ?? []).map((row) => (
                    <tr key={row.id} className="border-b border-gray-100 dark:border-gray-800">
                      <td className="py-2 pr-4">{row.bloque_fecha}</td>
                      <td className="py-2 pr-4">{row.rut_docente}</td>
                      <td className="py-2 pr-4">{row.hora_inicio}</td>
                      <td className="py-2 pr-4">{row.hora_fin}</td>
                      <td className="py-2 pr-4">{row.sala?.codigo || '-'}</td>
                      <td className="py-2 pr-4">{row.curso?.nom_curso || '-'}</td>
                      <td className="py-2 pr-4">{row.asignatura || '-'}</td>
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
