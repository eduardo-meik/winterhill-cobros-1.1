import React from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';

/**
 * Modal para confirmar la finalización de matrícula con vista previa (dry-run)
 * Props:
 * - isOpen: boolean
 * - onClose: () => void
 * - onConfirm: () => Promise<void> | void
 * - preview: any | null (resultado del dry-run)
 * - confirming?: boolean
 * - students?: array (lista actual de estudiantes seleccionados)
 * - enrollmentYear?: number
 * - folio?: string | null
 * - onDownloadReceipt?: () => void
 * - onEmailReceipt?: () => void
 * - sendingReceipt?: boolean
 */
export function FinalizeEnrollmentModal({
  isOpen,
  onClose,
  onConfirm,
  preview,
  confirming = false,
  students = [],
  enrollmentYear,
  folio,
  onDownloadReceipt,
  onEmailReceipt,
  sendingReceipt = false
}) {
  if (!isOpen) return null;

  const studentMap = Array.isArray(students)
    ? students.reduce((acc, student) => {
        acc[student.id] = student;
        return acc;
      }, {})
    : {};

  const getStudentDisplay = (studentId, fallbackName) => {
    const student = studentMap[studentId];
    if (!student) return fallbackName || studentId || '-';
    return student.run || fallbackName || student.whole_name || studentId || '-';
  };

  const normalizeCuotas = (list) => {
    if (!Array.isArray(list)) return [];
    return list.map((c) => ({
      numero_cuota: c.numero_cuota ?? c.numero ?? c.n ?? null,
      // Use final_amount if available (discounted), otherwise fallback to amount/monto
      amount: Number(c.final_amount ?? c.amount ?? c.monto ?? 0) || 0,
      original_amount: Number(c.amount ?? c.monto ?? 0) || 0,
      due_date: c.due_date ?? c.fecha ?? c.date ?? null,
      created: c.created ?? (c.existed === false),
      existed: c.existed ?? !(c.created ?? false)
    }));
  };

  const details = Array.isArray(preview?.details) ? preview.details : [];
  const normalizedDetails = details.map((detail) => ({
    student_id: detail.student_id,
    student_name: getStudentDisplay(detail.student_id, detail.student_name),
    cuotas: normalizeCuotas(detail.items)
  }));

  const explicitItems = Array.isArray(preview?.items) ? preview.items : [];
  const items = explicitItems.length
    ? explicitItems.map((entry) => ({
        ...entry,
        cuotas: Array.isArray(entry.cuotas) ? entry.cuotas : normalizeCuotas(entry.items),
        student_name: getStudentDisplay(entry.student_id, entry.student_name)
      }))
    : normalizedDetails;

  const baseSummary = preview?.summary || {};
  const summary = {
    ...baseSummary,
    year: baseSummary.year ?? preview?.year ?? enrollmentYear ?? '-',
    students_count: baseSummary.students_count ?? preview?.students_count ?? items.length ?? 0,
    total_cuotas:
      baseSummary.total_cuotas ?? items.reduce((acc, it) => acc + (Array.isArray(it.cuotas) ? it.cuotas.length : 0), 0)
  };
  const messages = Array.isArray(preview?.messages) ? preview.messages : [];

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <Card className="w-full max-w-3xl max-h-[90vh] overflow-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="w-full">
              {folio ? (
                <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-2 text-center">
                  <div className="text-4xl mb-2">🎉</div>
                  <h2 className="text-xl font-bold text-green-700 mb-1">¡Matrícula Finalizada!</h2>
                  <p className="text-sm text-green-600 mb-2">El proceso se ha completado exitosamente.</p>
                  <div className="inline-block bg-white px-3 py-1 rounded border border-green-300 shadow-sm">
                    <span className="text-xs text-gray-500 uppercase tracking-wider font-semibold mr-2">Folio</span>
                    <span className="font-mono text-lg font-bold text-gray-800">{folio}</span>
                  </div>
                </div>
              ) : (
                <h2 className="text-lg font-semibold">Confirmar matrícula</h2>
              )}
            </div>
            {!folio && <button onClick={onClose} className="text-gray-500 hover:text-gray-700 ml-4">✕</button>}
          </div>
          {!folio && <p className="text-xs text-gray-600 mt-1">Revisa el resumen antes de confirmar. No se aplicarán cambios hasta que presiones "Confirmar".</p>}
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Año</div>
                <div className="font-medium">{summary.year ?? '-'}</div>
              </div>
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Estudiantes</div>
                <div className="font-medium">{summary.students_count ?? items.length ?? 0}</div>
              </div>
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Total cuotas</div>
                <div className="font-medium">{summary.total_cuotas ?? '-'}</div>
              </div>
            </div>

            {messages.length > 0 && (
              <div className="p-3 border rounded bg-amber-50 text-amber-800 text-sm">
                <ul className="list-disc pl-5">
                  {messages.map((m, i) => (<li key={i}>{String(m)}</li>))}
                </ul>
              </div>
            )}

            {items.length > 0 ? (
              <div className="border rounded overflow-auto">
                <table className="min-w-full text-sm">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="px-3 py-2 text-left">Estudiante</th>
                      <th className="px-3 py-2 text-left">Cuotas</th>
                      <th className="px-3 py-2 text-left">Monto total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((it, idx) => {
                      const cuotas = Array.isArray(it.cuotas) ? it.cuotas : [];
                      const total = cuotas.reduce((acc, c) => acc + Number(c.amount || c.monto || 0), 0);
                      return (
                        <tr key={idx} className="border-t">
                          <td className="px-3 py-2">{it.student_name || it.student_id || '-'}</td>
                          <td className="px-3 py-2">
                            {cuotas.length ? (
                              <div className="flex flex-wrap gap-1">
                                {cuotas.map((c, i) => (
                                  <span key={i} className={`px-2 py-0.5 rounded text-xs border ${c.created ? 'bg-green-50 border-green-200 text-green-800' : 'bg-gray-50 border-gray-200 text-gray-700'}`}>
                                    #{c.numero_cuota ?? c.n} ${(c.amount).toLocaleString('es-CL')} {c.created ? 'nuevo' : 'existe'}
                                  </span>
                                ))}
                              </div>
                            ) : (
                              <span className="text-gray-500">-</span>
                            )}
                          </td>
                          <td className="px-3 py-2">${total.toLocaleString('es-CL')}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="text-sm text-gray-500">No hay detalle de cuotas en el preview.</div>
            )}

            {/* Fallback para inspección del payload completo si cambia el contrato */}
            <details className="text-xs text-gray-500">
              <summary className="cursor-pointer select-none">Ver JSON completo</summary>
              <pre className="mt-2 p-2 bg-gray-50 border rounded overflow-auto max-h-64">{JSON.stringify(preview, null, 2)}</pre>
            </details>

            <div className="flex flex-col gap-2 pt-2">
              {folio && (onDownloadReceipt || onEmailReceipt) && (
                <div className="flex gap-2 justify-between flex-wrap">
                  {onDownloadReceipt && (
                    <Button
                      type="button"
                      variant="outline"
                      onClick={onDownloadReceipt}
                      disabled={confirming || sendingReceipt}
                      className="flex-1 min-w-[140px]"
                    >
                      Descargar comprobante
                    </Button>
                  )}
                  {onEmailReceipt && (
                    <Button
                      type="button"
                      variant="outline"
                      onClick={onEmailReceipt}
                      disabled={confirming || sendingReceipt}
                      className="flex-1 min-w-[140px]"
                    >
                      {sendingReceipt ? 'Enviando…' : 'Enviar por email'}
                    </Button>
                  )}
                </div>
              )}

              <div className="flex gap-3">
                <Button variant="outline" onClick={onClose} className="flex-1">
                  {folio ? 'Cerrar' : 'Cancelar'}
                </Button>
                {!folio && (
                  <Button onClick={onConfirm} disabled={confirming} className="flex-1">
                    {confirming ? 'Confirmando…' : 'Confirmar matrícula'}
                  </Button>
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default FinalizeEnrollmentModal;
