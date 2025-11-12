import React, { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import { useGuardianData } from '../../contexts/GuardianContext';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';
import { addStudentToEnrollment, removeStudentFromEnrollment, updateEnrollmentMeta, ensureEnrollmentDocuments } from '../../services/matricula';
import GuardianCompletionNotice from '../../components/guardian/GuardianCompletionNotice';
import { sendGuardianCompletionEmail } from '../../services/guardianNotifications';

const STEP_LABELS = [
  'Seleccionar estudiantes',
  'Documentos requeridos',
  'Resumen de pagos'
];

const CLP_FORMATTER = new Intl.NumberFormat('es-CL', { maximumFractionDigits: 0 });

const statusBadge = (status) => {
  const value = String(status || '').toLowerCase();
  const styles = {
    submitted: 'bg-green-100 text-green-800',
    approved: 'bg-green-100 text-green-800',
    completed: 'bg-green-100 text-green-800',
    pending: 'bg-amber-100 text-amber-800',
    draft: 'bg-amber-100 text-amber-800',
    generated: 'bg-blue-100 text-blue-800',
    rejected: 'bg-red-100 text-red-800',
    overdue: 'bg-red-100 text-red-800',
  };
  const classes = styles[value] || 'bg-gray-100 text-gray-700';
  return <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${classes}`}>{value || 'sin estado'}</span>;
};

const getNumericYear = (value) => {
  if (value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isInteger(parsed) ? parsed : null;
};

const inferFeeYear = (fee) => {
  const directYear = getNumericYear(fee?.year);
  if (directYear !== null) return directYear;
  const academicYear = getNumericYear(fee?.year_academico);
  if (academicYear !== null) return academicYear;
  if (fee?.due_date) {
    const dueDate = new Date(fee.due_date);
    if (!Number.isNaN(dueDate.getTime())) {
      return dueDate.getFullYear();
    }
  }
  return null;
};

export function GuardianEnrollmentPage() {
  const { data, loading, refreshing, refresh } = useGuardianData();
  const { checking } = useGuardianIntakeGate();
  const [step, setStep] = useState(0);
  const [savingMeta, setSavingMeta] = useState(false);
  const [generatingDocs, setGeneratingDocs] = useState(false);
  const [sendingCompletionEmail, setSendingCompletionEmail] = useState(false);

  const availableYears = useMemo(() => {
    const uniqueYears = new Set();
    if (Array.isArray(data?.availableEnrollmentYears)) {
      data.availableEnrollmentYears.forEach((value) => {
        const numeric = getNumericYear(value);
        if (numeric !== null) uniqueYears.add(numeric);
      });
    }
    [data?.upcomingEnrollmentYear, data?.currentEnrollmentYear, data?.enrollment?.year].forEach((value) => {
      const numeric = getNumericYear(value);
      if (numeric !== null) uniqueYears.add(numeric);
    });
    return Array.from(uniqueYears).sort((a, b) => a - b);
  }, [data?.availableEnrollmentYears, data?.upcomingEnrollmentYear, data?.currentEnrollmentYear, data?.enrollment?.year]);

  const defaultYear = useMemo(() => {
    const upcoming = getNumericYear(data?.upcomingEnrollmentYear);
    if (upcoming !== null) return upcoming;
    if (availableYears.length) return availableYears[availableYears.length - 1];
    const enrollmentYear = getNumericYear(data?.enrollment?.year);
    if (enrollmentYear !== null) return enrollmentYear;
    return null;
  }, [data?.upcomingEnrollmentYear, availableYears, data?.enrollment?.year]);

  const [selectedYear, setSelectedYear] = useState(() => defaultYear);

  useEffect(() => {
    if (!availableYears.length) {
      if (selectedYear !== null) setSelectedYear(null);
      return;
    }
    if (selectedYear !== null && availableYears.includes(selectedYear)) {
      return;
    }
    if (defaultYear !== null && availableYears.includes(defaultYear)) {
      setSelectedYear(defaultYear);
      return;
    }
    setSelectedYear(availableYears[availableYears.length - 1]);
  }, [availableYears, defaultYear, selectedYear]);

  const activeBundle = useMemo(() => {
    if (!data?.enrollmentsByYear) return null;
    const byYear = data.enrollmentsByYear;

    const pickBundle = (yearValue) => {
      const numeric = getNumericYear(yearValue);
      if (numeric === null) return null;
      const key = String(numeric);
      return byYear[key] ?? null;
    };

    if (selectedYear !== null) {
      const bundle = pickBundle(selectedYear);
      if (bundle) return bundle;
    }
    if (defaultYear !== null) {
      const bundle = pickBundle(defaultYear);
      if (bundle) return bundle;
    }

    const numericKeys = Object.keys(byYear)
      .map((key) => getNumericYear(key))
      .filter((value) => value !== null)
      .sort((a, b) => a - b);

    if (numericKeys.length) {
      return pickBundle(numericKeys[numericKeys.length - 1]);
    }

    const rawKeys = Object.keys(byYear);
    if (rawKeys.length) {
      return byYear[rawKeys[rawKeys.length - 1]];
    }

    return null;
  }, [data?.enrollmentsByYear, selectedYear, defaultYear]);

  const activeEnrollment = useMemo(() => {
    if (activeBundle?.enrollment) return activeBundle.enrollment;
    if (selectedYear !== null && data?.enrollment && getNumericYear(data.enrollment.year) === selectedYear) {
      return data.enrollment;
    }
    if (!activeBundle && data?.enrollment) {
      return data.enrollment;
    }
    return null;
  }, [activeBundle?.enrollment, data?.enrollment, selectedYear]);

  const activeStudentIds = useMemo(() => {
    if (activeBundle?.studentIds?.length) return activeBundle.studentIds;
    if (Array.isArray(data?.enrollmentStudentIds)) return data.enrollmentStudentIds;
    return [];
  }, [activeBundle?.studentIds, data?.enrollmentStudentIds]);

  const activeDocuments = useMemo(() => {
    if (activeBundle?.documents?.length) return activeBundle.documents;
    if (Array.isArray(data?.enrollmentDocuments)) return data.enrollmentDocuments;
    return [];
  }, [activeBundle?.documents, data?.enrollmentDocuments]);

  const activeFees = useMemo(() => {
    if (activeBundle?.fees?.length) return activeBundle.fees;
    if (Array.isArray(data?.fees) && data.fees.length) {
      if (selectedYear === null) return data.fees;
      return data.fees.filter((fee) => inferFeeYear(fee) === selectedYear);
    }
    return [];
  }, [activeBundle?.fees, data?.fees, selectedYear]);

  const selectedStudentIds = useMemo(() => new Set(activeStudentIds), [activeStudentIds]);

  const enrollmentStatus = String(activeEnrollment?.status || '').toLowerCase();
  const showCompletionNotice = ['completed', 'approved', 'finalized'].includes(enrollmentStatus);

  const matriculaStudents = useMemo(() => (
    (data?.students || []).map((student) => ({
      id: student.id,
      whole_name: student.whole_name || undefined,
      first_name: student.first_name || undefined,
      last_name: student.last_name || undefined,
      run: student.run || undefined,
      curso: student.curso_id || undefined,
      curso_nombre: student.curso_label || undefined,
      curso_id: student.curso_id || undefined,
      grade: student.grade || undefined,
      nivel: student.nivel || undefined,
      date_of_birth: student.date_of_birth || undefined,
    }))
  ), [data?.students]);

  const feesByStudent = useMemo(() => {
    if (!activeFees.length) return new Map();
    const grouped = new Map();
    activeFees.forEach((fee) => {
      if (!fee?.student_id) return;
      const list = grouped.get(fee.student_id) || [];
      list.push(fee);
      grouped.set(fee.student_id, list);
    });
    return grouped;
  }, [activeFees]);

  const documentStats = useMemo(() => {
    const docs = activeDocuments;
    const totals = { approved: 0, rejected: 0, pending: 0 };
    docs.forEach((doc) => {
      const status = String(doc.status || '').toLowerCase();
      if (status === 'approved' || status === 'signed') totals.approved += 1;
      else if (status === 'rejected') totals.rejected += 1;
      else totals.pending += 1;
    });
    return { docs, totals };
  }, [activeDocuments]);

  const totalFeeSummary = useMemo(() => {
    if (!activeFees.length) {
      return { total: 0, pending: 0, overdue: 0 };
    }
    return activeFees.reduce((acc, fee) => {
      const amount = Number(fee.amount || 0);
      acc.total += amount;
      const status = String(fee.status || '').toLowerCase();
      if (status === 'pending') acc.pending += amount;
      if (status === 'overdue') acc.overdue += amount;
      return acc;
    }, { total: 0, pending: 0, overdue: 0 });
  }, [activeFees]);

  const handleToggleStudent = async (studentId, checked) => {
    if (!activeEnrollment) return;
    try {
      if (checked) {
        await addStudentToEnrollment(activeEnrollment.id, studentId);
      } else {
        await removeStudentFromEnrollment(activeEnrollment.id, studentId);
      }
      await refresh({ force: true });
    } catch (error) {
      console.error('Error updating enrollment student', error);
      toast.error('No se pudo actualizar la matrícula');
    }
  };

  const persistMetaField = async (field, value) => {
    if (!activeEnrollment) return;
    try {
      setSavingMeta(true);
      await updateEnrollmentMeta(activeEnrollment.id, { [field]: value });
      await refresh({ force: true });
    } catch (error) {
      console.error('Error saving enrollment meta', error);
      toast.error('No se pudo guardar la preferencia');
    } finally {
      setSavingMeta(false);
    }
  };

  const handleGenerateDocuments = async () => {
    if (!activeEnrollment || !data?.guardian) return;
    setGeneratingDocs(true);
    try {
      const debtTotal = activeFees.reduce((acc, fee) => {
        const status = String(fee.status || '').toLowerCase();
        if (status === 'overdue') {
          return acc + Number(fee.amount || 0);
        }
        return acc;
      }, 0);

      await ensureEnrollmentDocuments({
        enrollment: activeEnrollment,
        guardian: data.guardian,
        students: matriculaStudents,
        meta: activeEnrollment.meta || {},
        debtTotal,
      });
      toast.success('Documentos sincronizados');
      await refresh({ force: true });
    } catch (error) {
      console.error('Error generating enrollment documents', error);
      toast.error('No se pudieron generar los documentos');
    } finally {
      setGeneratingDocs(false);
    }
  };

  const handleSendCompletionEmail = async () => {
    if (!data?.guardian?.email) {
      toast.error('Agrega un correo de contacto antes de enviar la confirmación.');
      return;
    }
    try {
      setSendingCompletionEmail(true);
      const portalUrl = typeof window !== 'undefined' ? `${window.location.origin}/apoderado/matricula` : undefined;
      await sendGuardianCompletionEmail({
        guardian: data.guardian,
        students: data.students || [],
        enrollment: activeEnrollment,
        documents: activeDocuments,
        year: activeYearLabel,
        portalUrl,
      });
      toast.success('Reenviamos la confirmación a tu correo.');
    } catch (error) {
      console.error('Error enviando confirmación', error);
      const message = error?.message || 'No pudimos enviar el correo de confirmación.';
      toast.error(message);
    } finally {
      setSendingCompletionEmail(false);
    }
  };

  const canProceed = () => {
    if (step === 0) {
      return selectedStudentIds.size > 0;
    }
    if (step === 1) {
      return true;
    }
    return true;
  };

  const goNext = () => {
    if (step >= STEP_LABELS.length - 1) return;
    if (!canProceed()) {
      toast.error('Completa el paso antes de continuar');
      return;
    }
    setStep(step + 1);
  };

  const goBack = () => {
    if (step === 0) return;
    setStep(step - 1);
  };

  if (checking || loading) {
    return (
      <div className="flex-1 flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }

  if (!data?.guardian) {
    return (
      <div className="p-6">
        <h1 className="text-xl font-semibold mb-2">Matrícula</h1>
        <p className="text-sm text-gray-600">Aún no encontramos tu perfil de apoderado. Intenta refrescar en unos minutos.</p>
        <button
          onClick={() => refresh({ force: true })}
          className="mt-3 px-4 py-2 rounded bg-primary text-white"
        >
          Reintentar
        </button>
      </div>
    );
  }

  if (!activeEnrollment) {
    return (
      <div className="p-6">
        <h1 className="text-xl font-semibold mb-2">Matrícula</h1>
        <p className="text-sm text-gray-600">Estamos preparando tu proceso de matrícula. Vuelve a intentarlo en unos instantes.</p>
        <button
          onClick={() => refresh({ force: true })}
          className="mt-3 px-4 py-2 rounded bg-primary text-white"
        >
          Actualizar
        </button>
      </div>
    );
  }

  const activeYearLabel = selectedYear ?? getNumericYear(activeEnrollment.year) ?? '';

  return (
    <div className="p-6 space-y-6">
      {showCompletionNotice && (
        <GuardianCompletionNotice
          className="mb-2"
          guardianName={data.guardian?.first_name || data.guardian?.whole_name}
          email={data.guardian?.email}
          onViewDocuments={() => setStep(1)}
          onSendEmail={handleSendCompletionEmail}
          sendingEmail={sendingCompletionEmail}
        />
      )}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Matrícula {activeYearLabel}</h1>
          <p className="text-sm text-gray-600">Sigue los pasos para revisar y completar tu matrícula. Puedes retomar cuando lo necesites.</p>
        </div>
        <div className="flex items-center gap-3">
          {availableYears.length > 1 && (
            <select
              value={selectedYear ?? ''}
              onChange={(event) => {
                const rawValue = event.target.value;
                if (!rawValue) {
                  setSelectedYear(null);
                  return;
                }
                const numeric = Number(rawValue);
                setSelectedYear(Number.isNaN(numeric) ? null : numeric);
              }}
              className="px-3 py-2 text-sm border rounded"
            >
              {availableYears.map((year) => (
                <option key={year} value={year}>{year}</option>
              ))}
            </select>
          )}
          <button
            onClick={() => refresh({ force: true })}
            className="px-3 py-2 text-sm rounded bg-gray-100 hover:bg-gray-200"
          >
            {refreshing ? 'Actualizando…' : 'Actualizar'}
          </button>
        </div>
      </div>

      <div className="flex items-center gap-3">
        {STEP_LABELS.map((label, index) => (
          <React.Fragment key={label}>
            <button
              onClick={() => setStep(index)}
              className={`flex-1 px-3 py-2 rounded border text-sm font-medium transition ${
                index === step
                  ? 'border-primary text-primary bg-primary/10'
                  : 'border-gray-200 hover:border-primary/40 hover:text-primary'
              }`}
            >
              {label}
            </button>
            {index < STEP_LABELS.length - 1 && <div className="w-6 h-px bg-gray-200" />}
          </React.Fragment>
        ))}
      </div>

      {step === 0 && (
        <div className="space-y-4">
          <div className="bg-white dark:bg-gray-900 border rounded-lg p-4">
            <h2 className="text-lg font-semibold mb-3">Selecciona los estudiantes que matricularás este año</h2>
            <p className="text-sm text-gray-600 mb-4">Los estudiantes seleccionados quedarán asociados a tu matrícula {activeEnrollment.status?.toLowerCase()}.</p>
            <div className="space-y-3">
              {(data.students || []).map((student) => {
                const checked = selectedStudentIds.has(student.id);
                return (
                  <label key={student.id} className="flex items-start gap-3 p-3 border rounded hover:bg-gray-50 cursor-pointer">
                    <input
                      type="checkbox"
                      className="mt-1"
                      checked={checked}
                      onChange={(event) => handleToggleStudent(student.id, event.target.checked)}
                    />
                    <div className="flex-1">
                      <div className="font-medium">{student.whole_name || student.first_name}</div>
                      <div className="text-xs text-gray-500">
                        {student.run ? `${student.run} · ` : ''}{student.curso_label || 'Sin curso asignado'}
                      </div>
                    </div>
                  </label>
                );
              })}
              {!data.students?.length && (
                <div className="text-sm text-gray-500">No hay estudiantes vinculados actualmente.</div>
              )}
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <button
              onClick={goNext}
              className="px-4 py-2 bg-primary text-white rounded disabled:opacity-50"
              disabled={!canProceed()}
            >
              Continuar
            </button>
          </div>
        </div>
      )}

      {step === 1 && (
        <div className="space-y-4">
          <div className="bg-white dark:bg-gray-900 border rounded-lg p-4">
            <h2 className="text-lg font-semibold mb-2">Revisa el estado de tus documentos</h2>
            <p className="text-sm text-gray-600 mb-4">Consulta qué documentos están pendientes, aprobados o requieren correcciones.</p>
            {documentStats.docs.length === 0 ? (
              <div className="text-sm text-gray-500">Aún no se han generado documentos para tu matrícula.</div>
            ) : (
              <div className="space-y-3">
                {documentStats.docs.map((doc) => (
                  <div key={doc.id} className="p-3 border rounded flex items-center justify-between">
                    <div>
                      <div className="font-medium">{doc.type}</div>
                      <div className="text-xs text-gray-500">Versión {doc.template_version}</div>
                    </div>
                    {statusBadge(doc.status)}
                  </div>
                ))}
              </div>
            )}
            <div className="flex justify-end mt-4">
              <button
                onClick={handleGenerateDocuments}
                className="px-4 py-2 text-sm rounded bg-primary text-white disabled:opacity-60"
                disabled={generatingDocs || !matriculaStudents.length}
              >
                {generatingDocs ? 'Sincronizando…' : 'Generar / actualizar documentos'}
              </button>
            </div>
          </div>

          <div className="bg-white dark:bg-gray-900 border rounded-lg p-4">
            <h3 className="font-semibold mb-2">Preferencias</h3>
            <div className="flex items-center justify-between border rounded px-3 py-2">
              <div>
                <div className="font-medium text-sm">¿Necesitas ayuda para completar la matrícula?</div>
                <p className="text-xs text-gray-500">Marca esta opción si deseas que el equipo te contacte.</p>
              </div>
              <input
                type="checkbox"
                checked={Boolean(activeEnrollment.meta?.needs_assistance)}
                onChange={(event) => persistMetaField('needs_assistance', event.target.checked)}
                disabled={savingMeta}
              />
            </div>
          </div>

          <div className="flex justify-between">
            <button onClick={goBack} className="px-4 py-2 rounded border">Volver</button>
            <button onClick={goNext} className="px-4 py-2 bg-primary text-white rounded">Continuar</button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4">
          <div className="bg-white dark:bg-gray-900 border rounded-lg p-4">
            <h2 className="text-lg font-semibold mb-2">Resumen de cuotas</h2>
            <p className="text-sm text-gray-600 mb-4">Visualiza los montos totales y revisa los estados de pago por estudiante.</p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Total anual</div>
                <div className="text-lg font-semibold">${CLP_FORMATTER.format(totalFeeSummary.total)}</div>
              </div>
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Pendiente</div>
                <div className="text-lg font-semibold text-amber-600">${CLP_FORMATTER.format(totalFeeSummary.pending)}</div>
              </div>
              <div className="p-3 border rounded">
                <div className="text-xs text-gray-500">Atrasado</div>
                <div className="text-lg font-semibold text-red-600">${CLP_FORMATTER.format(totalFeeSummary.overdue)}</div>
              </div>
            </div>
            {(data.students || []).map((student) => {
              const fees = feesByStudent.get(student.id) || [];
              if (!fees.length) return null;
              return (
                <div key={student.id} className="border rounded mb-3">
                  <div className="px-3 py-2 bg-gray-50 flex items-center justify-between">
                    <div className="font-medium">{student.whole_name || student.first_name}</div>
                    <div className="text-xs text-gray-500">{student.curso_label || 'Sin curso'}</div>
                  </div>
                  <div className="divide-y">
                    {fees.map((fee) => (
                      <div key={fee.id} className="flex items-center justify-between px-3 py-2 text-sm">
                        <div>
                          <div>Cuota {fee.numero_cuota ?? '-'} · {fee.year || fee.year_academico || ''}</div>
                          <div className="text-xs text-gray-500">Vencimiento: {fee.due_date ? new Date(fee.due_date).toLocaleDateString('es-CL') : 'Sin fecha'}</div>
                        </div>
                        <div className="text-right">
                          <div className="font-medium">${CLP_FORMATTER.format(Number(fee.amount || 0))}</div>
                          {statusBadge(fee.status)}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
            {!data.fees?.length && (
              <div className="text-sm text-gray-500">No encontramos cuotas asociadas a tus estudiantes para este año.</div>
            )}
          </div>

          <div className="flex justify-between">
            <button onClick={goBack} className="px-4 py-2 rounded border">Volver</button>
            <div className="flex items-center gap-2 text-sm text-gray-500">
              Estado de matrícula: {statusBadge(activeEnrollment.status)}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default GuardianEnrollmentPage;
