import { useState, useEffect, useCallback, useMemo } from 'react';
import { supabase } from '../../services/supabase';
import { useCursosQuery } from '../queries/useCursosQuery';
import {
  fetchCurrentGuardian,
  getOrCreateEnrollment,
  listEnrollmentStudents,
  addStudentToEnrollment,
  removeStudentFromEnrollment,
  updateEnrollmentMeta,
  getGuardianOutstandingDebt,
  hasSignedRegularization,
} from '../../services/matricula';
import toast from 'react-hot-toast';

/**
 * Manages the core enrollment data lifecycle:
 * - Guardian loading (self or assisted)
 * - Enrollment creation/fetching
 * - Students enrolled + associated students (via student_guardian)
 * - Available courses for the selected year
 * - Debt checking + regularization state
 *
 * @param {Object} deps
 * @param {Object|null} deps.user - authenticated user
 * @param {number} deps.year - academic year
 * @param {boolean} deps.assistedMode - whether user is ADMIN/ASIST
 * @param {Object|null} deps.assistedGuardian - selected assisted guardian
 * @param {string} deps.viewMode - 'wizard' or 'dashboard'
 */
export function useEnrollmentData({ user, year, assistedMode, assistedGuardian, viewMode }) {
  const [guardian, setGuardian] = useState(null);
  const [enrollment, setEnrollment] = useState(null);
  const [students, setStudents] = useState([]);
  const [allMyStudents, setAllMyStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Debt gating state
  const [debtInfo, setDebtInfo] = useState({ total: 0, items: [] });
  const [debtDoc, setDebtDoc] = useState(null);
  const [debtLoading, setDebtLoading] = useState(false);
  const [hasRegularized, setHasRegularized] = useState(false);
  const [regularizationSigned, setRegularizationSigned] = useState(false);
  const [refreshingState, setRefreshingState] = useState(false);

  // Load guardian & enrollment baseline
  useEffect(() => {
    if (!user) return;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        let g = guardian;
        if (assistedMode) {
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
          console.log('🔍 MatriculaWizard: Guardian fetched, id:', g?.id || 'null');
          if (!g) {
            setError(
              'No se encontró su registro como apoderado en el sistema. Por favor contacte a la secretaría administrativa al correo secretariaadministrativa@winterhillenlinea.cl o al teléfono del colegio para que creen su perfil.'
            );
            toast.error('Perfil de apoderado no encontrado. Contacte a secretaría administrativa.');
            setLoading(false);
            return;
          }
        }
        setGuardian(g);

        if (viewMode === 'wizard') {
          console.log('🔍 MatriculaWizard: Creating enrollment for guardian:', g.id, 'year:', year);
          const enr = await getOrCreateEnrollment(g.id, year);
          console.log('🔍 MatriculaWizard: Enrollment id:', enr?.id || 'null');
          if (!enr) {
            setError(
              'No se pudo iniciar el proceso de matrícula. Por favor, actualice la página e intente nuevamente. Si el problema persiste, contacte a secretaría administrativa.'
            );
            toast.error('Error al iniciar matrícula. Intente actualizar la página.');
          } else {
            setEnrollment(enr);
            // Load outstanding debt
            try {
              setDebtLoading(true);
              const debt = await getGuardianOutstandingDebt(g.id);
              if (debt) {
                setDebtInfo({ total: debt.total || 0, items: debt.items || [] });
              }
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
                    .in('type', ['PAGARE_DEUDA', 'PAGARE_REPACTACION'])
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
        } else {
          setEnrollment(null);
        }
      } finally {
        setLoading(false);
        console.log('🔍 MatriculaWizard: Loading complete');
      }
    })();
  }, [user, year, assistedMode, assistedGuardian, viewMode]);

  // Load enrolled students
  const reloadEnrollmentStudents = useCallback(async () => {
    if (!enrollment) return;
    const list = await listEnrollmentStudents(enrollment.id);
    setStudents(list);
  }, [enrollment]);

  useEffect(() => {
    reloadEnrollmentStudents();
  }, [reloadEnrollmentStudents]);

  // Refresh debt & regularization state
  const refreshDebtAndRegularization = useCallback(async () => {
    if (!guardian || !enrollment) return;
    setRefreshingState(true);
    try {
      try {
        setDebtLoading(true);
        const debt = await getGuardianOutstandingDebt(guardian.id);
        setDebtInfo({ total: debt?.total || 0, items: debt?.items || [] });
      } finally {
        setDebtLoading(false);
      }

      try {
        const signed = await hasSignedRegularization(enrollment.id);
        if (signed) {
          setHasRegularized(true);
          setRegularizationSigned(true);
          return;
        }
        const { data: docsAny } = await supabase
          .from('enrollment_documents')
          .select('id, status')
          .eq('enrollment_id', enrollment.id)
          .in('type', ['PAGARE_DEUDA', 'PAGARE_REPACTACION'])
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

  // Load associated students via student_guardian
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
          curso:cursos (
            nom_curso,
            nivel,
            letra_curso
          )
        )
      `)
      .eq('guardian_id', guardian.id);
    if (error) {
      console.error('loadAssociatedStudents error:', error?.message || error);
      return;
    }
    const list = (data || [])
      .map(r => {
        const s = r.students || {};
        const c = s.cursos || null;
        const cursoLabel =
          c?.nom_curso ||
          (c ? `${c.nivel ?? ''}${c.letra_curso ? ` ${c.letra_curso}` : ''}`.trim() : null) ||
          s.curso ||
          null;
        return {
          id: s.id,
          whole_name: s.whole_name,
          run: s.run,
          curso: s.curso || undefined,
          curso_nombre: cursoLabel || undefined,
        };
      })
      .filter(st => Boolean(st.id));
    setAllMyStudents(list);
  }, [guardian]);

  useEffect(() => {
    loadAssociatedStudents();
  }, [loadAssociatedStudents]);

  // Derive courses for selected year from cached cursos
  const { data: allCursos = [] } = useCursosQuery();
  const availableYearCourses = useMemo(() =>
    allCursos
      .filter(c => c.year_academico === year)
      .sort((a, b) => (a.nivel || '').localeCompare(b.nivel || '')),
    [allCursos, year]
  );

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

  // Student modal success handler
  const handleStudentModalSuccess = useCallback(() => {
    loadAssociatedStudents();
    reloadEnrollmentStudents();
  }, [loadAssociatedStudents, reloadEnrollmentStudents]);

  return {
    guardian,
    setGuardian,
    enrollment,
    setEnrollment,
    students,
    allMyStudents,
    availableYearCourses,
    loading,
    setLoading,
    error,
    // Debt gating
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
    reloadEnrollmentStudents,
    loadAssociatedStudents,
  };
}
