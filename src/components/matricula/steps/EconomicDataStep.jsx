import React from 'react';
import { Card, CardContent, CardHeader } from '../../ui/Card';
import { Button } from '../../ui/Button';
import { BoxArrowInUpRight } from '../../Icons';

/**
 * Step 1: Economic data + payment method per-student entry.
 *
 * @param {Object} props
 * @param {number} props.year - academic year
 * @param {Array} props.students - enrolled students
 * @param {Object} props.studentEconomicMap - per-student economic data
 * @param {Object} props.economic - global economic data
 * @param {boolean} props.prioritario - global prioritario flag
 * @param {Object} props.paymentMethod - payment method flags
 * @param {Function} props.setPaymentMethod - setter
 * @param {boolean} props.descuentoPlanilla - descuento por planilla flag
 * @param {Function} props.setDescuentoPlanilla - setter
 * @param {Object} props.descuentoInfo - { motivo, condiciones, porcentaje_descuento, monto_total_descuento }
 * @param {Function} props.setDescuentoInfo - setter
 * @param {Array} props.availableYearCourses - courses for year
 * @param {Array} props.cheques - cheques array
 * @param {string} props.chequesButtonLabel - formatted label for cheques button
 * @param {Function} props.setShowChequesModal - open cheques modal
 * @param {Object} props.aggregatedEconomicTotals - aggregated totals
 * @param {number} props.totalNetMonthlyInstallment - net monthly installment
 * @param {Function} props.updateStudentEconomicField - field updater
 * @param {Function} props.updateStudentCourseForYear - course updater
 * @param {Function} props.handleSaveEconomic - save handler
 */
export function EconomicDataStep({
  year,
  students,
  studentEconomicMap,
  prioritario,
  paymentMethod,
  setPaymentMethod,
  descuentoPlanilla,
  setDescuentoPlanilla,
  descuentoInfo,
  setDescuentoInfo,
  availableYearCourses,
  cheques,
  chequesButtonLabel,
  setShowChequesModal,
  aggregatedEconomicTotals,
  totalNetMonthlyInstallment,
  updateStudentEconomicField,
  updateStudentCourseForYear,
  handleSaveEconomic,
}) {
  return (
    <Card>
      <CardHeader>
        <h2 className="font-semibold">Datos Económicos y Forma de Pago</h2>
      </CardHeader>
      <CardContent className="space-y-6 text-sm">
        {/* Per-student Economic Data */}
        {students.length > 0 && (
          <div className="space-y-4">
            <h3 className="font-medium text-sm text-gray-700 dark:text-gray-300">💰 Información por Estudiante</h3>
            <div className="space-y-3 pr-1">
              {students.map(st => {
                const econ = studentEconomicMap[st.id] || {};
                const baseCursoLabel = st.curso_nombre || st.curso || '';
                return (
                  <div key={st.id} className="border rounded-lg p-3 bg-gray-50 dark:bg-gray-900/30 space-y-2">
                    <div className="flex justify-between items-center gap-2">
                      <div className="min-w-0">
                        <p className="font-medium text-sm truncate">{st.whole_name || st.run}</p>
                        {baseCursoLabel && (
                          <p className="text-[11px] text-gray-500 truncate">Curso actual: {baseCursoLabel}</p>
                        )}
                      </div>
                      <label className="flex items-center gap-2 text-[11px] font-medium text-red-600">
                        <input
                          type="checkbox"
                          className="w-4 h-4"
                          checked={Boolean(econ.prioritario)}
                          onChange={e => updateStudentEconomicField(st.id, 'prioritario', e.target.checked)}
                        />
                        <span>Prioritario</span>
                      </label>
                    </div>
                    <div className="grid md:grid-cols-3 gap-3 text-xs">
                      <div>
                        <label className="block mb-1 font-medium">Monto Matrícula (CLP)</label>
                        <input type="number" className="w-full border rounded px-2 py-1" value={econ.monto_matricula || ''} onChange={e => updateStudentEconomicField(st.id, 'monto_matricula', e.target.value)} />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Colegiatura Anual (CLP)</label>
                        <input type="number" className="w-full border rounded px-2 py-1" value={econ.colegiatura_anual || ''} onChange={e => updateStudentEconomicField(st.id, 'colegiatura_anual', e.target.value)} />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Cantidad Cuotas</label>
                        <input type="number" className="w-full border rounded px-2 py-1" value={econ.cantidad_cuotas || ''} onChange={e => updateStudentEconomicField(st.id, 'cantidad_cuotas', e.target.value)} />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Monto por Cuota (CLP)</label>
                        <input type="number" className="w-full border rounded px-2 py-1 bg-gray-100" value={econ.monto_cuota || ''} readOnly />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Día Vencimiento (1-10)</label>
                        <input type="number" min="1" max="28" className="w-full border rounded px-2 py-1" value={econ.dia_vencimiento || ''} onChange={e => updateStudentEconomicField(st.id, 'dia_vencimiento', e.target.value)} />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Porcentaje de Descuento (%)</label>
                        <input type="number" min="0" max="100" className="w-full border rounded px-2 py-1" value={econ.porcentaje_descuento ?? 0} onChange={e => updateStudentEconomicField(st.id, 'porcentaje_descuento', Number(e.target.value))} />
                      </div>
                      <div>
                        <label className="block mb-1 font-medium">Monto Total Descuento (CLP)</label>
                        <input type="number" className="w-full border rounded px-2 py-1 bg-gray-100" value={econ.monto_total_descuento ?? 0} readOnly />
                      </div>
                      <div className="md:col-span-2">
                        <label className="block mb-1 font-medium">Curso para matrícula (año {year})</label>
                        <select
                          className="w-full border rounded px-2 py-1 bg-white dark:bg-dark-hover"
                          value={econ.curso_sugerido || ''}
                          onChange={e => updateStudentCourseForYear(st.id, e.target.value)}
                        >
                          <option value="">Seleccionar curso para este año</option>
                          {availableYearCourses.map(curso => {
                            const baseLabel = curso.nom_curso || `${curso.nivel ?? ''}${curso.letra_curso ? ` ${curso.letra_curso}` : ''}`.trim() || 'Sin nombre';
                            const yearLabel = curso.year_academico ? ` (${curso.year_academico})` : '';
                            return <option key={curso.id} value={curso.id}>{baseLabel}{yearLabel}</option>;
                          })}
                        </select>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Economic Summary Section */}
        <div className="bg-gray-50 dark:bg-gray-800/50 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-medium text-base text-gray-700 dark:text-gray-300 flex items-center gap-2">
              ⚙️ Resumen Económico del Contrato
              <span className="text-xs font-normal text-gray-500">Totales consolidados que se traspasarán al contrato</span>
            </h3>
          </div>
          {students.length > 0 ? (
            <div className="mt-1 p-3 rounded-lg bg-white/70 dark:bg-dark/40 border border-dashed border-gray-300 dark:border-gray-600 text-[11px] text-gray-700 dark:text-gray-300 flex flex-wrap gap-6">
              <div>
                <div className="font-semibold text-xs">Matrícula total</div>
                <div>$ <span className="font-mono">{aggregatedEconomicTotals.totalMatricula.toLocaleString('es-CL')}</span></div>
              </div>
              <div>
                <div className="font-semibold text-xs">Colegiatura anual total</div>
                <div>$ <span className="font-mono">{aggregatedEconomicTotals.totalColegiatura.toLocaleString('es-CL')}</span></div>
              </div>
              <div>
                <div className="font-semibold text-xs">Descuento anual total</div>
                <div>$ <span className="font-mono">{aggregatedEconomicTotals.totalDescuento.toLocaleString('es-CL')}</span></div>
              </div>
              <div>
                <div className="font-semibold text-xs">Total neto anual</div>
                <div>$ <span className="font-mono">{aggregatedEconomicTotals.totalNeto.toLocaleString('es-CL')}</span></div>
              </div>
              <div>
                <div className="font-semibold text-xs">Cuota mensual combinada estimada</div>
                <div>$ <span className="font-mono">{totalNetMonthlyInstallment.toLocaleString('es-CL')}</span></div>
              </div>
            </div>
          ) : (
            <p className="text-xs text-gray-500">Agregue estudiantes y sus valores económicos para ver el resumen consolidado.</p>
          )}
        </div>

        {/* Payment Method Section */}
        <div className="border-t pt-4">
          <h3 className="font-medium text-base mb-3 text-gray-700 dark:text-gray-300">💳 Forma de Pago</h3>
          <p className="text-xs text-gray-600 dark:text-gray-400 mb-3">Seleccione uno o más métodos de pago:</p>
          <div className="grid md:grid-cols-2 gap-3">
            <label className="flex items-center justify-between gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
              <div className="flex items-center gap-2">
                <input type="checkbox" checked={paymentMethod.cheques} disabled={prioritario} onChange={e => { setPaymentMethod({ ...paymentMethod, cheques: e.target.checked }); if (e.target.checked) setShowChequesModal(true); }} className="w-4 h-4" />
                <span>📝 Cheques</span>
              </div>
              <button type="button" title="Abrir cheques" aria-label="Abrir cheques" onClick={e => { e.preventDefault(); e.stopPropagation(); if (prioritario) return; setPaymentMethod({ ...paymentMethod, cheques: true }); setShowChequesModal(true); }} disabled={prioritario} className="inline-flex items-center justify-center rounded border border-gray-200 dark:border-gray-700 bg-white/70 dark:bg-dark-hover px-2 py-2 text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50">
                <BoxArrowInUpRight />
              </button>
            </label>
            {paymentMethod.cheques && (
              <Button variant="outline" size="sm" onClick={() => setShowChequesModal(true)} className="col-span-2" disabled={prioritario}>
                {cheques && cheques.length ? `✏️ Editar ${chequesButtonLabel}` : `➕ Agregar ${chequesButtonLabel}`}
              </Button>
            )}
            <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
              <input type="checkbox" checked={paymentMethod.transferencia} disabled={prioritario} onChange={e => setPaymentMethod({ ...paymentMethod, transferencia: e.target.checked })} className="w-4 h-4" />
              <span>💸 Transferencia Electrónica</span>
            </label>
            <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
              <input type="checkbox" checked={paymentMethod.efectivo} disabled={prioritario} onChange={e => setPaymentMethod({ ...paymentMethod, efectivo: e.target.checked })} className="w-4 h-4" />
              <span>💵 Pago en Efectivo</span>
            </label>
            <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
              <input type="checkbox" checked={paymentMethod.tarjeta} disabled={prioritario} onChange={e => setPaymentMethod({ ...paymentMethod, tarjeta: e.target.checked })} className="w-4 h-4" />
              <span>💳 Tarjeta de Crédito</span>
            </label>
            <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
              <input type="checkbox" checked={paymentMethod.pagare} disabled={prioritario} onChange={e => setPaymentMethod({ ...paymentMethod, pagare: e.target.checked })} className="w-4 h-4" />
              <span>📜 Pagaré</span>
            </label>
            <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 md:col-span-2">
              <input type="checkbox" className="w-4 h-4" checked={descuentoPlanilla} disabled={prioritario} onChange={e => setDescuentoPlanilla(e.target.checked)} />
              <span>🎁 Descuento por Planilla</span>
            </label>
          </div>
          {descuentoPlanilla && !prioritario && (
            <div className="mt-4 p-4 bg-yellow-50 dark:bg-yellow-900/10 border border-yellow-200 dark:border-yellow-800 rounded-lg space-y-3">
              <p className="text-xs text-yellow-800 dark:text-yellow-200 mb-3">ℹ️ Se generará una <strong>Autorización de Descuento</strong> en lugar de un Pagaré.</p>
              <div className="grid md:grid-cols-2 gap-3">
                <div className="md:col-span-2">
                  <label className="block text-xs mb-1 font-medium">Motivo del Descuento</label>
                  <input type="text" className="w-full border rounded px-2 py-1" value={descuentoInfo.motivo} onChange={e => setDescuentoInfo({ ...descuentoInfo, motivo: e.target.value })} placeholder="Ej: Beneficio laboral" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs mb-1 font-medium">Condiciones</label>
                  <textarea className="w-full border rounded px-2 py-1" rows="2" value={descuentoInfo.condiciones} onChange={e => setDescuentoInfo({ ...descuentoInfo, condiciones: e.target.value })} placeholder="Ej: Descuento aplicable mientras se mantenga relación laboral" />
                </div>
              </div>
            </div>
          )}
        </div>

        <Button onClick={handleSaveEconomic} className="mt-4">💾 Guardar Datos</Button>
      </CardContent>
    </Card>
  );
}
