import React, { useEffect, useState, useCallback, useRef, useMemo } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import toast from 'react-hot-toast';
import {
  fetchCurrentGuardian,
  getOrCreateEnrollment,
  listEnrollmentStudents,
  addStudentToEnrollment,
  removeStudentFromEnrollment,
  updateEnrollmentMeta,
  getActivePagareTemplate,
  buildPagarePayload,
  renderTemplate,
  createPagareDocument,
    getGuardianOutstandingDebt,
    buildPagareDeudaPayload,
    renderPagareDeuda,
    createDebtPagareDocument,
    hasSignedRegularization,
  signEnrollmentDocument,
  sha256,
  buildEnrollmentPaymentPlan
} from '../../services/matricula';
import { finalizeEnrollmentPreview, finalizeEnrollmentConfirm } from '../../services/matricula';
import FinalizeEnrollmentModal from './FinalizeEnrollmentModal';
import { buildPrestacionPayload, renderPrestacionWithAnnex, createPrestacionDocument, ensureEnrollmentDocuments } from '../../services/matricula';
import { saveChequesForEnrollment } from '../../services/matricula';
import { 
  buildAutorizacionPayload, 
  generateAutorizacionHTML 
} from '../../services/autorizacionDescuento';
import { generatePDFFromHTML, downloadPDFBlob } from '../../services/pdfGenerator';
import { sendEmailViaFunction, blobToBase64 } from '../../services/email';
import { supabase } from '../../services/supabase';
import { ChequesDataModal } from './ChequesDataModal';
import { GuardianFormModal } from '../guardians/GuardianFormModal';
import { StudentFormModal } from '../students/StudentFormModal';

// Renders full HTML (including <style> in <head>) inside an iframe for accurate preview
function HtmlIframePreview({ html, height = 600 }) {
  const iframeRef = useRef(null);
  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return;
    const doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
    if (!doc) return;
    doc.open();
    doc.write(html || '');
    doc.close();
  }, [html]);
  return (
    <iframe
      ref={iframeRef}
      title="Vista previa del documento"
      style={{ width: '100%', height: `${height}px`, border: '0', background: 'white' }}
    />
  );
}

// Simple wizard steps definition
const STEPS = [
  'Seleccionar Alumnos',
  'Datos Económicos',
  'Vista Previa y Descarga'
];

export function MatriculaWizard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const navigationState = location.state ?? {};
  const navigationGuardianId = navigationState.guardianId ?? null;
  const navigationGuardianSnapshot = navigationState.guardianSnapshot ?? null;
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState(currentYear);
  const [guardian, setGuardian] = useState(null);
  const [enrollment, setEnrollment] = useState(null);
  const [students, setStudents] = useState([]);
  const [allMyStudents, setAllMyStudents] = useState([]); // potential associated students via student_guardian
  const [availableYearCourses, setAvailableYearCourses] = useState([]); // cursos del año seleccionado
  const [studentEconomicMap, setStudentEconomicMap] = useState({}); // economic data per student in enrollment
  const [economic, setEconomic] = useState({
    monto_matricula: '',
    colegiatura_anual: '',
    cantidad_cuotas: '10',
    monto_cuota: '',
    dia_vencimiento: '5'
  });
  const [paymentMethod, setPaymentMethod] = useState({
    cheques: false,
    transferencia: true, // Default
    efectivo: false,
    tarjeta: false,
    pagare: false
  });
  const paymentPlan = useMemo(() => buildEnrollmentPaymentPlan({
    enrollmentYear: year,
    economic: {
      colegiatura_anual: economic.colegiatura_anual,
      cantidad_cuotas: economic.cantidad_cuotas,
      monto_cuota: economic.monto_cuota,
      dia_vencimiento: economic.dia_vencimiento
    },
    paymentMethodFlags: paymentMethod
  }), [economic, paymentMethod, year]);
  const [descuentoPlanilla, setDescuentoPlanilla] = useState(false);
  const [descuentoInfo, setDescuentoInfo] = useState({
    porcentaje_descuento: 0,
    monto_total_descuento: 0,
    motivo: '',
    condiciones: ''
  });
  const [prioritario, setPrioritario] = useState(false); // Nuevo flag para alumno prioriotario que bloquea economía y forma de pago
  const [cheques, setCheques] = useState([]);
  const [showChequesModal, setShowChequesModal] = useState(false);
  const [step, setStep] = useState(0);
  const [template, setTemplate] = useState(null);
  const [previewHtml, setPreviewHtml] = useState('');
  const [documentRecord, setDocumentRecord] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [sendingPagare, setSendingPagare] = useState(false);
  // Debt gating state
  const [debtInfo, setDebtInfo] = useState({ total: 0, items: [] });
  const [debtDoc, setDebtDoc] = useState(null); // record of PAGARE_DEUDA if generated
  const [autoDocSyncing, setAutoDocSyncing] = useState(false);
  const [debtLoading, setDebtLoading] = useState(false);
  const [showDebtGenerator, setShowDebtGenerator] = useState(false);
  const [debtForm, setDebtForm] = useState({ cuotas: 6, dia_vencimiento: 5 });
  // Regularización: permitir avanzar si existe documento (generated o signed) y diferenciar estado firmado
  const [hasRegularized, setHasRegularized] = useState(false); // true si hay documento de regularización (generated o signed)
  const [regularizationSigned, setRegularizationSigned] = useState(false); // true sólo si está firmado
  const [refreshingState, setRefreshingState] = useState(false);
  // Finalize (staff) state
  const [finalizing, setFinalizing] = useState(false);
  const [finalizeOpen, setFinalizeOpen] = useState(false);
  const [finalizePreview, setFinalizePreview] = useState(null);
  const [finalizeAlert, setFinalizeAlert] = useState(null);
  const [guardianModalOpen, setGuardianModalOpen] = useState(false);
  const [studentModalOpen, setStudentModalOpen] = useState(false);

  // Assisted mode (ADMIN/ASIST)
  const assistedMode = user?.profile === 'ADMIN' || user?.profile === 'ASIST';
  const [assistedGuardian, setAssistedGuardian] = useState(null);
    useEffect(() => {
      if (!assistedMode) return;
      const targetId = navigationGuardianSnapshot?.id || navigationGuardianId;
      if (!targetId || assistedGuardian?.id === targetId) return;

      if (navigationGuardianSnapshot) {
        setAssistedGuardian(prev => (prev?.id === navigationGuardianSnapshot.id ? prev : navigationGuardianSnapshot));
        return;
      }

      let cancelled = false;
      (async () => {
        try {
          const { data, error } = await supabase
            .from('guardians')
            .select('id, first_name, last_name, run, email, address, phone, profesion, estado_civil, comuna')
            .eq('id', targetId)
            .maybeSingle();
          if (error) throw error;
          if (!cancelled && data) {
            setAssistedGuardian(prev => (prev?.id === data.id ? prev : data));
          }
        } catch (e) {
          console.error('Prefetch guardian for MatriculaWizard', e);
        }
      })();

      return () => {
        cancelled = true;
      };
    }, [assistedMode, navigationGuardianId, navigationGuardianSnapshot, assistedGuardian?.id]);

    useEffect(() => {
      if (!guardian) {
        setFinalizeAlert(null);
      }
    }, [guardian?.id]);

  const [guardianSearch, setGuardianSearch] = useState('');
  const [guardianResults, setGuardianResults] = useState([]);
  const [guardianSearchLoading, setGuardianSearchLoading] = useState(false);

  const searchGuardians = useCallback(async (q) => {
    if (!q || q.trim().length < 2) { setGuardianResults([]); return; }
    try {
      setGuardianSearchLoading(true);
      const orFilter = `first_name.ilike.%${q}%,last_name.ilike.%${q}%,run.ilike.%${q}%,email.ilike.%${q}%`;
      const { data, error } = await supabase
        .from('guardians')
        .select('id, first_name, last_name, run, email')
        .or(orFilter)
        .limit(10);
      if (error) throw error;
      setGuardianResults(data || []);
    } catch (e) {
      console.error('Guardian search error', e);
    } finally {
      setGuardianSearchLoading(false);
    }
  }, []);

  const handleGuardianModalSuccess = useCallback(() => {
    setGuardianModalOpen(false);
    if (guardianSearch.trim().length >= 2) {
      searchGuardians(guardianSearch);
    }
  }, [guardianSearch, searchGuardians]);

  // Load guardian & enrollment baseline
  useEffect(() => {
    if (!user) return;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        let g = guardian;
        if (assistedMode) {
          // In assisted mode, require selecting a guardian first
          if (!assistedGuardian) {
            setGuardian(null);
            setEnrollment(null);
            setLoading(false);
            return;
          }
          g = assistedGuardian;
        } else {
          console.log('🔍 MatriculaWizard: Loading guardian for user:', user.id);
          g = await fetchCurrentGuardian(user.id, user.email);
          console.log('🔍 MatriculaWizard: Guardian fetched:', g);
          if (!g) {
            setError('No se encontró registro de apoderado. Por favor contacte al administrador para crear su perfil.');
            toast.error('No se encontró registro de apoderado');
            setLoading(false);
            return;
          }
        }
        setGuardian(g);
        console.log('🔍 MatriculaWizard: Creating enrollment for guardian:', g.id, 'year:', year);
        const enr = await getOrCreateEnrollment(g.id, year);
        console.log('🔍 MatriculaWizard: Enrollment created/fetched:', enr);
        if (!enr) {
          setError('No se pudo crear la matrícula. Intente nuevamente.');
          toast.error('Error creando matrícula');
        } else {
          setEnrollment(enr);
          // Load outstanding debt once we have guardian & enrollment
          try {
            setDebtLoading(true);
            const debt = await getGuardianOutstandingDebt(g.id);
            if (debt) {
              setDebtInfo({ total: debt.total || 0, items: debt.items || [] });
            }
            // Check regularization docs (signed OR generated) para gating y estado
            try {
              const signed = await hasSignedRegularization(enr.id);
              if (signed) {
                setHasRegularized(true);
                setRegularizationSigned(true);
              } else {
                const { data: docsAny } = await supabase
                  .from('enrollment_documents')
                  .select('id, status')
                  .eq('enrollment_id', enr.id)
                  .in('type', ['PAGARE_DEUDA','PAGARE_REPACTACION'])
                  .in('status', ['generated']);
                const hasGen = Array.isArray(docsAny) && docsAny.length > 0;
                setHasRegularized(hasGen);
                setRegularizationSigned(false);
              }
            } catch {}
          } catch (e) {
            console.warn('Debt load error', e);
          } finally {
            setDebtLoading(false);
          }
        }
      } finally {
        setLoading(false);
        console.log('🔍 MatriculaWizard: Loading complete');
      }
    })();
  }, [user, year, assistedMode, assistedGuardian]);

  // Load enrolled students & potential students (simplified: all students joined to guardian via student_guardian)
  const reloadEnrollmentStudents = useCallback(async () => {
    if (!enrollment) return;
    const list = await listEnrollmentStudents(enrollment.id);
    setStudents(list);
  }, [enrollment]);

  useEffect(() => { reloadEnrollmentStudents(); }, [reloadEnrollmentStudents]);

  // Unifica actualización (por distintos usuarios): deuda + estado de regularización
  const refreshDebtAndRegularization = useCallback(async () => {
    if (!guardian || !enrollment) return;
    setRefreshingState(true);
    try {
      // Deuda
      try {
        setDebtLoading(true);
        const debt = await getGuardianOutstandingDebt(guardian.id);
        setDebtInfo({ total: debt?.total || 0, items: debt?.items || [] });
      } finally { setDebtLoading(false); }

      // Regularización (signed primero)
      try {
        const signed = await hasSignedRegularization(enrollment.id);
        if (signed) {
          setHasRegularized(true);
          setRegularizationSigned(true);
          return; // firmado tiene prioridad
        }
        const { data: docsAny } = await supabase
          .from('enrollment_documents')
          .select('id, status')
          .eq('enrollment_id', enrollment.id)
          .in('type', ['PAGARE_DEUDA','PAGARE_REPACTACION'])
          .in('status', ['generated']);
        const hasGen = Array.isArray(docsAny) && docsAny.length > 0;
        setHasRegularized(hasGen);
        setRegularizationSigned(false);
      } catch (e) {
        console.warn('refresh regularization error', e);
      }
    } finally {
      setRefreshingState(false);
    }
  }, [guardian?.id, enrollment?.id]);

  // Auto document generation effect (debounced)
  useEffect(() => {
    if (!enrollment || !guardian) return;
    const timer = setTimeout(async () => {
      try {
        setAutoDocSyncing(true);
        // Provide minimal debt context: use debtInfo.total if available
        const debtTotal = debtInfo?.total || 0;
        await ensureEnrollmentDocuments({
          enrollment,
          guardian,
          students,
          meta: enrollment.meta || {},
          debtTotal,
        });
      } catch (e) {
        console.warn('Auto-doc generation error', e);
      } finally {
        setAutoDocSyncing(false);
      }
    }, 550); // debounce ~550ms
    return () => clearTimeout(timer);
  }, [enrollment?.id, guardian?.id, students, enrollment?.meta, prioritario, descuentoPlanilla, paymentMethod, economic, debtInfo?.total]);

  // Record assisted mode auditing in enrollment meta
  useEffect(() => {
    if (!assistedMode) return;
    if (!enrollment || !assistedGuardian || !user) return;
    // Minimal, fire-and-forget; ignore errors for UX smoothness
    updateEnrollmentMeta(enrollment.id, {
      assisted_by_user_id: user.id,
      assisted_by_role: user.profile,
      assisted_by_name: user.email || null,
      assisted_at: new Date().toISOString(),
    });
  }, [assistedMode, enrollment?.id, assistedGuardian?.id, user?.id]);

  // Load economic data and payment methods from enrollment.meta
  useEffect(() => {
    if (!enrollment || !enrollment.meta) return;
    
    console.log('📊 Loading saved economic data from enrollment.meta:', enrollment.meta);
    
    // Load economic data
    setEconomic(prev => ({
      ...prev,
      monto_matricula: enrollment.meta.monto_matricula?.toString() || prev.monto_matricula,
      colegiatura_anual: enrollment.meta.colegiatura_anual?.toString() || prev.colegiatura_anual,
      cantidad_cuotas: enrollment.meta.cantidad_cuotas?.toString() || prev.cantidad_cuotas,
      monto_cuota: enrollment.meta.monto_cuota?.toString() || prev.monto_cuota,
      dia_vencimiento: enrollment.meta.dia_vencimiento?.toString() || prev.dia_vencimiento
    }));
    // Prioritario
    if (typeof enrollment.meta.prioritario === 'boolean') {
      setPrioritario(enrollment.meta.prioritario);
    }
    // Descuento (persistir porcentaje si se guardó antes en meta)
    if (typeof enrollment.meta.porcentaje_descuento === 'number') {
      setDescuentoInfo(d => ({
        ...d,
        porcentaje_descuento: enrollment.meta.porcentaje_descuento,
        monto_total_descuento: (() => {
          const total = (Number(enrollment.meta.colegiatura_anual)||0) * (enrollment.meta.porcentaje_descuento/100);
          return Math.round(total);
        })()
      }));
    }
    
    // Load payment methods
    setPaymentMethod(prev => ({
      ...prev,
      cheques: enrollment.meta.forma_pago_cheques ?? prev.cheques,
      transferencia: enrollment.meta.forma_pago_transferencia ?? prev.transferencia,
      efectivo: enrollment.meta.forma_pago_efectivo ?? prev.efectivo,
      tarjeta: enrollment.meta.forma_pago_tarjeta ?? prev.tarjeta,
      pagare: enrollment.meta.forma_pago_pagare ?? prev.pagare
    }));
    // load descuento por planilla desde meta si existe
    if (typeof enrollment.meta.forma_pago_descuento_planilla === 'boolean') {
      setDescuentoPlanilla(enrollment.meta.forma_pago_descuento_planilla);
    }
  }, [enrollment]);

  // Auto-calculate monto_cuota when colegiatura_anual or cantidad_cuotas change
  useEffect(() => {
    const colegiatura = parseFloat(economic.colegiatura_anual);
    const cuotas = parseInt(economic.cantidad_cuotas);
    
    if (!isNaN(colegiatura) && !isNaN(cuotas) && cuotas > 0 && colegiatura > 0) {
      const montoPorCuota = Math.round(colegiatura / cuotas);
      console.log('🧮 Auto-calculando monto_cuota:', { colegiatura, cuotas, montoPorCuota });
      setEconomic(prev => ({ ...prev, monto_cuota: montoPorCuota.toString() }));
    }
  }, [economic.colegiatura_anual, economic.cantidad_cuotas]);

  // Auto-calculate per-student monto_cuota and descuento when their fields change
  useEffect(() => {
    if (!studentEconomicMap || Object.keys(studentEconomicMap).length === 0) return;
    setStudentEconomicMap(prev => {
      const next = { ...prev };
      Object.entries(prev).forEach(([studentId, econ]) => {
        const colegiatura = parseFloat(econ.colegiatura_anual || '');
        const cuotas = parseInt(econ.cantidad_cuotas || '');
        let updated = { ...econ };

        if (!isNaN(colegiatura) && !isNaN(cuotas) && cuotas > 0 && colegiatura > 0) {
          const montoPorCuota = Math.round(colegiatura / cuotas);
          updated.monto_cuota = montoPorCuota.toString();
        }

        if (typeof updated.porcentaje_descuento === 'number') {
          const totalDesc = (Number(updated.colegiatura_anual) || 0) * (updated.porcentaje_descuento / 100);
          updated.monto_total_descuento = Math.round(totalDesc);
        }

        next[studentId] = updated;
      });
      return next;
    });
  }, [studentEconomicMap]);

  // Keep per-student economic defaults in sync when students in enrollment change
  useEffect(() => {
    if (!Array.isArray(students) || students.length === 0) return;
    setStudentEconomicMap(prev => {
      const next = { ...prev };
      students.forEach(st => {
        if (!st.id) return;
        if (!next[st.id]) {
          next[st.id] = {
            monto_matricula: economic.monto_matricula,
            colegiatura_anual: economic.colegiatura_anual,
            cantidad_cuotas: economic.cantidad_cuotas,
            monto_cuota: economic.monto_cuota,
            dia_vencimiento: economic.dia_vencimiento,
            porcentaje_descuento: descuentoInfo.porcentaje_descuento,
            monto_total_descuento: descuentoInfo.monto_total_descuento,
            curso_sugerido: null,
            year_academico: year
          };
        }
      });
      return next;
    });
  }, [students, economic, descuentoInfo]);

  // Auto-suggest course for matrícula per student using backend promotion logic
  useEffect(() => {
    if (!Array.isArray(students) || students.length === 0) return;
    if (!Array.isArray(availableYearCourses) || availableYearCourses.length === 0) return;

    const fetchPromotionSuggestions = async () => {
      const updates = {};

      for (const st of students) {
        if (!st?.id) continue;

        // Do not override if a course was already selected manually or from meta
        if (studentEconomicMap[st.id]?.curso_sugerido) continue;

        try {
          // Call backend RPC for promotion suggestion
          const { data, error } = await supabase
            .rpc('get_student_promotion_suggestion', { p_student_id: st.id });

          if (error) {
            console.warn(`Promotion suggestion error for student ${st.id}:`, error);
            continue;
          }

          if (data && data.length > 0) {
            const suggestion = data[0];
            let suggestedId = suggestion.suggested_course_id || null;
            const suggestedYear = suggestion.suggested_year || year;

            // If backend didn't provide a specific course, try to match current course in available list
            if (!suggestedId && suggestion.current_course_id) {
              const sameCourse = availableYearCourses.find(c => c.id === suggestion.current_course_id);
              if (sameCourse) {
                suggestedId = sameCourse.id;
              }
            }

            // Store suggestion with year
            if (suggestedId || suggestedYear) {
              updates[st.id] = {
                ...(studentEconomicMap[st.id] || {}),
                curso_sugerido: suggestedId || '',
                year_academico: suggestedYear
              };
            }
          }
        } catch (e) {
          console.error(`Error fetching promotion for student ${st.id}:`, e);
        }
      }

      if (Object.keys(updates).length > 0) {
        setStudentEconomicMap(prev => ({
          ...prev,
          ...updates
        }));
      }
    };

    fetchPromotionSuggestions();
  }, [students, availableYearCourses, year]);

  const loadAssociatedStudents = useCallback(async () => {
    if (!guardian) return;
    const { data, error } = await supabase
      .from('student_guardian')
      .select(`
        student_id,
        students:student_id (
          id,
          whole_name,
          run,
          curso,
          cursos:curso (
            nom_curso,
            nivel,
            letra_curso
          )
        )
      `)
      .eq('guardian_id', guardian.id);
    if (error) {
      console.error('loadAssociatedStudents error', error);
      return;
    }
    const list = (data || []).map(r => {
      const s = r.students || {};
      const c = s.cursos || null;
      const cursoLabel = c?.nom_curso
        || (c ? `${c.nivel ?? ''}${c.letra_curso ? ` ${c.letra_curso}` : ''}`.trim() : null)
        || s.curso
        || null;
      return {
        id: s.id,
        whole_name: s.whole_name,
        run: s.run,
        curso: s.curso || undefined,
        curso_nombre: cursoLabel || undefined
      };
    }).filter(st => Boolean(st.id));
    setAllMyStudents(list);
  }, [guardian]);

  useEffect(() => { loadAssociatedStudents(); }, [loadAssociatedStudents]);

  // Load courses for the selected year to populate "Curso para matricula" options
  useEffect(() => {
    const fetchCoursesForYear = async () => {
      try {
        const { data, error } = await supabase
          .from('cursos')
          .select('id, nom_curso, nivel, letra_curso, year_academico')
          .eq('year_academico', year)
          .order('nivel', { ascending: true });
        if (error) throw error;
        setAvailableYearCourses(data || []);
      } catch (e) {
        console.error('Error loading year courses for MatriculaWizard', e);
        setAvailableYearCourses([]);
      }
    };

    if (year) {
      fetchCoursesForYear();
    }
  }, [year]);

  const handleStudentModalSuccess = useCallback(() => {
    setStudentModalOpen(false);
    loadAssociatedStudents();
    reloadEnrollmentStudents();
  }, [loadAssociatedStudents, reloadEnrollmentStudents]);

  // Step navigation guards
  const canProceed = () => {
    if (step === 0) {
      // Bloquea sólo si hay deuda y NO existe documento de regularización (generated o signed)
      const debtBlocked = debtInfo.total > 0 && !hasRegularized && !debtDoc;
      return students.length > 0 && !debtBlocked;
    }
    if (step === 1) {
      // Si es prioritario, permitimos avanzar sin requerir completar estos valores
      if (prioritario) return true;
      return economic.colegiatura_anual && economic.cantidad_cuotas && economic.dia_vencimiento;
    }
    if (step === 2) return !!previewHtml; // must have preview generated
    return true;
  };

  const next = () => { if (step < STEPS.length - 1 && canProceed()) setStep(step + 1); else if (!canProceed()) toast.error('Completa los datos antes de continuar'); };
  const back = () => { if (step > 0) setStep(step - 1); };

  // Add/remove student handlers
  const handleAddStudent = async (studentId) => {
    if (!enrollment) return;
    await addStudentToEnrollment(enrollment.id, studentId);
    reloadEnrollmentStudents();
  };
  const handleRemoveStudent = async (studentId) => {
    if (!enrollment) return;
    await removeStudentFromEnrollment(enrollment.id, studentId);
    reloadEnrollmentStudents();
  };

  const updateStudentEconomicField = (studentId, field, value) => {
    setStudentEconomicMap(prev => ({
      ...prev,
      [studentId]: {
        ...(prev[studentId] || {}),
        [field]: value
      }
    }));
  };

  const updateStudentCourseForYear = (studentId, value) => {
    setStudentEconomicMap(prev => ({
      ...prev,
      [studentId]: {
        ...(prev[studentId] || {}),
        curso_sugerido: value
      }
    }));
  };

  const updateStudentYearForMatricula = (studentId, value) => {
    setStudentEconomicMap(prev => ({
      ...prev,
      [studentId]: {
        ...(prev[studentId] || {}),
        year_academico: Number(value) || year
      }
    }));
  };

  // Save economic info
  const handleSaveEconomic = async () => {
    if (!enrollment) return;
    
    const patch = {
      // Economic data
      monto_matricula: Number(economic.monto_matricula) || 0,
      colegiatura_anual: Number(economic.colegiatura_anual) || 0,
      cantidad_cuotas: Number(economic.cantidad_cuotas) || 0,
      monto_cuota: Number(economic.monto_cuota) || 0,
      dia_vencimiento: Number(economic.dia_vencimiento) || 0,
      // Payment methods
      forma_pago_cheques: paymentMethod.cheques || false,
      forma_pago_transferencia: paymentMethod.transferencia || false,
      forma_pago_efectivo: paymentMethod.efectivo || false,
      forma_pago_tarjeta: paymentMethod.tarjeta || false,
      forma_pago_pagare: paymentMethod.pagare || false,
      forma_pago_descuento_planilla: descuentoPlanilla || false,
      prioritario,
      porcentaje_descuento: descuentoInfo.porcentaje_descuento || 0,
      monto_total_descuento: descuentoInfo.monto_total_descuento || 0
    };
    if (studentEconomicMap && Object.keys(studentEconomicMap).length > 0) {
      patch.per_student_economic = studentEconomicMap;
    }
    if (paymentPlan) {
      patch.payment_plan = paymentPlan;
    }
    
    console.log('💾 Guardando datos económicos y formas de pago:', patch);
    const updated = await updateEnrollmentMeta(enrollment.id, patch);
    if (updated) {
      setEnrollment(prev => prev ? { ...prev, meta: { ...(prev.meta || {}), ...patch } } : prev);
    }
    
    // Auto-calculate monto_cuota if not provided
    if (!economic.monto_cuota && patch.colegiatura_anual && patch.cantidad_cuotas) {
      const calc = Math.round(patch.colegiatura_anual / patch.cantidad_cuotas);
      setEconomic(e => ({ ...e, monto_cuota: calc.toString() }));
    }
    
    toast.success('Datos económicos guardados correctamente');
  };

  // Generate pagaré HTML preview OR Autorización de Descuento (depending on descuentoPlanilla flag)
  const handleGeneratePagare = async () => {
    if (!guardian || !enrollment) {
      console.error('❌ Missing guardian or enrollment:', { guardian, enrollment });
      toast.error('Faltan datos del apoderado o matrícula');
      return;
    }
    
    setLoading(true);
    
    console.log('🎯 handleGeneratePagare started');
    console.log('👤 Guardian COMPLETO:', JSON.stringify(guardian, null, 2));
    console.log('👥 Students COMPLETO:', JSON.stringify(students, null, 2));
    console.log('💰 Economic data COMPLETO:', JSON.stringify(economic, null, 2));
    console.log('💳 Payment method COMPLETO:', JSON.stringify(paymentMethod, null, 2));
    console.log('🎁 Descuento planilla:', descuentoPlanilla);
    
    const econNumbers = {
      monto_matricula: Number(economic.monto_matricula) || undefined,
      colegiatura_anual: Number(economic.colegiatura_anual) || undefined,
      cantidad_cuotas: Number(economic.cantidad_cuotas) || undefined,
      monto_cuota: Number(economic.monto_cuota) || undefined,
      dia_vencimiento: Number(economic.dia_vencimiento) || undefined,
    };
    
    console.log('💵 Economic numbers parsed:', JSON.stringify(econNumbers, null, 2));
    
    // Always generate Contrato de Prestación + anexos según método de pago
    const prestacionPayload = buildPrestacionPayload({
      guardian,
      year,
      students,
      economic: econNumbers,
      paymentMethod,
      cheques,
      descuento: descuentoPlanilla ? {
        porcentaje: Number(descuentoInfo.porcentaje_descuento) || 0,
        motivo: descuentoInfo.motivo || '',
        condiciones: descuentoInfo.condiciones || ''
      } : null
    });

    // Provide a provisional folio number for templates that display it (e.g., Anexo Pagaré)
    try {
      const provisionalFolio = (enrollment?.id ? String(enrollment.id).slice(0, 8) : Date.now().toString().slice(-8)).toUpperCase();
      prestacionPayload.folio_number = provisionalFolio;
    } catch {}

  // Si es prioritario, no generar anexos aunque existan selecciones previas
  const annex = prioritario ? null : (descuentoPlanilla ? 'descuento' : (paymentMethod.pagare ? 'pagare' : null));
    const html = renderPrestacionWithAnnex(prestacionPayload, { annex });
    
    console.log('📄 HTML generated (length):', html.length);
    
    setPreviewHtml(html);
    
    // Create document record
    const contentHash = await sha256(html);
    const doc = await createPrestacionDocument({
      enrollmentId: enrollment.id,
      payload: prestacionPayload,
      finalContent: html,
      contentHash
    });
    
    setDocumentRecord(doc);
    // If cheques were selected and we have cheques data, persist them linked to document/folio
  if (paymentMethod?.cheques && Array.isArray(cheques) && cheques.length && doc?.id) {
      try {
        const folioNumber = doc.id.substring(0, 8).toUpperCase();
        await saveChequesForEnrollment({
          enrollmentId: enrollment.id,
          cheques: cheques.map((c, idx) => ({
            numero_cuota: c.numero_cuota ?? (idx + 1),
            numero_serie: c.numero_serie,
            banco: c.banco,
            fecha_emision: c.fecha_emision,
            monto: Number(c.monto) || 0,
            notas: c.notas || ''
          })),
          documentId: doc.id,
          folioNumber,
          createdBy: user?.id || null
        });
      } catch (e) {
        console.error('saveChequesForEnrollment error', e);
      }
    }

    setLoading(false);
    
    if (doc) {
      setStep(2);
      toast.success(`Vista previa del Contrato de Prestación generada. Revise el documento antes de descargar.`);
    }
  };

  // Download PDF - Generate on-the-fly from HTML
  const handleDownloadPDF = async () => {
    if (!previewHtml || !guardian) {
      toast.error('No hay documento para descargar');
      return;
    }
    
    try {
      toast.loading('Generando PDF...', { id: 'pdf-download' });
      
      // Generar número de folio (basado en ID del documento o timestamp)
      const folioNumber = documentRecord?.id 
        ? documentRecord.id.substring(0, 8).toUpperCase() 
        : Date.now().toString().slice(-8);
      
      // Generate PDF from HTML (client-side, no server upload)
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: previewHtml,
        includeHeader: true,
        includeSignatureSection: true,
        folioNumber: folioNumber, // Añadido número de folio
        guardianRun: guardian.run
        // watermark removida - ya no se usa por defecto
      });
      
      // Download directly
  downloadPDFBlob(pdfBlob, `Contrato_Prestacion_${year}_${guardian?.run || 'documento'}.pdf`);
      
      toast.success('PDF descargado exitosamente', { id: 'pdf-download' });
    } catch (err) {
      console.error('Download PDF error:', err);
      toast.error('Error al generar el PDF', { id: 'pdf-download' });
    }
  };

  // Print HTML preview
  const handlePrint = () => {
    if (!previewHtml) {
      toast.error('No hay documento para imprimir');
      return;
    }
    
    // Open print dialog with the HTML content
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Pagaré ${year}</title>
          <style>
            body { 
              font-family: Arial, sans-serif; 
              padding: 40px; 
              line-height: 1.6;
              max-width: 800px;
              margin: 0 auto;
            }
            h1, h2 { color: #333; }
            table { 
              width: 100%; 
              border-collapse: collapse; 
              margin: 20px 0;
            }
            th, td { 
              border: 1px solid #ddd; 
              padding: 8px; 
              text-align: left;
            }
            th { background-color: #f2f2f2; }
            @media print {
              body { padding: 20px; }
            }
          </style>
        </head>
        <body>
          ${previewHtml}
        </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.focus();
      setTimeout(() => printWindow.print(), 250);
    }
  };

  const computeFinalizeOptions = () => {
    if (!paymentPlan) {
      toast.error('Completa los datos económicos (monto anual, cuotas y día de vencimiento) antes de confirmar.');
      return null;
    }
    return {
      ...(assistedMode ? { skip_doc_checks: true } : {}),
      payment_plan: paymentPlan
    };
  };

  // Staff finalize: dry-run preview
  const handleFinalizePreview = async () => {
    if (!enrollment) return;
    const finalizeOptions = computeFinalizeOptions();
    if (!finalizeOptions) return;
    try {
      setFinalizing(true);
      setFinalizeAlert(null);
      const preview = await finalizeEnrollmentPreview(enrollment.id, finalizeOptions);
      if (preview && !preview.year) {
        preview.year = enrollment.year ?? year;
      }
      setFinalizePreview(preview);
      setFinalizeOpen(true);
    } catch (e) {
      // toast handled in service
    } finally {
      setFinalizing(false);
    }
  };

  // Staff finalize: confirm apply
  const handleFinalizeConfirm = async () => {
    if (!enrollment) return;
    const finalizeOptions = computeFinalizeOptions();
    if (!finalizeOptions) {
      setFinalizeAlert({ type: 'warning', message: 'Falta configurar el plan de pagos antes de confirmar.' });
      return;
    }
    try {
      setFinalizing(true);
      const result = await finalizeEnrollmentConfirm(enrollment.id, finalizeOptions);
      if (result && !result.year) {
        result.year = enrollment.year ?? year;
      }
      const studentsCount = Number(result?.students_count ?? students.length ?? 0);
      const createdCharges = Number(result?.created_charges ?? 0);
      const skippedDuplicates = Number(result?.skipped_duplicates ?? 0);
      const alertType = skippedDuplicates > 0 ? 'warning' : 'success';
      const baseMessage = `Matrícula confirmada para ${studentsCount} estudiante${studentsCount === 1 ? '' : 's'}.`;
      const detailMessage = ` Se generaron ${createdCharges} cargo${createdCharges === 1 ? '' : 's'}${skippedDuplicates ? `; ${skippedDuplicates} ya existían y no se duplicaron.` : '.'}`;
      const followUp = ' Recuerda actualizar el estado a Matriculado (valor ACTIVO) o Retirado en el módulo de Estudiantes una vez recibida la documentación física.';
      setFinalizeAlert({ type: alertType, message: `${baseMessage}${detailMessage}${followUp}` });
      toast.success(`Matrícula confirmada (${createdCharges} cargo${createdCharges === 1 ? '' : 's'} nuevos${skippedDuplicates ? `, ${skippedDuplicates} duplicado${skippedDuplicates === 1 ? '' : 's'} omitido${skippedDuplicates === 1 ? '' : 's'}` : ''}).`);
      setFinalizeOpen(false);
      setFinalizePreview(null);
      await reloadEnrollmentStudents();
      await refreshDebtAndRegularization();
      if (guardian) {
        const latest = await getOrCreateEnrollment(guardian.id, year);
        if (latest) {
          setEnrollment(latest);
        } else {
          setEnrollment(prev => (prev ? { ...prev, status: 'completed' } : prev));
        }
      } else {
        setEnrollment(prev => (prev ? { ...prev, status: 'completed' } : prev));
      }
    } catch (e) {
      // toast handled in service
      const message = e?.message || 'No se pudo confirmar la matrícula. Revisa documentos o plan de pago.';
      setFinalizeAlert({ type: 'warning', message });
    } finally {
      setFinalizing(false);
    }
  };

  // Email pagare as PDF attachment to guardian
  const handleSendPagareEmail = async () => {
    if (!previewHtml || !guardian) {
      toast.error('No hay documento para enviar');
      return;
    }
    if (!guardian.email) {
      toast.error('El apoderado no tiene email registrado');
      return;
    }
    try {
      setSendingPagare(true);
      toast.loading('Generando y enviando Pagaré...', { id: 'pagare-send' });
      
      // Generar número de folio
      const folioNumber = documentRecord?.id 
        ? documentRecord.id.substring(0, 8).toUpperCase() 
        : Date.now().toString().slice(-8);
      
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: previewHtml,
        includeHeader: true,
        includeSignatureSection: true,
        folioNumber: folioNumber, // Añadido número de folio
        guardianRun: guardian.run
        // watermark removida
      });
  const base64 = await blobToBase64(pdfBlob);
  const filename = `Contrato_Prestacion_${year}_${guardian?.run || 'documento'}.pdf`;
      const subject = `Contrato de Prestación Matrícula ${year} - Winterhill`;
      const html = `<p>Estimado(a) ${guardian.first_name} ${guardian.last_name},</p>
        <p>Adjuntamos el Contrato de Prestación (y anexos, si corresponden) para la matrícula ${year}. Por favor, revise el documento y conserve una copia para sus registros.</p>
        <p>Saludos cordiales,<br/>Corporación Educacional Winterhill</p>`;
      await sendEmailViaFunction({
        to: guardian.email,
        subject,
        html,
        type: 'prestacion',
        related_id: documentRecord?.id || undefined,
        attachments: [{ filename, content: base64, type: 'application/pdf' }],
      });
      toast.success('Contrato de Prestación enviado por correo', { id: 'pagare-send' });
    } catch (err) {
      console.error('Enviar pagaré error:', err);
      const msg = err?.message || 'No se pudo enviar el pagaré';
      toast.error(msg, { id: 'pagare-send' });
    } finally {
      setSendingPagare(false);
    }
  };

  // Sign document
  const handleSign = async () => {
    if (!documentRecord) return;
    setLoading(true);
    const ok = await signEnrollmentDocument(documentRecord.id, 'checkbox', user?.id);
    setLoading(false);
    if (ok) {
  toast.success('Contrato firmado');
    }
  };

  return (
    <main className="flex-1 min-w-0 p-4 space-y-4 animate-fade-in">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Matrícula {year}</h1>
      <p className="text-sm text-gray-600 dark:text-gray-400">Asistente básico de matrícula y generación de Pagaré (versión inicial).</p>

      {/* Assisted mode selector for ADMIN/ASIST */}
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
            {!assistedGuardian ? (
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={guardianSearch}
                    onChange={(e) => {
                      const q = e.target.value;
                      setGuardianSearch(q);
                      // Debounce-lite: search after short delay
                      setTimeout(() => searchGuardians(q), 250);
                    }}
                    placeholder="Buscar por nombre, RUN o email..."
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <Button onClick={() => searchGuardians(guardianSearch)} disabled={guardianSearchLoading}>
                    {guardianSearchLoading ? 'Buscando...' : 'Buscar'}
                  </Button>
                </div>
                <div className="max-h-64 overflow-y-auto divide-y divide-gray-100 dark:divide-gray-800 rounded-lg border border-gray-100 dark:border-gray-800">
                  {(guardianResults || []).map((g) => (
                    <button
                      key={g.id}
                      onClick={() => setAssistedGuardian(g)}
                      className="w-full text-left px-4 py-3 hover:bg-gray-50 dark:hover:bg-dark-hover"
                    >
                      <div className="font-medium text-gray-900 dark:text-white">{g.first_name} {g.last_name}</div>
                      <div className="text-xs text-gray-500">RUN: {g.run || '—'} · {g.email || 'sin email'}</div>
                    </button>
                  ))}
                  {!guardianResults?.length && (
                    <div className="px-4 py-6 text-sm text-gray-500">Sin resultados. Ingresa al menos 2 caracteres.</div>
                  )}
                </div>
                <div className="p-4 rounded-lg border border-dashed border-gray-200 dark:border-gray-700 bg-white/70 dark:bg-dark/40">
                  <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">¿No encuentras al apoderado? Regístralo y abre la Encuesta de Ingreso para iniciar la matrícula.</p>
                  <Button size="sm" variant="outline" onClick={() => setGuardianModalOpen(true)}>
                    ➕ Nuevo apoderado
                  </Button>
                </div>
              </div>
            ) : (
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-sm text-gray-600 dark:text-gray-300">Operando en nombre de:</div>
                  <div className="text-base font-medium text-gray-900 dark:text-white">{assistedGuardian.first_name} {assistedGuardian.last_name} · RUN: {assistedGuardian.run || '—'}</div>
                </div>
                <Button variant="secondary" onClick={() => { setAssistedGuardian(null); setGuardian(null); setEnrollment(null); }}>Cambiar apoderado</Button>
              </div>
            )}
          </CardContent>
        </Card>
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
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-gray-600 dark:text-gray-400">Cargando información...</p>
          </CardContent>
        </Card>
      )}

      {/* Show wizard only if no error and guardian exists */}
      {!error && guardian && (
        <>
          <div className="flex gap-2 flex-wrap">
            {STEPS.map((s, idx) => (
              <span key={s} className={`px-3 py-1 rounded text-xs font-medium ${idx === step ? 'bg-primary text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'}`}>{idx + 1}. {s}</span>
            ))}
          </div>

          {/* Debt gating banner */}
          {debtInfo.total > 0 && !hasRegularized && !debtDoc && (
            <div className="mt-4 p-4 rounded-lg border border-red-300 bg-red-50 dark:bg-red-900/30 dark:border-red-700">
              <div className="flex items-start gap-3">
                <span className="text-xl">🛑</span>
                <div className="flex-1">
                  <h3 className="font-semibold text-red-800 dark:text-red-200 text-sm mb-1">Deuda Pendiente Detectada</h3>
                  <p className="text-xs text-red-700 dark:text-red-300 mb-2">Antes de continuar con la matrícula, debe regularizar la deuda. Puede generar un <strong>Pagaré de Deuda</strong> simple o hacerlo mediante el módulo de <strong>Repactación</strong>.</p>
                  <p className="text-sm font-medium text-red-900 dark:text-red-100">Total deuda: $ {debtInfo.total.toLocaleString('es-CL')}</p>
                  <div className="mt-3 flex gap-2 flex-wrap">
                    <Button size="sm" variant="destructive" onClick={() => setShowDebtGenerator(true)}>Generar Pagaré de Deuda</Button>
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
                    <Button size="sm" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>{refreshingState ? 'Actualizando…' : '↻ Actualizar estado'}</Button>
                  </div>
                  {debtLoading && <p className="text-xs mt-2 text-red-600">Verificando deuda...</p>}
                </div>
              </div>
            </div>
          )}
          {/* Advertencia informativa si hay regularización generada pero no firmada */}
          {debtInfo.total > 0 && hasRegularized && !regularizationSigned && (
            <div className="mt-4 p-4 rounded-lg border border-yellow-300 bg-yellow-50 dark:bg-yellow-900/30 dark:border-yellow-700">
              <div className="flex items-start gap-3">
                <span className="text-xl">⚠️</span>
                <div className="flex-1">
                  <h3 className="font-semibold text-yellow-800 dark:text-yellow-200 text-sm mb-1">Documento de Regularización Pendiente de Firma</h3>
                  <p className="text-xs text-yellow-700 dark:text-yellow-300 mb-2">Se generó un pagaré de deuda o repactación pero aún no está firmado. Puede continuar con la matrícula; recuerde obtener la firma.</p>
                  <div className="flex gap-2 flex-wrap mt-2">
                    <Button size="xs" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>{refreshingState ? 'Verificando…' : '↻ Actualizar estado'}</Button>
                  </div>
                </div>
              </div>
            </div>
          )}
          {/* Indicador firmado */}
          {debtInfo.total > 0 && regularizationSigned && (
            <div className="mt-4 p-3 rounded-lg border border-green-300 bg-green-50 dark:bg-green-900/30 dark:border-green-700 text-xs text-green-800 dark:text-green-200 flex items-center justify-between">
              <span>✓ Documento de regularización firmado. Deuda formalizada.</span>
              <Button size="xs" variant="outline" onClick={refreshDebtAndRegularization} disabled={refreshingState}>{refreshingState ? 'Refrescando…' : '↻ Actualizar estado'}</Button>
            </div>
          )}

          {/* Debt generator modal-lite */}
          {showDebtGenerator && (
            <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
              <div className="bg-white dark:bg-dark rounded-lg shadow-lg w-full max-w-lg p-6 space-y-4">
                <h3 className="text-lg font-semibold">Generar Pagaré de Deuda</h3>
                <p className="text-xs text-gray-600 dark:text-gray-300">Configure el número de cuotas para regularizar la deuda. El monto de cada cuota se calculará automáticamente.</p>
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
                    <label className="block text-xs mb-1 font-medium">Día Vencimiento (1-28)</label>
                    <input type="number" min={1} max={28} value={debtForm.dia_vencimiento} onChange={e => setDebtForm(df => ({ ...df, dia_vencimiento: Number(e.target.value) }))} className="w-full border rounded px-2 py-1" />
                  </div>
                  <div>
                    <label className="block text-xs mb-1 font-medium">Monto por Cuota (CLP)</label>
                    <input type="text" readOnly value={Math.round(debtInfo.total / Math.max(1, debtForm.cuotas)).toLocaleString('es-CL')} className="w-full border rounded px-2 py-1 bg-gray-100" />
                  </div>
                </div>
                <div className="flex justify-end gap-2">
                  <Button variant="outline" size="sm" onClick={() => setShowDebtGenerator(false)}>Cancelar</Button>
                  <Button size="sm" onClick={async () => {
                    if (!guardian) return;
                    try {
                      toast.loading('Generando pagaré de deuda...', { id: 'debt-gen' });
                      const payload = buildPagareDeudaPayload({ guardian, year, students, debt: { total: debtInfo.total, cuotas: debtForm.cuotas, dia_vencimiento: debtForm.dia_vencimiento } });
                      // provisional folio
                      payload.folio_number = (enrollment?.id ? String(enrollment.id).slice(0, 8) : Date.now().toString().slice(-8)).toUpperCase();
                      const html = renderPagareDeuda(payload);
                      const hash = await sha256(html);
                      const doc = await createDebtPagareDocument({ enrollmentId: enrollment.id, payload, finalContent: html, contentHash: hash });
                       if (doc) {
                         setDebtDoc(doc);
                         setHasRegularized(true);
                         setRegularizationSigned(false);
                        toast.success('Pagaré de deuda generado');
                        setShowDebtGenerator(false);
                      }
                    } catch (e) {
                      console.error('Debt pagare generation error', e);
                      toast.error('Error generando pagaré de deuda', { id: 'debt-gen' });
                    } finally {
                      toast.dismiss('debt-gen');
                    }
                  }}>Generar</Button>
                </div>
              </div>
            </div>
          )}

      {/* STEP 0 */}
      {step === 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">Seleccionar Alumno y  </h2>
              <div className="flex items-center gap-2">
                <label className="text-sm"> Año:</label>
                <input type="number" value={year} onChange={e => setYear(Number(e.target.value))} className="w-28 px-2 py-1 border rounded" />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h3 className="font-medium mb-2 text-sm">Mis Alumnos Asociados</h3>
                {assistedMode && allMyStudents.length === 0 && (
                  <div className="mb-3 rounded-lg border border-yellow-200 dark:border-yellow-700 bg-yellow-50 dark:bg-yellow-900/30 p-3 text-xs text-yellow-800 dark:text-yellow-200">
                    <p className="mb-2">Aún no existen estudiantes vinculados a este apoderado. Regístralos para continuar con la matrícula asistida.</p>
                    <Button
                      size="xs"
                      variant="outline"
                      onClick={() => setStudentModalOpen(true)}
                      disabled={!guardian?.id}
                    >
                      Registrar estudiante
                    </Button>
                  </div>
                )}
                <ul className="space-y-1 max-h-72 overflow-auto text-sm">
                  {allMyStudents.map(st => {
                    const cursoLabel = st.curso_nombre || st.curso || null;
                    const subtitleParts = [];
                    if (st.run && st.whole_name !== st.run) subtitleParts.push(st.run);
                    if (cursoLabel) subtitleParts.push(cursoLabel);
                    return (
                      <li key={st.id} className="flex items-center justify-between gap-2 bg-gray-50 dark:bg-dark/40 px-2 py-1 rounded">
                        <div className="flex flex-col flex-1 min-w-0">
                          <span className="font-medium truncate">{st.whole_name || st.run}</span>
                          {subtitleParts.length > 0 && (
                            <span className="text-[11px] text-gray-500 truncate">
                              {subtitleParts.join(' | ')}
                            </span>
                          )}
                        </div>
                        <Button variant="outline" size="xs" onClick={() => handleAddStudent(st.id)}>Agregar</Button>
                      </li>
                    );
                  })}
                  {allMyStudents.length === 0 && <li className="text-gray-500">No hay alumnos asociados</li>}
                </ul>
              </div>
              <div>
                <h3 className="font-medium mb-2 text-sm">Alumnos en la Matrícula</h3>
                <ul className="space-y-1 max-h-72 overflow-auto text-sm">
                  {students.map(st => {
                    const cursoLabel = st.curso_nombre || st.curso || null;
                    const subtitleParts = [];
                    if (st.run && st.whole_name !== st.run) subtitleParts.push(st.run);
                    if (cursoLabel) subtitleParts.push(cursoLabel);
                    return (
                      <li key={st.id} className="flex items-center justify-between gap-2 bg-primary/5 dark:bg-primary/10 px-2 py-1 rounded">
                        <div className="flex flex-col flex-1 min-w-0">
                          <span className="font-medium truncate">{st.whole_name || st.run}</span>
                          {subtitleParts.length > 0 && (
                            <span className="text-[11px] text-gray-600 dark:text-gray-300 truncate">
                              {subtitleParts.join(' | ')}
                            </span>
                          )}
                        </div>
                        <Button variant="destructive" size="xs" onClick={() => handleRemoveStudent(st.id)}>Quitar</Button>
                      </li>
                    );
                  })}
                  {students.length === 0 && <li className="text-gray-500">Aún no agregas alumnos</li>}
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* STEP 1: Economic Data */}
      {step === 1 && (
        <Card>
          <CardHeader>
            <h2 className="font-semibold">Datos Económicos y Forma de Pago</h2>
          </CardHeader>
          <CardContent className="space-y-6 text-sm">
            {/* Per-student Economic Data */}
            {students.length > 0 && (
              <div className="space-y-4">
                <h3 className="font-medium text-sm text-gray-700 dark:text-gray-300">💰 Información por Estudiante</h3>
                <div className="space-y-3 max-h-96 overflow-auto pr-1">
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
                        </div>
                        <div className="grid md:grid-cols-3 gap-3 text-xs">
                          <div>
                            <label className="block mb-1 font-medium">Monto Matrícula (CLP)</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1"
                              value={econ.monto_matricula || ''}
                              onChange={e => updateStudentEconomicField(st.id, 'monto_matricula', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Colegiatura Anual (CLP)</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1"
                              value={econ.colegiatura_anual || ''}
                              onChange={e => updateStudentEconomicField(st.id, 'colegiatura_anual', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Cantidad Cuotas</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1"
                              value={econ.cantidad_cuotas || ''}
                              onChange={e => updateStudentEconomicField(st.id, 'cantidad_cuotas', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Monto por Cuota (CLP)</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1 bg-gray-100"
                              value={econ.monto_cuota || ''}
                              readOnly
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Día Vencimiento (1-28)</label>
                            <input
                              type="number"
                              min="1"
                              max="28"
                              className="w-full border rounded px-2 py-1"
                              value={econ.dia_vencimiento || ''}
                              onChange={e => updateStudentEconomicField(st.id, 'dia_vencimiento', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Porcentaje de Descuento (%)</label>
                            <input
                              type="number"
                              min="0"
                              max="100"
                              className="w-full border rounded px-2 py-1"
                              value={econ.porcentaje_descuento ?? 0}
                              onChange={e => updateStudentEconomicField(st.id, 'porcentaje_descuento', Number(e.target.value))}
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Monto Total Descuento (CLP)</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1 bg-gray-100"
                              value={econ.monto_total_descuento ?? 0}
                              readOnly
                            />
                          </div>
                          <div>
                            <label className="block mb-1 font-medium">Año Académico</label>
                            <input
                              type="number"
                              className="w-full border rounded px-2 py-1"
                              value={econ.year_academico || year}
                              onChange={e => updateStudentYearForMatricula(st.id, e.target.value)}
                              min={year - 1}
                              max={year + 1}
                              placeholder={`Año: ${year}`}
                            />
                          </div>
                          <div className="md:col-span-2">
                            <label className="block mb-1 font-medium">Curso para matrícula (año {econ.year_academico || year})</label>
                            <select
                              className="w-full border rounded px-2 py-1 bg-white dark:bg-dark-hover"
                              value={econ.curso_sugerido || ''}
                              onChange={e => updateStudentCourseForYear(st.id, e.target.value)}
                            >
                              <option value="">Seleccionar curso para este año</option>
                              {availableYearCourses.map(curso => {
                                const label = curso.nom_curso || `${curso.nivel ?? ''}${curso.letra_curso ? ` ${curso.letra_curso}` : ''}`.trim() || 'Sin nombre';
                                return (
                                  <option key={curso.id} value={curso.id}>
                                    {label}
                                  </option>
                                );
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

            {/* Economic Data Section */}
            <div>
              <h3 className="font-medium text-base mb-3 text-gray-700 dark:text-gray-300 flex items-center justify-between">💰 Información Económica
                <label className="flex items-center gap-2 text-xs font-normal ml-4 cursor-pointer">
                  <input type="checkbox" className="w-4 h-4" checked={prioritario} onChange={e => setPrioritario(e.target.checked)} />
                  <span className="font-medium text-red-600">Prioritario</span>
                </label>
              </h3>
              <div className="grid md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs mb-1 font-medium">Monto Matrícula (CLP)</label>
                  <input 
                    type="number" 
                    className="w-full border rounded px-2 py-1" 
                    value={economic.monto_matricula} 
                    onChange={e => setEconomic({ ...economic, monto_matricula: e.target.value })} 
                    disabled={prioritario}
                    placeholder="Ej: 150000"
                  />
                </div>
                <div>
                  <label className="block text-xs mb-1 font-medium">Colegiatura Anual (CLP)</label>
                  <input 
                    type="number" 
                    className="w-full border rounded px-2 py-1" 
                    value={economic.colegiatura_anual} 
                    onChange={e => setEconomic({ ...economic, colegiatura_anual: e.target.value })} 
                    disabled={prioritario}
                    placeholder="Ej: 3600000"
                  />
                </div>
                <div>
                  <label className="block text-xs mb-1 font-medium">Cantidad Cuotas</label>
                  <input 
                    type="number" 
                    className="w-full border rounded px-2 py-1" 
                    value={economic.cantidad_cuotas} 
                    onChange={e => setEconomic({ ...economic, cantidad_cuotas: e.target.value })} 
                    disabled={prioritario}
                    placeholder="Ej: 10"
                  />
                </div>
                <div>
                  <label className="block text-xs mb-1 font-medium">Monto por Cuota (CLP) - Auto-calculado</label>
                  <input 
                    type="number" 
                    className="w-full border rounded px-2 py-1 bg-gray-100" 
                    value={economic.monto_cuota} 
                    readOnly
                    placeholder="Se calcula automáticamente"
                  />
                </div>
                <div>
                  <label className="block text-xs mb-1 font-medium">Día Vencimiento (1-28)</label>
                  <input 
                    type="number" 
                    min="1" 
                    max="28" 
                    className="w-full border rounded px-2 py-1" 
                    value={economic.dia_vencimiento} 
                    onChange={e => setEconomic({ ...economic, dia_vencimiento: e.target.value })} 
                    disabled={prioritario}
                    placeholder="Ej: 5"
                  />
                </div>
                {/* Nuevo: Porcentaje de Descuento movido aquí */}
                <div>
                  <label className="block text-xs mb-1 font-medium">Porcentaje de Descuento (%)</label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    className="w-full border rounded px-2 py-1"
                    value={descuentoInfo.porcentaje_descuento}
                    disabled={prioritario}
                    onChange={e => {
                      const pct = Number(e.target.value);
                      const total = (Number(economic.colegiatura_anual) || 0) * (pct / 100);
                      setDescuentoInfo({
                        ...descuentoInfo,
                        porcentaje_descuento: pct,
                        monto_total_descuento: Math.round(total)
                      });
                    }}
                    placeholder="Ej: 20"
                  />
                </div>
                <div>
                  <label className="block text-xs mb-1 font-medium">Monto Total Descuento (CLP)</label>
                  <input
                    type="number"
                    className="w-full border rounded px-2 py-1 bg-gray-100"
                    value={descuentoInfo.monto_total_descuento}
                    readOnly
                    placeholder="Auto"
                  />
                </div>
              </div>
              {prioritario && (
                <p className="text-xs mt-2 text-red-600">⚠️ Prioritario: valores bloqueados; no se aplican métodos de pago ni anexos.</p>
              )}
            </div>

            {/* Payment Method Section */}
            <div className="border-t pt-4">
              <h3 className="font-medium text-base mb-3 text-gray-700 dark:text-gray-300">💳 Forma de Pago</h3>
              <p className="text-xs text-gray-600 dark:text-gray-400 mb-3">Seleccione uno o más métodos de pago:</p>
              <div className="grid md:grid-cols-2 gap-3">
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.cheques} 
                    disabled={prioritario}
                    onChange={e => {
                      setPaymentMethod({ ...paymentMethod, cheques: e.target.checked });
                      if (e.target.checked) {
                        setShowChequesModal(true);
                      }
                    }} 
                    className="w-4 h-4"
                  />
                  <span>📝 Cheques</span>
                </label>
                {paymentMethod.cheques && (
                  <Button 
                    variant="outline" 
                    size="sm" 
                    onClick={() => setShowChequesModal(true)}
                    className="col-span-2"
                    disabled={prioritario}
                  >
                    {cheques && cheques.length ? '✏️ Editar Cheques' : '➕ Agregar Cheques'}
                  </Button>
                )}
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.transferencia} 
                    disabled={prioritario}
                    onChange={e => setPaymentMethod({ ...paymentMethod, transferencia: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💸 Transferencia Electrónica</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.efectivo} 
                    disabled={prioritario}
                    onChange={e => setPaymentMethod({ ...paymentMethod, efectivo: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💵 Pago en Efectivo</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.tarjeta} 
                    disabled={prioritario}
                    onChange={e => setPaymentMethod({ ...paymentMethod, tarjeta: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💳 Tarjeta de Crédito</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.pagare} 
                    disabled={prioritario}
                    onChange={e => setPaymentMethod({ ...paymentMethod, pagare: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>📜 Pagaré</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 md:col-span-2">
                  <input
                    type="checkbox"
                    className="w-4 h-4"
                    checked={descuentoPlanilla}
                    disabled={prioritario}
                    onChange={e => setDescuentoPlanilla(e.target.checked)}
                  />
                  <span>🎁 Descuento por Planilla</span>
                </label>
              </div>
              {descuentoPlanilla && !prioritario && (
                <div className="mt-4 p-4 bg-yellow-50 dark:bg-yellow-900/10 border border-yellow-200 dark:border-yellow-800 rounded-lg space-y-3">
                  <p className="text-xs text-yellow-800 dark:text-yellow-200 mb-3">ℹ️ Se generará una <strong>Autorización de Descuento</strong> en lugar de un Pagaré.</p>
                  <div className="grid md:grid-cols-2 gap-3">
                    <div className="md:col-span-2">
                      <label className="block text-xs mb-1 font-medium">Motivo del Descuento</label>
                      <input
                        type="text"
                        className="w-full border rounded px-2 py-1"
                        value={descuentoInfo.motivo}
                        onChange={e => setDescuentoInfo({ ...descuentoInfo, motivo: e.target.value })}
                        placeholder="Ej: Beneficio laboral"
                      />
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-xs mb-1 font-medium">Condiciones</label>
                      <textarea
                        className="w-full border rounded px-2 py-1"
                        rows="2"
                        value={descuentoInfo.condiciones}
                        onChange={e => setDescuentoInfo({ ...descuentoInfo, condiciones: e.target.value })}
                        placeholder="Ej: Descuento aplicable mientras se mantenga relación laboral"
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>

            <Button onClick={handleSaveEconomic} className="mt-4">💾 Guardar Datos</Button>
          </CardContent>
        </Card>
      )}

      {/* STEP 2: Preview Pagaré or Autorización and Generate PDF */}
      {step === 2 && (
        <Card>
          <CardHeader className="flex items-center justify-between">
            <h2 className="font-semibold">Vista Previa del Contrato de Prestación y Anexos</h2>
            <div className="flex gap-2 items-center">
              {documentRecord && (
                <span className="text-xs px-2 py-1 rounded bg-green-600 text-white">✓ Documento Generado</span>
              )}
              {documentRecord?.status === 'signed' && (
                <span className="text-xs px-2 py-1 rounded bg-blue-600 text-white">✓ Firmado</span>
              )}
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {!previewHtml && !loading && (
              <div className="text-center py-8">
                <p className="text-gray-600 dark:text-gray-400 mb-4">
                  Haga clic en "Generar Vista Previa" para crear el documento.
                </p>
                <Button onClick={handleGeneratePagare} disabled={loading || students.length === 0}>📄 Generar Vista Previa</Button>
                {students.length === 0 && (
                  <p className="text-sm text-red-600 dark:text-red-400 mt-2">
                    Debe agregar al menos un alumno en el paso anterior
                  </p>
                )}
              </div>
            )}
            
            {previewHtml && (
              <>
                {/* HTML Preview */}
                <div className="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-lg p-1">
                  <div className="border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 shadow-lg">
                    <HtmlIframePreview html={previewHtml} height={600} />
                  </div>
                </div>

                {finalizeAlert && (
                  <div
                    className={`p-3 rounded border text-sm ${
                      finalizeAlert.type === 'success'
                        ? 'border-green-300 bg-green-50 text-green-800 dark:bg-green-900/20 dark:border-green-700 dark:text-green-100'
                        : 'border-amber-300 bg-amber-50 text-amber-800 dark:bg-amber-900/20 dark:border-amber-700 dark:text-amber-100'
                    }`}
                  >
                    {finalizeAlert.message}
                  </div>
                )}

                {/* Action Buttons */}
                <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                  <h3 className="text-sm font-semibold mb-2 text-blue-900 dark:text-blue-100">
                    📋 Acciones del Documento
                  </h3>
                  <p className="text-xs text-blue-700 dark:text-blue-300 mb-4">
                    Revise el contenido del documento. Puede descargarlo como PDF o imprimirlo directamente.
                  </p>
                  <div className="flex gap-3 flex-wrap">
                    <Button 
                      variant="default" 
                      onClick={handleDownloadPDF}
                      disabled={loading}
                      className="bg-blue-600 hover:bg-blue-700 text-white"
                    >
                      📥 Descargar PDF
                    </Button>
                    <Button 
                      variant="outline" 
                      onClick={handlePrint}
                      disabled={loading}
                    >
                      🖨️ Imprimir
                    </Button>
                    <Button
                      variant="outline"
                      onClick={handleSendPagareEmail}
                      disabled={loading || sendingPagare || !guardian?.email}
                      title={!guardian?.email ? 'Apoderado sin email' : ''}
                    >
                      {sendingPagare ? 'Enviando…' : 'Enviar por correo'}
                    </Button>
                    <Button 
                      variant="outline" 
                      onClick={() => { setStep(1); setPreviewHtml(''); setDocumentRecord(null); setFinalizeAlert(null); }}
                      disabled={loading}
                    >
                      ✏️ Editar Datos
                    </Button>
                    {assistedMode && (
                      <Button
                        onClick={handleFinalizePreview}
                        disabled={finalizing || students.length === 0}
                        className="ml-auto bg-primary text-white"
                      >
                        {finalizing ? 'Preparando…' : 'Confirmar matrícula'}
                      </Button>
                    )}
                  </div>
                  {assistedMode && (
                    <p className="text-[11px] text-gray-600 dark:text-gray-400 mt-2">Este paso deja a los estudiantes en estado Pendiente (valor MATRICULADO) hasta que el equipo marque Matriculado (valor ACTIVO) o Retirado desde el módulo de Estudiantes.</p>
                  )}
                  <div className="mt-4 pt-4 border-t border-blue-200 dark:border-blue-700">
                    <p className="text-xs text-blue-600 dark:text-blue-400">
                      💡 <strong>Importante:</strong> El PDF se genera con formato profesional incluyendo:
                    </p>
                    <ul className="text-xs text-blue-600 dark:text-blue-400 mt-2 ml-4 space-y-1">
                      <li>✓ Logo y datos del colegio</li>
                      <li>✓ Secciones con bordes profesionales</li>
                      <li>✓ Áreas de firma para apoderado y corporación</li>
                      <li>✓ Anexos según forma de pago (Descuento por Planilla / Pagaré)</li>
                    </ul>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}

      {/* Navigation */}
      {!error && guardian && (
        <div className="flex justify-between pt-2">
          <Button variant="outline" onClick={back} disabled={step === 0 || loading}>Atrás</Button>
          {step < 2 && (
            <Button
              onClick={next}
              disabled={!canProceed() || loading || (debtInfo.total > 0 && !hasRegularized && !debtDoc)}
            >
              {debtInfo.total > 0 && !hasRegularized && !debtDoc ? 'Regularice la Deuda' : 'Siguiente'}
            </Button>
          )}
        </div>
      )}
        </>
      )}

      {/* Cheques Data Modal */}
      <ChequesDataModal
        isOpen={showChequesModal}
        onClose={() => setShowChequesModal(false)}
        onSave={(rows) => {
          setCheques(rows);
          toast.success('Cheques guardados');
        }}
        initialData={cheques}
        cantidadCuotas={Number(economic.cantidad_cuotas) || 1}
        montoCuota={Number(economic.monto_cuota) || 0}
      />

      {/* Finalize Enrollment Modal (staff) */}
      <FinalizeEnrollmentModal
        isOpen={finalizeOpen}
        onClose={() => { if (!finalizing) setFinalizeOpen(false); }}
        onConfirm={handleFinalizeConfirm}
        preview={finalizePreview}
        confirming={finalizing}
        students={students}
        enrollmentYear={enrollment?.year ?? year}
      />

      <GuardianFormModal
        isOpen={guardianModalOpen}
        onClose={() => setGuardianModalOpen(false)}
        onSuccess={handleGuardianModalSuccess}
        guardian={null}
      />

      <StudentFormModal
        isOpen={studentModalOpen}
        onClose={() => setStudentModalOpen(false)}
        student={null}
        onSuccess={handleStudentModalSuccess}
      />
    </main>
  );
}

export default MatriculaWizard;
