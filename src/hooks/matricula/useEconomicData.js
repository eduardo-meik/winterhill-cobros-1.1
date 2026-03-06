import { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { supabase } from '../../services/supabase';
import {
  updateEnrollmentMeta,
  getChequesForEnrollment,
  buildEnrollmentPaymentPlan,
} from '../../services/matricula';
import { buildEconomicPatch } from '../../utils/matriculaHelpers';
import toast from 'react-hot-toast';

/**
 * Manages all economic/payment state for the enrollment wizard:
 * - Per-student economic data map
 * - Global economic defaults
 * - Payment methods + cheques
 * - Descuento por planilla
 * - Auto-calculations (monto_cuota, descuento)
 * - Aggregated totals across students
 * - Payment plan building
 * - Meta hydration from enrollment
 *
 * @param {Object} deps
 * @param {Object|null} deps.enrollment - enrollment record
 * @param {Array} deps.students - enrolled students
 * @param {number} deps.year - academic year
 * @param {Array} deps.availableYearCourses - courses for selected year
 * @param {Function} deps.setEnrollment - setter for enrollment in parent
 */
export function useEconomicData({ enrollment, students, year, availableYearCourses, setEnrollment }) {
  const [economic, setEconomic] = useState({
    monto_matricula: '',
    colegiatura_anual: '',
    cantidad_cuotas: '10',
    monto_cuota: '',
    dia_vencimiento: '5',
  });
  const [studentEconomicMap, setStudentEconomicMap] = useState({});
  const [paymentMethod, setPaymentMethod] = useState({
    cheques: false,
    transferencia: true,
    efectivo: false,
    tarjeta: false,
    pagare: false,
  });
  const [descuentoPlanilla, setDescuentoPlanilla] = useState(false);
  const [descuentoInfo, setDescuentoInfo] = useState({
    porcentaje_descuento: 0,
    monto_total_descuento: 0,
    motivo: '',
    condiciones: '',
  });
  const [prioritario, setPrioritario] = useState(false);
  const [cheques, setCheques] = useState([]);
  const [showChequesModal, setShowChequesModal] = useState(false);
  const hydratedMetaForEnrollmentId = useRef(null);

  const chequesButtonLabel = useMemo(() => {
    const count = cheques?.length || 0;
    if (!paymentMethod?.cheques) return '🧾 Cheques';
    if (count > 0) return `🧾 Cheques (${count})`;
    return '🧾 Cheques';
  }, [cheques, paymentMethod?.cheques]);

  // ---------- META HYDRATION ----------

  useEffect(() => {
    if (!enrollment || !enrollment.meta) return;
    if (hydratedMetaForEnrollmentId.current === enrollment.id) return;
    hydratedMetaForEnrollmentId.current = enrollment.id;

    const meta = enrollment.meta || {};

    setEconomic(prev => ({
      ...prev,
      monto_matricula: meta.monto_matricula?.toString() || prev.monto_matricula,
      colegiatura_anual: meta.colegiatura_anual?.toString() || prev.colegiatura_anual,
      cantidad_cuotas: meta.cantidad_cuotas?.toString() || prev.cantidad_cuotas,
      monto_cuota: meta.monto_cuota?.toString() || prev.monto_cuota,
      dia_vencimiento: meta.dia_vencimiento?.toString() || prev.dia_vencimiento,
    }));

    if (typeof meta.prioritario === 'boolean') {
      setPrioritario(meta.prioritario);
    }

    if (typeof meta.porcentaje_descuento === 'number') {
      setDescuentoInfo(d => ({
        ...d,
        porcentaje_descuento: meta.porcentaje_descuento,
        monto_total_descuento:
          typeof meta.monto_total_descuento === 'number'
            ? meta.monto_total_descuento
            : Math.round((Number(meta.colegiatura_anual) || 0) * (meta.porcentaje_descuento / 100)),
      }));
    }

    setPaymentMethod(prev => ({
      ...prev,
      cheques: meta.forma_pago_cheques ?? prev.cheques,
      transferencia: meta.forma_pago_transferencia ?? prev.transferencia,
      efectivo: meta.forma_pago_efectivo ?? prev.efectivo,
      tarjeta: meta.forma_pago_tarjeta ?? prev.tarjeta,
      pagare: meta.forma_pago_pagare ?? prev.pagare,
    }));

    if (typeof meta.forma_pago_descuento_planilla === 'boolean') {
      setDescuentoPlanilla(meta.forma_pago_descuento_planilla);
    }

    if (meta.per_student_economic && typeof meta.per_student_economic === 'object') {
      setStudentEconomicMap(prev => ({ ...prev, ...meta.per_student_economic }));
    }

    // payment_plan is now derived via useMemo — no need to hydrate
  }, [enrollment?.id]);

  // Load existing cheques from DB
  useEffect(() => {
    if (!enrollment?.id) return;
    const fetchCheques = async () => {
      try {
        const dbCheques = await getChequesForEnrollment(enrollment.id);
        if (dbCheques && dbCheques.length > 0) {
          setCheques(dbCheques);
          setPaymentMethod(prev => {
            if (!prev.cheques) return { ...prev, cheques: true };
            return prev;
          });
        }
      } catch (e) {
        console.error('Error loading cheques:', e);
      }
    };
    fetchCheques();
  }, [enrollment?.id]);

  // ---------- AUTO-CALCULATIONS ----------

  // Auto-calc global monto_cuota
  useEffect(() => {
    const colegiatura = parseFloat(economic.colegiatura_anual);
    const cuotas = parseInt(economic.cantidad_cuotas);
    if (!isNaN(colegiatura) && !isNaN(cuotas) && cuotas > 0 && colegiatura > 0) {
      const montoPorCuota = Math.round(colegiatura / cuotas);
      setEconomic(prev => ({ ...prev, monto_cuota: montoPorCuota.toString() }));
    }
  }, [economic.colegiatura_anual, economic.cantidad_cuotas]);

  // Auto-calc per-student monto_cuota and descuento
  useEffect(() => {
    if (!studentEconomicMap || Object.keys(studentEconomicMap).length === 0) return;
    setStudentEconomicMap(prev => {
      let changed = false;
      const next = { ...prev };
      Object.entries(prev).forEach(([studentId, econ]) => {
        const colegiatura = parseFloat(econ.colegiatura_anual || '');
        const cuotas = parseInt(econ.cantidad_cuotas || '');
        const porcentaje = typeof econ.porcentaje_descuento === 'number' ? econ.porcentaje_descuento : undefined;
        let updated = { ...econ };

        if (!isNaN(colegiatura) && !isNaN(cuotas) && cuotas > 0 && colegiatura > 0) {
          const montoPorCuota = Math.round(colegiatura / cuotas).toString();
          if (updated.monto_cuota !== montoPorCuota) {
            updated.monto_cuota = montoPorCuota;
            changed = true;
          }
        }

        if (typeof porcentaje === 'number') {
          const totalDesc = Math.round(((Number(updated.colegiatura_anual) || 0) * porcentaje) / 100);
          if (updated.monto_total_descuento !== totalDesc) {
            updated.monto_total_descuento = totalDesc;
            changed = true;
          }
        }

        next[studentId] = updated;
      });
      return changed ? next : prev;
    });
  }, [studentEconomicMap]);

  // Keep per-student economic defaults in sync when students change
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
            year_academico: year,
          };
        }
      });
      return next;
    });
  }, [students, economic, descuentoInfo]);

  // Auto-suggest course per student using backend promotion logic
  useEffect(() => {
    if (!Array.isArray(students) || students.length === 0) return;
    if (!Array.isArray(availableYearCourses) || availableYearCourses.length === 0) return;

    const fetchPromotionSuggestions = async () => {
      const updates = {};
      for (const st of students) {
        if (!st?.id) continue;
        if (studentEconomicMap[st.id]?.curso_sugerido) continue;
        try {
          const { data, error } = await supabase.rpc('get_student_promotion_suggestion', {
            p_student_id: st.id,
          });
          if (error) {
            console.warn('Promotion suggestion error for student:', error?.message || error);
            continue;
          }
          if (data && data.length > 0) {
            const suggestion = data[0];
            let suggestedId = suggestion.suggested_course_id || null;
            const suggestedYear = suggestion.suggested_year || year;
            if (!suggestedId && suggestion.current_course_id) {
              const sameCourse = availableYearCourses.find(c => c.id === suggestion.current_course_id);
              if (sameCourse) suggestedId = sameCourse.id;
            }
            if (suggestedId || suggestedYear) {
              updates[st.id] = {
                ...(studentEconomicMap[st.id] || {}),
                curso_sugerido: suggestedId || '',
                year_academico: suggestedYear,
              };
            }
          }
        } catch (e) {
          console.error('Error fetching promotion:', e?.message || e);
        }
      }
      if (Object.keys(updates).length > 0) {
        setStudentEconomicMap(prev => ({ ...prev, ...updates }));
      }
    };

    fetchPromotionSuggestions();
  }, [students, availableYearCourses, year]);

  // Update prioritario flag when any student is marked prioritario
  useEffect(() => {
    const anyPrioritario = students.some(st => {
      const econ = studentEconomicMap[st.id];
      return econ?.prioritario === true;
    });
    setPrioritario(anyPrioritario);
  }, [students, studentEconomicMap]);

  // ---------- FIELD UPDATERS ----------

  const updateStudentEconomicField = (studentId, field, value) => {
    setStudentEconomicMap(prev => ({
      ...prev,
      [studentId]: { ...(prev[studentId] || {}), [field]: value },
    }));
  };

  const updateStudentCourseForYear = (studentId, value) => {
    setStudentEconomicMap(prev => ({
      ...prev,
      [studentId]: { ...(prev[studentId] || {}), curso_sugerido: value },
    }));
  };

  // ---------- AGGREGATED TOTALS ----------

  const totalNetMonthlyInstallment = useMemo(() => {
    if (!students || students.length === 0) return 0;
    let total = 0;
    students.forEach(st => {
      const econ = studentEconomicMap[st.id];
      if (!econ) return;
      const colegiatura = Number(econ.colegiatura_anual) || 0;
      const descuento = Number(econ.monto_total_descuento) || 0;
      const cuotas = Math.max(1, Number(econ.cantidad_cuotas) || 1);
      const netAnnual = Math.max(0, colegiatura - descuento);
      total += Math.round(netAnnual / cuotas);
    });
    return total;
  }, [students, studentEconomicMap]);

  const aggregatedEconomicTotals = useMemo(() => {
    if (!students || students.length === 0) {
      return { totalMatricula: 0, totalColegiatura: 0, totalDescuento: 0, totalNeto: 0, cantidadCuotas: 0, diaVencimiento: 5 };
    }
    let totalMatricula = 0;
    let totalColegiatura = 0;
    let totalDescuento = 0;
    let maxCuotas = 0;
    let firstDiaVencimiento = 5;
    let foundFirstDia = false;

    students.forEach(st => {
      const econ = studentEconomicMap[st.id];
      if (!econ) return;
      totalMatricula += Number(econ.monto_matricula) || 0;
      totalColegiatura += Number(econ.colegiatura_anual) || 0;
      totalDescuento += Number(econ.monto_total_descuento) || 0;
      const cuotas = Number(econ.cantidad_cuotas) || 0;
      if (cuotas > maxCuotas) maxCuotas = cuotas;
      if (!foundFirstDia && econ.dia_vencimiento) {
        firstDiaVencimiento = Number(econ.dia_vencimiento) || 5;
        foundFirstDia = true;
      }
    });

    return {
      totalMatricula,
      totalColegiatura,
      totalDescuento,
      totalNeto: Math.max(0, totalColegiatura - totalDescuento),
      cantidadCuotas: maxCuotas,
      diaVencimiento: firstDiaVencimiento,
    };
  }, [students, studentEconomicMap]);

  // Derived paymentPlan — synchronous, no extra render cycle
  const paymentPlan = useMemo(() => {
    if (!enrollment?.year || !aggregatedEconomicTotals) return null;
    return buildEnrollmentPaymentPlan({
      enrollmentYear: enrollment.year,
      economic: {
        monto_matricula: aggregatedEconomicTotals.totalMatricula,
        colegiatura_anual: aggregatedEconomicTotals.totalNeto,
        cantidad_cuotas: aggregatedEconomicTotals.cantidadCuotas,
        monto_cuota:
          aggregatedEconomicTotals.cantidadCuotas > 0
            ? Math.round(aggregatedEconomicTotals.totalNeto / aggregatedEconomicTotals.cantidadCuotas)
            : 0,
        dia_vencimiento: aggregatedEconomicTotals.diaVencimiento,
      },
      paymentMethodFlags: paymentMethod,
    });
  }, [aggregatedEconomicTotals, paymentMethod, enrollment?.year]);

  // ---------- SAVE ----------

  const handleSaveEconomic = useCallback(async () => {
    if (!enrollment) return;

    let colegiaturaAnual = Number(economic.colegiatura_anual) || 0;
    let cantidadCuotas = Number(economic.cantidad_cuotas) || 0;
    let montoCuota = Number(economic.monto_cuota) || 0;

    if (prioritario) {
      colegiaturaAnual = 0;
      cantidadCuotas = 0;
      montoCuota = 0;
    }

    const patch = buildEconomicPatch({
      economic,
      colegiaturaAnual,
      cantidadCuotas,
      montoCuota,
      paymentMethod,
      descuentoPlanilla,
      prioritario,
      descuentoInfo,
    });

    if (studentEconomicMap && Object.keys(studentEconomicMap).length > 0) {
      patch.per_student_economic = studentEconomicMap;
    }

    const studentsCount = Array.isArray(students) ? students.length : 0;
    const useAggregated = aggregatedEconomicTotals.totalColegiatura > 0;
    const fallbackTotal =
      studentsCount > 1 ? (Number(patch.colegiatura_anual) || 0) * studentsCount : Number(patch.colegiatura_anual) || 0;
    const planColegiatura = useAggregated ? aggregatedEconomicTotals.totalColegiatura : fallbackTotal;

    const userMontoCuota =
      totalNetMonthlyInstallment > 0 ? totalNetMonthlyInstallment : Number(patch.monto_cuota) || 0;
    const derivedMontoCuota = patch.cantidad_cuotas
      ? Math.round(Number(planColegiatura) / Number(patch.cantidad_cuotas))
      : 0;
    const planMontoCuota = prioritario ? 0 : userMontoCuota > 0 ? userMontoCuota : derivedMontoCuota;

    const localPlan = buildEnrollmentPaymentPlan({
      enrollmentYear: year,
      economic: {
        colegiatura_anual: planColegiatura,
        cantidad_cuotas: patch.cantidad_cuotas,
        monto_cuota: planMontoCuota,
        dia_vencimiento: patch.dia_vencimiento,
      },
      paymentMethodFlags: paymentMethod,
    });

    patch.payment_plan = localPlan;

    const updated = await updateEnrollmentMeta(enrollment.id, patch);
    if (updated) {
      setEnrollment(prev => (prev ? { ...prev, meta: { ...(prev.meta || {}), ...patch } } : prev));
    }

    if (!prioritario && !economic.monto_cuota && patch.colegiatura_anual && patch.cantidad_cuotas) {
      const calc = Math.round(patch.colegiatura_anual / patch.cantidad_cuotas);
      setEconomic(e => ({ ...e, monto_cuota: calc.toString() }));
    }

    toast.success('Datos económicos guardados correctamente');
  }, [
    enrollment,
    economic,
    prioritario,
    paymentMethod,
    descuentoPlanilla,
    descuentoInfo,
    studentEconomicMap,
    students,
    aggregatedEconomicTotals,
    totalNetMonthlyInstallment,
    year,
    setEnrollment,
  ]);

  return {
    economic,
    setEconomic,
    studentEconomicMap,
    setStudentEconomicMap,
    paymentMethod,
    setPaymentMethod,
    paymentPlan,
    descuentoPlanilla,
    setDescuentoPlanilla,
    descuentoInfo,
    setDescuentoInfo,
    prioritario,
    cheques,
    setCheques,
    showChequesModal,
    setShowChequesModal,
    chequesButtonLabel,
    // Field updaters
    updateStudentEconomicField,
    updateStudentCourseForYear,
    // Aggregated
    totalNetMonthlyInstallment,
    aggregatedEconomicTotals,
    // Save handler
    handleSaveEconomic,
  };
}
