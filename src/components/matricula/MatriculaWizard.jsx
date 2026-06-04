/**
 * MatriculaWizard — Multi-step enrollment wizard (orchestrator).
 *
 * Decomposed from the original ~2,700-line monolith into:
 *   • Custom hooks: useWizardNavigation, useAssistedMode, useEnrollmentData,
 *     useEconomicData, useDocumentGeneration
 *   • Step sub-components: StudentSelectionStep, EconomicDataStep, PreviewStep
 *   • DebtGatingBanner for debt regularization UI
 *
 * This file now acts as a thin orchestrator (~300 lines) that wires hooks together
 * and delegates rendering to the step components.
 *
 * See: AUDIT_REPORT.md — Fix #17 (SRP decomposition)
 */
import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import toast from 'react-hot-toast';

// Hooks
import {
  useWizardNavigation,
  useAssistedMode,
  useEnrollmentData,
  useEconomicData,
  useDocumentGeneration,
} from '../../hooks/matricula';

// Step sub-components
import {
  StudentSelectionStep,
  EconomicDataStep,
  PreviewStep,
  DebtGatingBanner,
} from './steps';

// Existing components
import FinalizeEnrollmentModal from './FinalizeEnrollmentModal';
import { ChequesDataModal } from './ChequesDataModal';
import { GuardianFormModal } from '../guardians/GuardianFormModal';
import { StudentFormModal } from '../students/StudentFormModal';
import { EnrollmentDashboard } from './EnrollmentDashboard';
import { GlobalEnrollmentsTable } from './GlobalEnrollmentsTable';

export function MatriculaWizard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const navigationState = location.state ?? {};
  const navigationGuardianId = navigationState.guardianId ?? null;
  const navigationGuardianSnapshot = navigationState.guardianSnapshot ?? null;
  const currentYear = new Date().getFullYear();
  const [year, setYear] = React.useState(currentYear);
  const [viewMode, setViewMode] = React.useState('dashboard');

  const assistedMode = user?.profile === 'ADMIN' || user?.profile === 'ASIST';

  // ─── Assisted Mode ───────────────────────────────────────────
  const assisted = useAssistedMode({
    assistedMode,
    navigationGuardianId,
    navigationGuardianSnapshot,
    setGuardian: (g) => enrollment_.setGuardian(g),
    setEnrollment: (e) => enrollment_.setEnrollment(e),
  });

  // Lazy-init refs to avoid circular dependency — setGuardian/setEnrollment
  // are provided by useEnrollmentData below. We use a mutable object pattern.
  const enrollment_ = useEnrollmentData({
    user,
    year,
    assistedMode,
    assistedGuardian: assisted.assistedGuardian,
    viewMode,
  });

  const {
    guardian,
    setGuardian,
    enrollment,
    setEnrollment,
    students,
    allMyStudents,
    availableYearCourses,
    loading: enrollmentLoading,
    setLoading,
    error,
    // Debt
    debtInfo,
    debtDoc,
    setDebtDoc,
    debtLoading,
    hasRegularized,
    setHasRegularized,
    regularizationSigned,
    setRegularizationSigned,
    refreshingState,
    refreshDebtAndRegularization,
    // Student management
    handleAddStudent,
    handleRemoveStudent,
    handleStudentModalSuccess,
  } = enrollment_;

  // ─── Economic Data ───────────────────────────────────────────
  const econ = useEconomicData({
    enrollment,
    students,
    year,
    availableYearCourses,
    setEnrollment,
  });

  // ─── Wizard Navigation ──────────────────────────────────────
  // Use aggregated per-student totals for validation instead of the global
  // economic state, because the UI only edits per-student fields.
  const nav = useWizardNavigation({
    students,
    economic: {
      colegiatura_anual: econ.aggregatedEconomicTotals.totalColegiatura || econ.economic.colegiatura_anual,
      cantidad_cuotas: econ.aggregatedEconomicTotals.cantidadCuotas || econ.economic.cantidad_cuotas,
      dia_vencimiento: econ.aggregatedEconomicTotals.diaVencimiento || econ.economic.dia_vencimiento,
    },
    prioritario: econ.prioritario,
    previewHtml: '', // Will be overridden below
    debtInfo,
    hasRegularized,
    debtDoc,
  });

  // ─── Document Generation & Finalization ─────────────────────
  const docs = useDocumentGeneration({
    user,
    guardian,
    enrollment,
    students,
    year,
    assistedMode,
    economic: econ.economic,
    studentEconomicMap: econ.studentEconomicMap,
    paymentMethod: econ.paymentMethod,
    descuentoPlanilla: econ.descuentoPlanilla,
    descuentoInfo: econ.descuentoInfo,
    prioritario: econ.prioritario,
    cheques: econ.cheques,
    paymentPlan: econ.paymentPlan,
    availableYearCourses,
    aggregatedEconomicTotals: econ.aggregatedEconomicTotals,
    totalNetMonthlyInstallment: econ.totalNetMonthlyInstallment,
    debtInfo,
    setEnrollment,
    setLoading,
    reloadEnrollmentStudents: enrollment_.reloadEnrollmentStudents,
    setStep: nav.setStep,
    navigate,
  });

  // Wire previewHtml into navigation's canProceed for step 2
  const canProceedWithPreview = () => {
    if (nav.step === 2) return !!docs.previewHtml;
    return nav.canProceed();
  };

  const loading = enrollmentLoading;

  // ─── RENDER ─────────────────────────────────────────────────
  return (
    <main className="flex-1 min-w-0 p-4 space-y-4 animate-fade-in">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Matrícula {year}</h1>
      <p className="text-sm text-gray-600 dark:text-gray-400">
        Asistente básico de matrícula y generación de Pagaré (versión inicial).
      </p>

      {/* ─── Assisted mode selector ─── */}
      {assistedMode && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-semibold text-gray-900 dark:text-white">Modo asistido</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">Selecciona el apoderado para operar en su nombre.</p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {!assisted.assistedGuardian ? (
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={assisted.guardianSearch}
                    onChange={e => {
                      const q = e.target.value;
                      assisted.setGuardianSearch(q);
                      assisted.debouncedSearchGuardians(q);
                    }}
                    placeholder="Buscar por nombre, RUN o email..."
                    aria-label="Buscar apoderado por nombre, RUN o email"
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <Button onClick={() => assisted.searchGuardians(assisted.guardianSearch)} disabled={assisted.guardianSearchLoading}>
                    {assisted.guardianSearchLoading ? 'Buscando...' : 'Buscar'}
                  </Button>
                </div>
                <div className="max-h-64 overflow-y-auto divide-y divide-gray-100 dark:divide-gray-800 rounded-lg border border-gray-100 dark:border-gray-800">
                  {(assisted.guardianResults || []).map(g => (
                    <button
                      key={g.id}
                      onClick={() => assisted.setAssistedGuardian(g)}
                      className="w-full text-left px-4 py-3 hover:bg-gray-50 dark:hover:bg-dark-hover"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">{g.first_name} {g.last_name}</div>
                      <div className="text-xs text-gray-500">RUN: {g.run || '—'} · {g.email || 'sin email'}</div>
                    </button>
                  ))}
                  {!assisted.guardianResults?.length && (
                    <div className="px-4 py-6 text-sm text-gray-500">Sin resultados. Ingresa al menos 2 caracteres.</div>
                  )}
                </div>
                <div className="p-4 rounded-lg border border-dashed border-gray-200 dark:border-gray-700 bg-white/70 dark:bg-dark/40">
                  <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">¿No encuentras al apoderado? Regístralo y abre la Encuesta de Ingreso para iniciar la matrícula.</p>
                  <Button size="sm" variant="outline" onClick={() => assisted.setGuardianModalOpen(true)}>
                    ➕ Nuevo apoderado
                  </Button>
                </div>
              </div>
            ) : (
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-sm text-gray-600 dark:text-gray-300">Operando en nombre de:</div>
                  <div className="text-base font-medium text-gray-900 dark:text-white">
                    {assisted.assistedGuardian.first_name} {assisted.assistedGuardian.last_name} · RUN: {assisted.assistedGuardian.run || '—'}
                  </div>
                </div>
                <Button variant="secondary" onClick={() => { assisted.setAssistedGuardian(null); setGuardian(null); setEnrollment(null); }}>
                  Cambiar apoderado
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Global Dashboard for ADMIN/ASIST when no guardian selected */}
      {assistedMode && !assisted.assistedGuardian && (
        <GlobalEnrollmentsTable
          onSelectEnrollment={(enr, g) => {
            assisted.setAssistedGuardian(g);
            setEnrollment(enr);
            setYear(enr.year);
            setViewMode('wizard');
          }}
        />
      )}

      {/* Error State */}
      {error && !assistedMode && (
        <Card className="border-red-500 bg-red-50 dark:bg-red-900/20">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <span className="text-2xl">⚠️</span>
              <div>
                <h3 className="font-semibold text-red-900 dark:text-red-100 mb-1">Error de Configuración</h3>
                <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
                <div className="mt-3 space-y-1 text-xs text-red-700 dark:text-red-300">
                  <p><strong>Posibles soluciones:</strong></p>
                  <ul className="list-disc ml-5 space-y-1">
                    <li>Contacte al administrador para crear su perfil de apoderado</li>
                    <li>Verifique que su cuenta esté correctamente configurada</li>
                    <li>Intente cerrar sesión y volver a ingresar</li>
                  </ul>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Loading State */}
      {loading && !error && (
        <Card>
          <CardContent className="p-8 text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">Cargando información...</p>
          </CardContent>
        </Card>
      )}

      {/* Show wizard only if no error and guardian exists */}
      {!error && guardian && (
        viewMode === 'dashboard' ? (
          <EnrollmentDashboard
            guardian={guardian}
            onContinue={enr => { setYear(enr.year); setEnrollment(enr); setViewMode('wizard'); }}
            onNewEnrollment={() => { setEnrollment(null); setViewMode('wizard'); }}
          />
        ) : (
          <>
            {/* Step indicators */}
            <div className="flex gap-2 flex-wrap">
              {nav.STEPS.map((s, idx) => (
                <span
                  key={s}
                  className={`px-3 py-1 rounded text-xs font-medium ${
                    idx === nav.step
                      ? 'bg-primary text-white'
                      : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                  }`}
                >
                  {idx + 1}. {s}
                </span>
              ))}
            </div>

            {/* Debt gating banners */}
            <DebtGatingBanner
              debtInfo={debtInfo}
              hasRegularized={hasRegularized}
              regularizationSigned={regularizationSigned}
              onDebtRegularized={(doc) => {
                setDebtDoc(doc);
                setHasRegularized(true);
                setRegularizationSigned(false);
              }}
              debtLoading={debtLoading}
              refreshingState={refreshingState}
              refreshDebtAndRegularization={refreshDebtAndRegularization}
              guardian={guardian}
              enrollment={enrollment}
              students={students}
              year={year}
            />

            {/* STEP 0: Student Selection */}
            {nav.step === 0 && (
              <StudentSelectionStep
                year={year}
                setYear={setYear}
                allMyStudents={allMyStudents}
                students={students}
                assistedMode={assistedMode}
                guardian={guardian}
                handleAddStudent={handleAddStudent}
                handleRemoveStudent={handleRemoveStudent}
                setStudentModalOpen={assisted.setStudentModalOpen}
              />
            )}

            {/* STEP 1: Economic Data */}
            {nav.step === 1 && (
              <EconomicDataStep
                year={year}
                students={students}
                studentEconomicMap={econ.studentEconomicMap}
                economic={econ.economic}
                prioritario={econ.prioritario}
                paymentMethod={econ.paymentMethod}
                setPaymentMethod={econ.setPaymentMethod}
                descuentoPlanilla={econ.descuentoPlanilla}
                setDescuentoPlanilla={econ.setDescuentoPlanilla}
                descuentoInfo={econ.descuentoInfo}
                setDescuentoInfo={econ.setDescuentoInfo}
                availableYearCourses={availableYearCourses}
                cheques={econ.cheques}
                chequesButtonLabel={econ.chequesButtonLabel}
                setShowChequesModal={econ.setShowChequesModal}
                aggregatedEconomicTotals={econ.aggregatedEconomicTotals}
                totalNetMonthlyInstallment={econ.totalNetMonthlyInstallment}
                updateStudentEconomicField={econ.updateStudentEconomicField}
                updateStudentCourseForYear={econ.updateStudentCourseForYear}
                handleSaveEconomic={econ.handleSaveEconomic}
              />
            )}

            {/* STEP 2: Preview & Download */}
            {nav.step === 2 && (
              <PreviewStep
                previewHtml={docs.previewHtml}
                previewParts={docs.previewParts}
                setPreviewParts={docs.setPreviewParts}
                documentRecord={docs.documentRecord}
                loading={loading}
                students={students}
                prioritario={econ.prioritario}
                assistedMode={assistedMode}
                paymentMethod={econ.paymentMethod}
                descuentoPlanilla={econ.descuentoPlanilla}
                guardian={guardian}
                sendingPagare={docs.sendingPagare}
                finalizing={docs.finalizing}
                finalizeAlert={docs.finalizeAlert}
                setStep={nav.setStep}
                setPreviewHtml={docs.setPreviewHtml}
                setDocumentRecord={docs.setDocumentRecord}
                setFinalizeAlert={docs.setFinalizeAlert}
                handleGeneratePagare={docs.handleGeneratePagare}
                handleDownloadPDF={docs.handleDownloadPDF}
                handlePrint={docs.handlePrint}
                handleDownloadIndividualPDF={docs.handleDownloadIndividualPDF}
                handleSendPagareEmail={docs.handleSendPagareEmail}
                handleFinalizePreview={docs.handleFinalizePreview}
              />
            )}

            {/* Navigation */}
            {!error && guardian && (
              <div className="flex justify-between pt-2">
                <Button variant="outline" onClick={nav.back} disabled={nav.step === 0 || loading}>Atrás</Button>
                {nav.step < 2 && (
                  <Button
                    onClick={nav.next}
                    disabled={!canProceedWithPreview() || loading || (debtInfo.total > 0 && !hasRegularized && !debtDoc)}
                  >
                    {debtInfo.total > 0 && !hasRegularized && !debtDoc ? 'Regularice la Deuda' : 'Siguiente'}
                  </Button>
                )}
              </div>
            )}
          </>
        )
      )}

      {/* Cheques button (outside wizard steps) */}
      {enrollment?.id && (econ.cheques?.length || 0) > 0 && (
        <div className="mt-2 flex justify-end">
          <Button variant="outline" size="sm" onClick={() => econ.setShowChequesModal(true)}>
            🧾 Ver cheques
          </Button>
        </div>
      )}

      {/* ─── MODALS ─── */}
      <ChequesDataModal
        isOpen={econ.showChequesModal}
        onClose={() => econ.setShowChequesModal(false)}
        onSave={rows => {
          econ.setCheques(rows);
          toast.success('Datos de cheques guardados. Se persistirán al generar el documento.');
        }}
        initialData={econ.cheques}
        cantidadCuotas={Math.max(1, econ.aggregatedEconomicTotals.cantidadCuotas || 1)}
        montoCuota={
          econ.totalNetMonthlyInstallment > 0
            ? econ.totalNetMonthlyInstallment
            : Number(econ.aggregatedEconomicTotals.totalNeto) / Math.max(1, econ.aggregatedEconomicTotals.cantidadCuotas) || 0
        }
        diaVencimiento={econ.aggregatedEconomicTotals.diaVencimiento || 5}
        year={enrollment?.year ?? year}
      />

      <FinalizeEnrollmentModal
        isOpen={docs.finalizeOpen}
        onClose={() => {
          if (docs.finalizing) return;
          docs.setFinalizeOpen(false);
          if (docs.enrollmentFolio) navigate('/matricula');
        }}
        onConfirm={docs.handleFinalizeConfirm}
        preview={docs.finalizePreview}
        confirming={docs.finalizing}
        students={students}
        enrollmentYear={enrollment?.year ?? year}
        folio={docs.enrollmentFolio}
        onDownloadReceipt={docs.handleDownloadEnrollmentReceipt}
        onEmailReceipt={docs.handleEmailEnrollmentReceipt}
        sendingReceipt={docs.sendingEnrollmentReceipt}
      />

      <GuardianFormModal
        isOpen={assisted.guardianModalOpen}
        onClose={() => assisted.setGuardianModalOpen(false)}
        onSuccess={assisted.handleGuardianModalSuccess}
        guardian={null}
      />

      <StudentFormModal
        isOpen={assisted.studentModalOpen}
        onClose={() => assisted.setStudentModalOpen(false)}
        student={null}
        onSuccess={handleStudentModalSuccess}
      />

      {/* Success Modal */}
      {docs.showSuccessModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <Card className="w-full max-w-md">
            <CardHeader>
              <h2 className="text-lg font-semibold text-green-600">¡Matrícula Exitosa!</h2>
            </CardHeader>
            <CardContent>
              <p className="text-gray-700 mb-4">El proceso de matrícula ha sido registrado exitosamente.</p>
              <Button
                onClick={() => {
                  docs.setShowSuccessModal(false);
                  navigate('/matricula');
                }}
                className="w-full"
              >
                Volver al Inicio
              </Button>
            </CardContent>
          </Card>
        </div>
      )}
    </main>
  );
}

export default MatriculaWizard;
