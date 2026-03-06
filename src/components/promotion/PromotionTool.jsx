import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { supabase } from '@/services/supabase';
import { useAcademicYear } from '../../contexts/AcademicYearContext';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { Pagination } from '../ui/Pagination';
import { usePagination } from '../../hooks/usePagination';
import toast from 'react-hot-toast';

/**
 * PromotionTool — Bulk student promotion with formal enrollment creation.
 *
 * Flow:
 *   1. Loads students from the current academic year with their promotion suggestions.
 *   2. User selects students to promote + configures payment plan.
 *   3. Preview (dry-run) → Confirm → calls `promote_and_enroll_batch` RPC.
 */
export function PromotionTool() {
  const { academicYear } = useAcademicYear();
  const targetYear = academicYear + 1;

  // ── State ──────────────────────────────────────────────────────────────────
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [selectedIds, setSelectedIds] = useState(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [filterNivel, setFilterNivel] = useState('all');
  const [previewResult, setPreviewResult] = useState(null);
  const [confirmResult, setConfirmResult] = useState(null);
  const [showPaymentConfig, setShowPaymentConfig] = useState(false);

  // Payment plan defaults
  const [paymentPlan, setPaymentPlan] = useState({
    numero_cuotas: 10,
    monto_cuota: 0,
    primera_cuota: `${targetYear}-03-01`,
  });

  // ── Fetch students with promotion suggestions ─────────────────────────────
  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      // 1. Get all students in the current academic year
      const { data: studentsData, error: studentsError } = await supabase
        .from('students')
        .select(`
          id,
          first_name,
          apellido_paterno,
          whole_name,
          run,
          estado_std,
          curso,
          cursos (
            id,
            nom_curso,
            nivel,
            year_academico
          ),
          student_guardian (
            guardian_id,
            is_primary,
            guardians (
              id,
              first_name,
              last_name
            )
          )
        `)
        .not('curso', 'is', null);

      if (studentsError) throw studentsError;

      // Filter for students whose curso matches the current academic year
      const yearStudents = (studentsData || []).filter(
        s => s.cursos?.year_academico === academicYear
      );

      // 2. Get promotion suggestion for each student via RPC
      const withSuggestions = await Promise.all(
        yearStudents.map(async (student) => {
          try {
            const { data, error } = await supabase.rpc('get_student_promotion_suggestion', {
              p_student_id: student.id,
            });
            if (error) throw error;
            return { ...student, promotion: data };
          } catch {
            return {
              ...student,
              promotion: { suggestion: null, reason: 'Error fetching suggestion' },
            };
          }
        })
      );

      setStudents(withSuggestions);
    } catch (err) {
      console.error('Error fetching students for promotion:', err);
      toast.error('Error al cargar estudiantes');
    } finally {
      setLoading(false);
    }
  }, [academicYear]);

  useEffect(() => {
    fetchStudents();
  }, [fetchStudents]);

  // ── Derived data ──────────────────────────────────────────────────────────
  const niveles = useMemo(() => {
    const set = new Set();
    students.forEach(s => {
      if (s.cursos?.nivel) set.add(s.cursos.nivel);
    });
    return Array.from(set).sort();
  }, [students]);

  const eligibleStudents = useMemo(() => {
    return students.filter(s => s.promotion?.suggestion != null);
  }, [students]);

  const filteredStudents = useMemo(() => {
    return students.filter(s => {
      if (filterNivel !== 'all' && s.cursos?.nivel !== filterNivel) return false;
      if (searchTerm) {
        const term = searchTerm.toLowerCase();
        const name = (s.whole_name || `${s.first_name || ''} ${s.apellido_paterno || ''}`).toLowerCase();
        if (!name.includes(term) && !(s.run || '').toLowerCase().includes(term)) return false;
      }
      return true;
    });
  }, [students, filterNivel, searchTerm]);

  const {
    currentPage,
    pageSize,
    setPageSize,
    totalPages,
    paginatedItems,
    handlePageChange,
  } = usePagination(filteredStudents, 25);

  // ── Selection helpers ─────────────────────────────────────────────────────
  const toggleSelect = (id) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (selectedIds.size === eligibleStudents.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(eligibleStudents.map(s => s.id)));
    }
  };

  const selectAllFiltered = () => {
    const eligible = filteredStudents.filter(s => s.promotion?.suggestion != null);
    setSelectedIds(new Set(eligible.map(s => s.id)));
  };

  // ── Preview (dry-run) ─────────────────────────────────────────────────────
  const handlePreview = async () => {
    if (selectedIds.size === 0) {
      toast.error('Seleccione al menos un estudiante');
      return;
    }
    setProcessing(true);
    setPreviewResult(null);
    setConfirmResult(null);
    toast.loading('Calculando vista previa...', { id: 'promotion' });
    try {
      const planPayload = paymentPlan.monto_cuota > 0 ? paymentPlan : null;
      const { data, error } = await supabase.rpc('promote_and_enroll_batch', {
        p_student_ids: Array.from(selectedIds),
        p_target_year: targetYear,
        p_payment_plan: planPayload,
        p_dry_run: true,
      });
      if (error) throw error;
      setPreviewResult(data);
      toast.success(`Vista previa: ${data.promoted} estudiantes serán promovidos`, { id: 'promotion' });
    } catch (err) {
      console.error('Preview error:', err);
      toast.error('Error en la vista previa', { id: 'promotion' });
    } finally {
      setProcessing(false);
    }
  };

  // ── Confirm ──────────────────────────────────────────────────────────────
  const handleConfirm = async () => {
    if (selectedIds.size === 0) return;
    setProcessing(true);
    setConfirmResult(null);
    toast.loading('Promoviendo estudiantes...', { id: 'promotion' });
    try {
      const planPayload = paymentPlan.monto_cuota > 0 ? paymentPlan : null;
      const { data, error } = await supabase.rpc('promote_and_enroll_batch', {
        p_student_ids: Array.from(selectedIds),
        p_target_year: targetYear,
        p_payment_plan: planPayload,
        p_dry_run: false,
      });
      if (error) throw error;
      setConfirmResult(data);
      setPreviewResult(null);
      setSelectedIds(new Set());
      toast.success(
        `✅ ${data.promoted} estudiantes promovidos, ${data.enrollments_created} matrículas creadas` +
        (data.fees_created > 0 ? `, ${data.fees_created} cuotas generadas` : ''),
        { id: 'promotion' }
      );
      // Refresh the list
      fetchStudents();
    } catch (err) {
      console.error('Confirm error:', err);
      toast.error('Error al confirmar promoción', { id: 'promotion' });
    } finally {
      setProcessing(false);
    }
  };

  // ── Guardian display helper ────────────────────────────────────────────────
  const getPrimaryGuardian = (student) => {
    const sg = student.student_guardian?.find(sg => sg.is_primary) || student.student_guardian?.[0];
    if (!sg?.guardians) return '—';
    return `${sg.guardians.first_name || ''} ${sg.guardians.last_name || ''}`.trim() || '—';
  };

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-4 p-4 mb-4">
          <div>
            <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">
              Promoción Masiva
            </h1>
            <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
              Año {academicYear} → {targetYear} · {eligibleStudents.length} elegibles de {students.length} estudiantes
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button
              onClick={handlePreview}
              disabled={processing || selectedIds.size === 0}
              variant="outline"
              className="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                <path d="M10.5 8a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0"/>
                <path d="M0 8s3-5.5 8-5.5S16 8 16 8s-3 5.5-8 5.5S0 8 0 8m8 3.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7"/>
              </svg>
              {processing ? 'Procesando...' : `Vista Previa (${selectedIds.size})`}
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={processing || !previewResult || selectedIds.size === 0}
              className="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                <path d="M12.736 3.97a.733.733 0 0 1 1.047 0c.286.289.29.756.01 1.05L7.88 12.01a.733.733 0 0 1-1.065.02L3.217 8.384a.757.757 0 0 1 0-1.06.733.733 0 0 1 1.047 0l3.052 3.093 5.4-6.425z"/>
              </svg>
              Confirmar Promoción
            </Button>
          </div>
        </div>

        <div className="p-4 space-y-4">
          {/* Payment Plan Config */}
          <Card>
            <CardHeader>
              <button
                onClick={() => setShowPaymentConfig(!showPaymentConfig)}
                className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 w-full text-left"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  fill="currentColor"
                  viewBox="0 0 16 16"
                  className={`transform transition-transform ${showPaymentConfig ? 'rotate-90' : ''}`}
                >
                  <path fillRule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708"/>
                </svg>
                Plan de Pago (opcional — dejar monto en 0 para omitir generación de cuotas)
              </button>
            </CardHeader>
            {showPaymentConfig && (
              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      N° de Cuotas
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="12"
                      value={paymentPlan.numero_cuotas}
                      onChange={(e) =>
                        setPaymentPlan(prev => ({ ...prev, numero_cuotas: parseInt(e.target.value) || 10 }))
                      }
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Monto por Cuota ($)
                    </label>
                    <input
                      type="number"
                      min="0"
                      step="1000"
                      value={paymentPlan.monto_cuota}
                      onChange={(e) =>
                        setPaymentPlan(prev => ({ ...prev, monto_cuota: parseInt(e.target.value) || 0 }))
                      }
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Fecha Primera Cuota
                    </label>
                    <input
                      type="date"
                      value={paymentPlan.primera_cuota}
                      onChange={(e) =>
                        setPaymentPlan(prev => ({ ...prev, primera_cuota: e.target.value }))
                      }
                      className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white"
                    />
                  </div>
                </div>
              </CardContent>
            )}
          </Card>

          {/* Preview / Confirm Results */}
          {(previewResult || confirmResult) && (
            <ResultBanner result={previewResult || confirmResult} isConfirm={!!confirmResult} />
          )}

          {/* Filters + Table */}
          <Card>
            <CardHeader>
              <div className="flex flex-wrap items-center gap-4 w-full">
                <input
                  type="text"
                  placeholder="Buscar por nombre o RUN..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="flex-1 min-w-[200px] px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white"
                />
                <select
                  value={filterNivel}
                  onChange={(e) => setFilterNivel(e.target.value)}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white"
                >
                  <option value="all">Todos los Niveles</option>
                  {niveles.map(n => (
                    <option key={n} value={n}>{n}</option>
                  ))}
                </select>
                <Button variant="outline" onClick={selectAllFiltered} className="text-sm">
                  Seleccionar Elegibles ({filteredStudents.filter(s => s.promotion?.suggestion).length})
                </Button>
                <Button variant="outline" onClick={() => setSelectedIds(new Set())} className="text-sm">
                  Deseleccionar Todo
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary" />
                </div>
              ) : (
                <>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-gray-200 dark:border-gray-700">
                          <th className="py-3 px-2 text-left">
                            <input
                              type="checkbox"
                              checked={selectedIds.size > 0 && selectedIds.size === eligibleStudents.length}
                              onChange={toggleSelectAll}
                              className="rounded border-gray-300 dark:border-gray-600"
                            />
                          </th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">Estudiante</th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">RUN</th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">Curso Actual</th>
                          <th className="py-3 px-3 text-center text-gray-600 dark:text-gray-400 font-medium">→</th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">Curso {targetYear}</th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">Apoderado</th>
                          <th className="py-3 px-3 text-left text-gray-600 dark:text-gray-400 font-medium">Estado</th>
                        </tr>
                      </thead>
                      <tbody>
                        {paginatedItems.map((student) => {
                          const suggestion = student.promotion?.suggestion;
                          const reason = student.promotion?.reason || '';
                          const isEligible = suggestion != null;
                          const isSelected = selectedIds.has(student.id);

                          return (
                            <tr
                              key={student.id}
                              className={`border-b border-gray-100 dark:border-gray-800 transition-colors ${
                                isSelected
                                  ? 'bg-primary/5 dark:bg-primary/10'
                                  : 'hover:bg-gray-50 dark:hover:bg-dark-hover'
                              } ${!isEligible ? 'opacity-60' : ''}`}
                            >
                              <td className="py-3 px-2">
                                <input
                                  type="checkbox"
                                  checked={isSelected}
                                  disabled={!isEligible}
                                  onChange={() => toggleSelect(student.id)}
                                  className="rounded border-gray-300 dark:border-gray-600"
                                />
                              </td>
                              <td className="py-3 px-3 font-medium text-gray-900 dark:text-white">
                                {student.whole_name || `${student.first_name || ''} ${student.apellido_paterno || ''}`}
                              </td>
                              <td className="py-3 px-3 text-gray-600 dark:text-gray-400">
                                {student.run || '—'}
                              </td>
                              <td className="py-3 px-3">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                                  {student.cursos?.nom_curso || '—'}
                                </span>
                              </td>
                              <td className="py-3 px-3 text-center text-gray-400">
                                {isEligible ? '→' : '—'}
                              </td>
                              <td className="py-3 px-3">
                                {isEligible ? (
                                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300">
                                    {suggestion.nom_curso}
                                  </span>
                                ) : (
                                  <span className="text-xs text-gray-500 dark:text-gray-400 italic">
                                    {reason.includes('graduating') ? 'Egresa' : 
                                     reason.includes('No curso found') ? 'Sin curso destino' : 
                                     reason.includes('no current') ? 'Sin curso asignado' : reason}
                                  </span>
                                )}
                              </td>
                              <td className="py-3 px-3 text-gray-600 dark:text-gray-400 text-xs">
                                {getPrimaryGuardian(student)}
                              </td>
                              <td className="py-3 px-3">
                                {isEligible ? (
                                  <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                                    Elegible
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                                    {reason.includes('graduating') ? 'Egresa' : 'No elegible'}
                                  </span>
                                )}
                              </td>
                            </tr>
                          );
                        })}
                        {paginatedItems.length === 0 && (
                          <tr>
                            <td colSpan={8} className="py-12 text-center text-gray-500 dark:text-gray-400">
                              {loading ? 'Cargando...' : 'No se encontraron estudiantes'}
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                  <Pagination
                    currentPage={currentPage}
                    totalPages={totalPages}
                    onPageChange={handlePageChange}
                    totalRecords={filteredStudents.length}
                    pageSize={pageSize}
                    onPageSizeChange={setPageSize}
                  />
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </main>
  );
}

// ── Sub-component: Result Banner ──────────────────────────────────────────────

function ResultBanner({ result, isConfirm }) {
  if (!result) return null;

  const hasErrors = result.errors?.length > 0;

  return (
    <Card>
      <CardContent>
        <div className={`rounded-lg p-4 ${
          isConfirm
            ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
            : 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800'
        }`}>
          <h3 className={`font-semibold mb-2 ${
            isConfirm ? 'text-green-800 dark:text-green-300' : 'text-blue-800 dark:text-blue-300'
          }`}>
            {isConfirm ? '✅ Promoción Completada' : '👁️ Vista Previa'}
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            <div>
              <span className="text-gray-500 dark:text-gray-400">Promovidos:</span>
              <span className="ml-2 font-semibold text-gray-900 dark:text-white">{result.promoted}</span>
            </div>
            <div>
              <span className="text-gray-500 dark:text-gray-400">Omitidos:</span>
              <span className="ml-2 font-semibold text-gray-900 dark:text-white">{result.skipped}</span>
            </div>
            {isConfirm && (
              <>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">Matrículas:</span>
                  <span className="ml-2 font-semibold text-gray-900 dark:text-white">{result.enrollments_created}</span>
                </div>
                <div>
                  <span className="text-gray-500 dark:text-gray-400">Cuotas generadas:</span>
                  <span className="ml-2 font-semibold text-gray-900 dark:text-white">{result.fees_created}</span>
                </div>
              </>
            )}
          </div>

          {/* Details */}
          {result.details?.length > 0 && (
            <details className="mt-3">
              <summary className="cursor-pointer text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200">
                Ver detalle ({result.details.length} estudiantes)
              </summary>
              <ul className="mt-2 space-y-1 text-xs text-gray-600 dark:text-gray-400 max-h-40 overflow-y-auto">
                {result.details.map((d, i) => (
                  <li key={i}>
                    {d.current_curso || '?'} → <span className="font-medium text-green-700 dark:text-green-400">{d.new_curso}</span>
                    <span className="ml-1 text-gray-400">({d.student_id?.substring(0, 8)})</span>
                  </li>
                ))}
              </ul>
            </details>
          )}

          {/* Errors */}
          {hasErrors && (
            <details className="mt-3">
              <summary className="cursor-pointer text-sm text-red-600 dark:text-red-400">
                ⚠️ {result.errors.length} errores
              </summary>
              <ul className="mt-2 space-y-1 text-xs text-red-600 dark:text-red-400 max-h-40 overflow-y-auto">
                {result.errors.map((e, i) => (
                  <li key={i}>
                    {e.student_id?.substring(0, 8) || e.guardian_id?.substring(0, 8)}: {e.reason}
                  </li>
                ))}
              </ul>
            </details>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export default PromotionTool;
