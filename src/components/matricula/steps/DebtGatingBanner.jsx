import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../../ui/Button';
import {
  buildPagareDeudaPayload,
  renderPagareDeuda,
  createDebtPagareDocument,
  sha256,
} from '../../../services/matricula';
import toast from 'react-hot-toast';

/**
 * Debt gating banner + inline debt pagaré generator.
 * Shows different states: blocked, pending signature, signed.
 *
 * @param {Object} props
 * @param {Object} props.debtInfo - { total, items }
 * @param {boolean} props.hasRegularized - has a regularization document
 * @param {boolean} props.regularizationSigned - regularization is signed
 * @param {Function} props.onDebtRegularized - callback(doc) when a debt pagaré is generated
 * @param {boolean} props.debtLoading - debt verification loading
 * @param {boolean} props.refreshingState - refreshing state
 * @param {Function} props.refreshDebtAndRegularization - refresh handler
 * @param {Object|null} props.guardian - guardian record
 * @param {Object|null} props.enrollment - enrollment record
 * @param {Array} props.students - enrolled students
 * @param {number} props.year - academic year
 */
export function DebtGatingBanner({
  debtInfo,
  hasRegularized,
  regularizationSigned,
  onDebtRegularized,
  debtLoading,
  refreshingState,
  refreshDebtAndRegularization,
  guardian,
  enrollment,
  students,
  year,
}) {
  const navigate = useNavigate();
  const [showDebtGenerator, setShowDebtGenerator] = useState(false);
  const [debtForm, setDebtForm] = useState({ cuotas: 6, dia_vencimiento: 5 });

  if (debtInfo.total <= 0) return null;

  return (
    <>
      {/* Blocked: debt + no regularization */}
      {!hasRegularized && (
        <div className="mt-4 p-4 rounded-lg border border-red-300 bg-red-50 dark:bg-red-900/30 dark:border-red-700">
          <div className="flex items-start gap-3">
            <span className="text-xl">🛑</span>
            <div className="flex-1">
              <h3 className="font-semibold text-red-800 dark:text-red-200 text-sm mb-1">Deuda Pendiente Detectada</h3>
              <p className="text-xs text-red-700 dark:text-red-300 mb-2">
                Antes de continuar con la matrícula, debe regularizar la deuda. Puede generar un <strong>Pagaré de Deuda</strong> simple o hacerlo mediante el módulo de <strong>Repactación</strong>.
              </p>
              <p className="text-sm font-medium text-red-900 dark:text-red-100">
                Total deuda: $ {debtInfo.total.toLocaleString('es-CL')}
              </p>
              <div className="mt-3 flex gap-2 flex-wrap">
                <Button size="sm" variant="destructive" onClick={() => setShowDebtGenerator(true)}>
                  Generar Pagaré de Deuda
                </Button>
                <Button
                  size="sm"
                  variant="secondary"
                  onClick={() => {
                    if (!guardian) return;
                    const snapshot = {
                      id: guardian.id,
                      first_name: guardian.first_name,
                      last_name: guardian.last_name,
                      run: guardian.run,
                      email: guardian.email ?? null,
                      address: guardian.address ?? null,
                      phone: guardian.phone ?? null,
                      profesion: guardian.profesion ?? null,
                      estado_civil: guardian.estado_civil ?? null,
                      comuna: guardian.comuna ?? null,
                    };
                    navigate('/repactacion', {
                      state: {
                        from: 'matricula',
                        guardianId: guardian.id,
                        guardianSnapshot: snapshot,
                        enrollmentId: enrollment?.id ?? null,
                      },
                    });
                  }}
                >
                  Ir a Repactación
                </Button>
                <Button size="sm" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>
                  {refreshingState ? 'Actualizando…' : '↻ Actualizar estado'}
                </Button>
              </div>
              {debtLoading && <p className="text-xs mt-2 text-red-600">Verificando deuda...</p>}
            </div>
          </div>
        </div>
      )}

      {/* Warning: regularization generated but not signed */}
      {hasRegularized && !regularizationSigned && (
        <div className="mt-4 p-4 rounded-lg border border-yellow-300 bg-yellow-50 dark:bg-yellow-900/30 dark:border-yellow-700">
          <div className="flex items-start gap-3">
            <span className="text-xl">⚠️</span>
            <div className="flex-1">
              <h3 className="font-semibold text-yellow-800 dark:text-yellow-200 text-sm mb-1">
                Documento de Regularización Pendiente de Firma
              </h3>
              <p className="text-xs text-yellow-700 dark:text-yellow-300 mb-2">
                Se generó un pagaré de deuda o repactación pero aún no está firmado. Puede continuar con la matrícula; recuerde obtener la firma.
              </p>
              <div className="flex gap-2 flex-wrap mt-2">
                <Button size="xs" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>
                  {refreshingState ? 'Verificando…' : '↻ Actualizar estado'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Signed indicator */}
      {regularizationSigned && (
        <div className="mt-4 p-3 rounded-lg border border-green-300 bg-green-50 dark:bg-green-900/30 dark:border-green-700 text-xs text-green-800 dark:text-green-200 flex items-center justify-between">
          <span>✓ Documento de regularización firmado. Deuda formalizada.</span>
          <Button size="xs" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>
            {refreshingState ? 'Refrescando…' : '↻ Actualizar estado'}
          </Button>
        </div>
      )}

      {/* Debt generator modal-lite */}
      {showDebtGenerator && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white dark:bg-dark rounded-lg shadow-lg w-full max-w-lg p-6 space-y-4">
            <h3 className="text-lg font-semibold">Generar Pagaré de Deuda</h3>
            <p className="text-xs text-gray-600 dark:text-gray-300">
              Configure el número de cuotas para regularizar la deuda. El monto de cada cuota se calculará automáticamente.
            </p>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <label className="block text-xs mb-1 font-medium">Total Deuda (CLP)</label>
                <input type="text" readOnly value={debtInfo.total.toLocaleString('es-CL')} className="w-full border rounded px-2 py-1 bg-gray-100" />
              </div>
              <div>
                <label className="block text-xs mb-1 font-medium">Cuotas</label>
                <input type="number" min={1} max={24} value={debtForm.cuotas} onChange={e => setDebtForm(df => ({ ...df, cuotas: Number(e.target.value) }))} className="w-full border rounded px-2 py-1" />
              </div>
              <div>
                <label className="block text-xs mb-1 font-medium">Día Vencimiento (1-10)</label>
                <input type="number" min={1} max={28} value={debtForm.dia_vencimiento} onChange={e => setDebtForm(df => ({ ...df, dia_vencimiento: Number(e.target.value) }))} className="w-full border rounded px-2 py-1" />
              </div>
              <div>
                <label className="block text-xs mb-1 font-medium">Monto por Cuota (CLP)</label>
                <input type="text" readOnly value={Math.round(debtInfo.total / Math.max(1, debtForm.cuotas)).toLocaleString('es-CL')} className="w-full border rounded px-2 py-1 bg-gray-100" />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" size="sm" onClick={() => setShowDebtGenerator(false)}>Cancelar</Button>
              <Button
                size="sm"
                onClick={async () => {
                  if (!guardian) return;
                  try {
                    toast.loading('Generando pagaré de deuda...', { id: 'debt-gen' });
                    const payload = buildPagareDeudaPayload({
                      guardian,
                      year,
                      students,
                      debt: { total: debtInfo.total, cuotas: debtForm.cuotas, dia_vencimiento: debtForm.dia_vencimiento },
                    });
                    payload.folio_number = (enrollment?.id ? String(enrollment.id).slice(0, 8) : Date.now().toString().slice(-8)).toUpperCase();
                    const html = renderPagareDeuda(payload);
                    const hash = await sha256(html);
                    const doc = await createDebtPagareDocument({
                      enrollmentId: enrollment.id,
                      payload,
                      finalContent: html,
                      contentHash: hash,
                    });
                    if (doc) {
                      onDebtRegularized(doc);
                      toast.success('Pagaré de deuda generado');
                      setShowDebtGenerator(false);
                    }
                  } catch (e) {
                    console.error('Debt pagare generation error:', e?.message || e);
                    toast.error('Error generando pagaré de deuda', { id: 'debt-gen' });
                  }
                }}
              >
                Generar
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
