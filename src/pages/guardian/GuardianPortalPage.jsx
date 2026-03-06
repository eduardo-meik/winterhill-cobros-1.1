import React, { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { useGuardianData } from '../../contexts/GuardianContext';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';

function formatCurrency(value) {
  try {
    return new Intl.NumberFormat('es-CL', { style: 'currency', currency: 'CLP', maximumFractionDigits: 0 }).format(
      Number(value || 0)
    );
  } catch {
    return `$${value}`;
  }
}

function downloadCSV(filename, rows) {
  if (!rows || rows.length === 0) return;
  const headers = Object.keys(rows[0]);
  const escape = (v) => (typeof v === 'string' && (v.includes(';') || v.includes('"') || v.includes('\n'))
    ? '"' + v.replace(/"/g, '""') + '"'
    : v);
  const csv = [headers.join(';')]
    .concat(rows.map(r => headers.map(h => escape(r[h] ?? '')).join(';')))
    .join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

export default function GuardianPortalPage() {
  const { user } = useAuth();
  const { data, loading, refreshing, refresh, error } = useGuardianData();
  const { checking } = useGuardianIntakeGate();
  const [selectedStudent, setSelectedStudent] = useState('all');
  const [status, setStatus] = useState('all');
  const currentYear = new Date().getFullYear();
  const availableYears = useMemo(() => {
    const years = new Set();
    (data?.fees || []).forEach((fee) => {
      if (fee.year) years.add(fee.year);
      else if (fee.year_academico) years.add(fee.year_academico);
    });
    if (years.size === 0) {
      years.add(currentYear);
    }
    return Array.from(years).sort((a, b) => Number(b) - Number(a));
  }, [data?.fees, currentYear]);
  const [year, setYear] = useState(() => availableYears[0] || currentYear);

  useEffect(() => {
    if (!availableYears.includes(year)) {
      setYear(availableYears[0] || currentYear);
    }
  }, [availableYears, year, currentYear]);

  const guardian = data?.guardian;
  const students = data?.students || [];
  const fees = data?.fees || [];
  const enrollment = data?.enrollment;
  const enrollmentStudentIds = data?.enrollmentStudentIds || [];
  const enrollmentDocs = data?.enrollmentDocuments || [];

  const filteredFees = useMemo(() => {
    let rows = fees.filter((fee) => {
      const feeYear = fee.year ?? fee.year_academico ?? year;
      return Number(feeYear) === Number(year);
    });
    if (selectedStudent !== 'all') {
      rows = rows.filter((fee) => fee.student_id === selectedStudent);
    }
    if (status !== 'all') {
      rows = rows.filter((fee) => String(fee.status || '').toLowerCase() === status);
    }
    return rows;
  }, [fees, status, selectedStudent, year]);

  const totals = useMemo(() => {
    const total = filteredFees.reduce((acc, f) => acc + Number(f.amount || 0), 0);
    const byStatus = filteredFees.reduce((acc, f) => {
      const s = String(f.status || 'unknown').toLowerCase();
      acc[s] = (acc[s] || 0) + Number(f.amount || 0);
      return acc;
    }, {});
    return { total, byStatus };
  }, [filteredFees]);

  const exportCsv = () => {
    const rows = filteredFees.map(f => {
      const s = students.find(s => s.id === f.student_id);
      return {
  estudiante: s?.whole_name || '-',
  run: s?.run || '-',
  curso: s?.curso_label || '-',
        numero_cuota: f.numero_cuota,
        monto: f.amount,
        fecha_vencimiento: f.due_date,
        estado: f.status,
        metodo_pago: f.payment_method,
        anio: f.year ?? f.year_academico,
      };
    });
    downloadCSV(`aranceles_${year}_${selectedStudent === 'all' ? 'todos' : selectedStudent}.csv`, rows);
  };

  if (!user) {
    return <div className="p-6">No autenticado.</div>;
  }
  if (user.role !== 'guardian') {
    return <div className="p-6">Esta página es solo para apoderados.</div>;
  }

  if (checking || loading) {
    return (
      <div className="flex-1 flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }

  if (!guardian) {
    return (
      <div className="p-6">
        <h1 className="text-2xl font-semibold mb-2">Portal de Apoderados</h1>
        <p className="text-sm text-gray-600">Aún no encontramos tu registro de apoderado. Intenta refrescar en unos minutos.</p>
        <button onClick={() => refresh({ force: true })} className="mt-3 px-4 py-2 bg-primary text-white rounded">Reintentar</button>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="flex items-start justify-between gap-3 mb-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 dark:text-white mb-1">Portal de Apoderados</h1>
          <p className="text-gray-600 dark:text-gray-300">Revisa la situación financiera de tus estudiantes.</p>
        </div>
        <button onClick={() => refresh({ force: true })} className="px-3 py-2 text-sm rounded bg-gray-100 hover:bg-gray-200">
          {refreshing ? 'Actualizando…' : 'Actualizar'}
        </button>
      </div>

      {error && (
        <div className="border border-red-300 bg-red-50 dark:bg-red-900/30 text-sm text-red-700 rounded p-3 mb-4">
          {error}
        </div>
      )}

      {/* MP-02: Estado de matrícula */}
      {enrollment && (
        <div className="mb-6 p-4 rounded border bg-white dark:bg-gray-900 dark:border-gray-800">
          <h2 className="text-lg font-semibold mb-3">Estado de Matrícula {enrollment.year || currentYear}</h2>
          <div className="flex items-center gap-3 mb-3">
            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${
              enrollment.status === 'completed'
                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                : enrollment.status === 'pending' || enrollment.status === 'draft'
                ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
                : 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400'
            }`}>
              {enrollment.status === 'completed' ? '✓ Matrícula Finalizada'
                : enrollment.status === 'pending' ? '⏳ Matrícula Pendiente'
                : enrollment.status === 'draft' ? '📝 Matrícula en Borrador'
                : enrollment.status}
            </span>
            {enrollment.meta?.folio && (
              <span className="text-xs text-gray-500 dark:text-gray-400">Folio: {enrollment.meta.folio}</span>
            )}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-300">
            <span className="font-medium">Estudiantes matriculados:</span>{' '}
            {enrollmentStudentIds.length > 0
              ? students.filter(s => enrollmentStudentIds.includes(s.id)).map(s => s.whole_name || s.run).join(', ')
              : 'Ninguno'}
          </div>
          {enrollmentDocs.length > 0 && (
            <div className="mt-3">
              <span className="text-sm font-medium text-gray-600 dark:text-gray-300">Documentos:</span>
              <div className="mt-1 flex flex-wrap gap-2">
                {enrollmentDocs.map((doc, i) => (
                  <span key={i} className={`inline-flex items-center px-2 py-0.5 rounded text-xs ${
                    doc.status === 'signed' || doc.status === 'completed'
                      ? 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400'
                      : 'bg-yellow-50 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400'
                  }`}>
                    {doc.document_type || doc.type || 'Documento'}: {doc.status === 'signed' || doc.status === 'completed' ? '✓ Firmado' : '⏳ Pendiente'}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      <div className="flex items-baseline justify-between mb-3">
        <h2 className="text-lg font-semibold">Aranceles</h2>
      </div>

      <div className="flex flex-wrap gap-3 items-center mb-4">
        <div>
          <label className="block text-sm text-gray-600 dark:text-gray-300 mb-1">Estudiante</label>
          <select
            value={selectedStudent}
            onChange={e => setSelectedStudent(e.target.value === 'all' ? 'all' : e.target.value)}
            className="border rounded px-3 py-2 bg-white dark:bg-gray-800 dark:text-white min-w-[220px]"
          >
            <option value="all">Todos</option>
            {students.map(s => (
              <option key={s.id} value={s.id}>{s.whole_name || s.run}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm text-gray-600 dark:text-gray-300 mb-1">Año</label>
          <select
            value={year}
            onChange={e => setYear(Number(e.target.value))}
            className="border rounded px-3 py-2 bg-white dark:bg-gray-800 dark:text-white"
          >
            {availableYears.map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm text-gray-600 dark:text-gray-300 mb-1">Estado</label>
          <select
            value={status}
            onChange={e => setStatus(e.target.value)}
            className="border rounded px-3 py-2 bg-white dark:bg-gray-800 dark:text-white"
          >
            <option value="all">Todos</option>
            <option value="pending">Pendiente</option>
            <option value="paid">Pagado</option>
            <option value="overdue">Atrasado</option>
          </select>
        </div>

        <button
          onClick={exportCsv}
          className="ml-auto inline-flex items-center px-4 py-2 rounded bg-primary text-white hover:opacity-90"
        >
          Exportar CSV
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="p-4 rounded border bg-white dark:bg-gray-900 dark:border-gray-800">
          <div className="text-sm text-gray-500 dark:text-gray-400">Total ({filteredFees.length} cuotas)</div>
          <div className="text-xl font-semibold">{formatCurrency(totals.total)}</div>
        </div>
        <div className="p-4 rounded border bg-white dark:bg-gray-900 dark:border-gray-800">
          <div className="text-sm text-gray-500 dark:text-gray-400">Pendiente</div>
          <div className="text-xl font-semibold">{formatCurrency(totals.byStatus?.pending || 0)}</div>
        </div>
        <div className="p-4 rounded border bg-white dark:bg-gray-900 dark:border-gray-800">
          <div className="text-sm text-gray-500 dark:text-gray-400">Atrasado</div>
          <div className="text-xl font-semibold">{formatCurrency(totals.byStatus?.overdue || 0)}</div>
        </div>
      </div>

      <div className="overflow-x-auto border rounded bg-white dark:bg-gray-900 dark:border-gray-800">
        {refreshing ? (
          <div className="p-6 text-center text-gray-500 dark:text-gray-400">Cargando…</div>
        ) : filteredFees.length === 0 ? (
          <div className="p-6 text-center text-gray-500 dark:text-gray-400">Sin cuotas para los filtros seleccionados.</div>
        ) : (
          students
            .filter(s => selectedStudent === 'all' || s.id === selectedStudent)
            .map(s => {
              const feesForStudent = filteredFees.filter(f => f.student_id === s.id);
              const subtotal = feesForStudent.reduce((acc, f) => acc + Number(f.amount || 0), 0);
              return (
                <div key={s.id} className="border-b dark:border-gray-800">
                  <div className="px-4 py-3 bg-gray-50 dark:bg-gray-800 flex items-center justify-between">
                    <div className="font-medium">{s.whole_name || '-'} <span className="text-xs text-gray-500 ml-2">{s.run}</span></div>
                    <div className="text-sm">Subtotal: <span className="font-semibold">{formatCurrency(subtotal)}</span></div>
                  </div>
                  <table className="min-w-full text-sm">
                    <thead className="text-gray-700 dark:text-gray-200">
                      <tr>
                        <th className="text-left p-3 w-24">Cuota</th>
                        <th className="text-right p-3 w-32">Monto</th>
                        <th className="text-left p-3 w-40">Vencimiento</th>
                        <th className="text-left p-3 w-28">Estado</th>
                        <th className="text-left p-3 w-32">Método</th>
                        <th className="text-left p-3 w-40">Recibo</th>
                      </tr>
                    </thead>
                    <tbody>
                      {feesForStudent.map(f => (
                        <tr key={f.id} className="border-t dark:border-gray-800">
                          <td className="p-3">{f.numero_cuota}</td>
                          <td className="p-3 text-right">{formatCurrency(f.amount)}</td>
                          <td className="p-3">{new Date(f.due_date).toLocaleDateString('es-CL')}</td>
                          <td className="p-3 capitalize">{String(f.status).toLowerCase()}</td>
                          <td className="p-3 capitalize">{String(f.payment_method).toLowerCase()}</td>
                          <td className="p-3">
                            <button className="text-primary disabled:text-gray-400" disabled title="Próximamente">Descargar PDF</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              );
            })
        )}
      </div>
    </div>
  );
}
