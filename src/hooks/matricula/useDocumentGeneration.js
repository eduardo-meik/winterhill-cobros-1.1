import { useState, useEffect, useCallback } from 'react';
import {
  updateEnrollmentMeta,
  sha256,
  signEnrollmentDocument,
  buildEnrollmentPaymentPlan,
  saveChequesForEnrollment,
  ensureEnrollmentDocuments,
  assignEnrollmentFolio,
  syncEnrollmentStudentCourses,
} from '../../services/matricula';
import {
  finalizeEnrollmentPreview,
  finalizeEnrollmentConfirm,
} from '../../services/matricula';
import {
  buildPrestacionPayload,
  renderPrestacionWithAnnex,
  renderSingleDocument,
  createPrestacionDocument,
} from '../../services/matricula';
import { generatePDFFromHTML, downloadPDFBlob } from '../../services/pdfGenerator';
import { sendEmailViaFunction, blobToBase64 } from '../../services/email';
import {
  buildEnrollmentReceiptHtml,
  generateEnrollmentReceiptPdf,
} from '../../services/enrollmentReceipt';
import toast from 'react-hot-toast';

/**
 * Handles document generation, preview, PDF download, email, signing, and enrollment finalization.
 *
 * @param {Object} deps
 * @param {Object|null} deps.user - authenticated user
 * @param {Object|null} deps.guardian - guardian record
 * @param {Object|null} deps.enrollment - enrollment record
 * @param {Array} deps.students - enrolled students
 * @param {number} deps.year - academic year
 * @param {boolean} deps.assistedMode - staff assisted mode
 * @param {Object} deps.economic - global economic data
 * @param {Object} deps.studentEconomicMap - per-student economic data
 * @param {Object} deps.paymentMethod - payment method flags
 * @param {boolean} deps.descuentoPlanilla - descuento por planilla flag
 * @param {Object} deps.descuentoInfo - descuento info { porcentaje, motivo, condiciones }
 * @param {boolean} deps.prioritario - global prioritario flag
 * @param {Array} deps.cheques - cheques data
 * @param {Object|null} deps.paymentPlan - current payment plan
 * @param {Array} deps.availableYearCourses - courses for year
 * @param {Object} deps.aggregatedEconomicTotals - aggregated totals
 * @param {number} deps.totalNetMonthlyInstallment - net monthly installment
 * @param {Object} deps.debtInfo - debt info { total, items }
 * @param {Function} deps.setEnrollment - setter for enrollment
 * @param {Function} deps.setLoading - setter for loading state
 * @param {Function} deps.reloadEnrollmentStudents - reload students
 * @param {Function} deps.setStep - step setter from navigation hook
 * @param {Function} deps.navigate - react-router navigate
 */
export function useDocumentGeneration({
  user,
  guardian,
  enrollment,
  students,
  year,
  assistedMode,
  economic,
  studentEconomicMap,
  paymentMethod,
  descuentoPlanilla,
  descuentoInfo,
  prioritario,
  cheques,
  paymentPlan,
  availableYearCourses,
  aggregatedEconomicTotals,
  totalNetMonthlyInstallment,
  debtInfo,
  setEnrollment,
  setLoading,
  reloadEnrollmentStudents,
  setStep,
  navigate,
}) {
  const [previewHtml, setPreviewHtml] = useState('');
  const [previewParts, setPreviewParts] = useState(null);
  const [documentRecord, setDocumentRecord] = useState(null);
  const [sendingPagare, setSendingPagare] = useState(false);
  const [autoDocSyncing, setAutoDocSyncing] = useState(false);

  // Finalize state
  const [finalizing, setFinalizing] = useState(false);
  const [finalizeOpen, setFinalizeOpen] = useState(false);
  const [finalizePreview, setFinalizePreview] = useState(null);
  const [finalizeAlert, setFinalizeAlert] = useState(null);
  const [enrollmentFolio, setEnrollmentFolio] = useState(null);
  const [sendingEnrollmentReceipt, setSendingEnrollmentReceipt] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);

  // Clear finalize alert when guardian changes
  useEffect(() => {
    if (!guardian) setFinalizeAlert(null);
  }, [guardian?.id]);

  // Auto document generation effect (debounced)
  useEffect(() => {
    if (!enrollment || !guardian) return;
    const timer = setTimeout(async () => {
      try {
        setAutoDocSyncing(true);
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
    }, 550);
    return () => clearTimeout(timer);
  }, [enrollment?.id, guardian?.id, students, enrollment?.meta, prioritario, descuentoPlanilla, paymentMethod, economic, debtInfo?.total]);

  // Record assisted mode auditing in enrollment meta
  useEffect(() => {
    if (!assistedMode) return;
    if (!enrollment || !guardian || !user) return;
    updateEnrollmentMeta(enrollment.id, {
      assisted_by_user_id: user.id,
      assisted_by_role: user.profile,
      assisted_by_name: user.email || null,
      assisted_at: new Date().toISOString(),
    });
  }, [assistedMode, enrollment?.id, guardian?.id, user?.id]);

  // ---------- HELPERS ----------

  const _buildStudentsWithCourse = useCallback(() => {
    return students.map(s => {
      const econ = studentEconomicMap?.[s.id];
      const cursoId = econ?.curso_sugerido;
      let curso_nombre = s.curso_nombre || s.curso || s.grade || s.nivel || 'Sin curso asignado';
      if (cursoId && Array.isArray(availableYearCourses)) {
        const curso = availableYearCourses.find(c => c.id === cursoId);
        if (curso) {
          curso_nombre = curso.nom_curso || `${curso.nivel ?? ''}${curso.letra_curso ? ` ${curso.letra_curso}` : ''}`.trim() || 'Sin nombre';
        }
      }
      return { ...s, curso_nombre };
    });
  }, [students, studentEconomicMap, availableYearCourses]);

  const _buildPerStudentEconomic = useCallback(() => {
    const descuentoMetaPorcentaje = Number(descuentoInfo.porcentaje_descuento) || 0;
    return students.map(s => {
      const econ = studentEconomicMap?.[s.id] || {};
      const colegAnual = Number(econ.colegiatura_anual ?? economic.colegiatura_anual) || 0;
      const porcentajeDescAlumno = typeof econ.porcentaje_descuento === 'number' ? econ.porcentaje_descuento : descuentoMetaPorcentaje;
      const montoTotalDescAlumno = colegAnual > 0 && porcentajeDescAlumno > 0 ? Math.round(colegAnual * (porcentajeDescAlumno / 100)) : 0;
      const montoNetoAnualAlumno = Math.max(0, colegAnual - montoTotalDescAlumno);
      return {
        student_id: s.id,
        colegiatura_anual: colegAnual,
        porcentaje_descuento: porcentajeDescAlumno,
        monto_total_descuento: montoTotalDescAlumno,
        monto_neto_anual: montoNetoAnualAlumno,
      };
    });
  }, [students, studentEconomicMap, economic, descuentoInfo]);

  const _buildPayload = useCallback(() => {
    const econNumbers = {
      monto_matricula: aggregatedEconomicTotals.totalMatricula || undefined,
      colegiatura_anual: aggregatedEconomicTotals.totalColegiatura || undefined,
      cantidad_cuotas: aggregatedEconomicTotals.cantidadCuotas || undefined,
      monto_cuota: aggregatedEconomicTotals.cantidadCuotas > 0
        ? Math.round(aggregatedEconomicTotals.totalNeto / aggregatedEconomicTotals.cantidadCuotas)
        : undefined,
      dia_vencimiento: aggregatedEconomicTotals.diaVencimiento || undefined,
    };

    const descuentoMetaPorcentaje = Number(descuentoInfo.porcentaje_descuento) || 0;

    const payload = buildPrestacionPayload({
      guardian,
      year,
      students: _buildStudentsWithCourse(),
      economic: econNumbers,
      paymentMethod,
      cheques,
      perStudentEconomic: _buildPerStudentEconomic(),
      descuento: descuentoMetaPorcentaje > 0
        ? { porcentaje: descuentoMetaPorcentaje, motivo: descuentoInfo.motivo || '', condiciones: descuentoInfo.condiciones || '' }
        : null,
      paymentPlan: paymentPlan || null,
    });

    try {
      payload.folio_number = (enrollment?.id ? String(enrollment.id).slice(0, 8) : Date.now().toString().slice(-8)).toUpperCase();
    } catch {}

    return payload;
  }, [guardian, year, enrollment, paymentMethod, cheques, descuentoInfo, paymentPlan, aggregatedEconomicTotals, _buildStudentsWithCourse, _buildPerStudentEconomic]);

  // ---------- GENERATE PREVIEW ----------

  const handleGeneratePagare = useCallback(async () => {
    if (!guardian || !enrollment) {
      if (!guardian) toast.error('No se han cargado los datos del apoderado. Por favor, actualice la página.');
      else toast.error('No se ha iniciado el proceso de matrícula. Por favor, seleccione el año académico e inicie nuevamente.');
      return;
    }

    setLoading(true);

    const prestacionPayload = _buildPayload();

    // Pre-assign enrollment folio so pagaré shows the real folio number
    const assignedFolio = await assignEnrollmentFolio(enrollment.id);
    if (assignedFolio) {
      prestacionPayload.folio_number = assignedFolio;
    }

    const annex = prioritario ? null : descuentoPlanilla ? 'descuento' : paymentMethod.pagare ? 'pagare' : null;
    const html = renderPrestacionWithAnnex(prestacionPayload, { annex });

    setPreviewHtml(html);

    // Build separate HTML parts for per-document preview
    try {
      const contractOnlyHtml = renderSingleDocument(prestacionPayload, 'contract');
      const pagareHtml = !prioritario && paymentMethod.pagare ? renderSingleDocument(prestacionPayload, 'pagare') : null;
      const descuentoHtml = !prioritario && descuentoPlanilla ? renderSingleDocument(prestacionPayload, 'descuento') : null;
      setPreviewParts({
        contractHtml: contractOnlyHtml,
        pagareHtml,
        descuentoHtml,
        excluded: { contract: false, pagare: false, descuento: false },
        selected: 'contract',
      });
    } catch (e) {
      console.error('Error building per-document preview parts:', e?.message || e);
      setPreviewParts(null);
    }

    // Create document record
    const contentHash = await sha256(html);
    const doc = await createPrestacionDocument({
      enrollmentId: enrollment.id,
      payload: prestacionPayload,
      finalContent: html,
      contentHash,
    });
    setDocumentRecord(doc);

    // Persist cheques with document_id — use the real enrollment folio
    if (paymentMethod?.cheques && Array.isArray(cheques) && cheques.length && doc?.id) {
      try {
        const folioNumber = assignedFolio || doc.id.substring(0, 8).toUpperCase();
        await saveChequesForEnrollment({
          enrollmentId: enrollment.id,
          cheques: cheques.map((c, idx) => ({
            numero_cuota: c.numero_cuota ?? idx + 1,
            numero_serie: c.numero_serie,
            banco: c.banco,
            fecha_emision: c.fecha_emision,
            monto: Number(c.monto) || 0,
            notas: c.notas || '',
          })),
          documentId: doc.id,
          folioNumber,
          createdBy: user?.id || null,
        });
      } catch (e) {
        console.error('❌ Error saving cheques:', e?.message || e);
        toast.error('Error al guardar cheques. Verifique en la base de datos.');
      }
    }

    setLoading(false);

    if (doc) {
      setStep(2);
      toast.success('Vista previa del Contrato de Prestación generada. Revise el documento antes de descargar.');
    }
  }, [guardian, enrollment, _buildPayload, prioritario, descuentoPlanilla, paymentMethod, cheques, user, setLoading, setStep]);

  // ---------- DOWNLOAD PDF ----------

  const handleDownloadPDF = useCallback(async () => {
    if (!previewHtml || !guardian) {
      toast.error('Debe generar el contrato primero usando el botón "Generar Vista Previa" antes de poder descargarlo.');
      return;
    }
    try {
      toast.loading('Generando PDF...', { id: 'pdf-download' });
      const folioNumber = documentRecord?.id ? documentRecord.id.substring(0, 8).toUpperCase() : Date.now().toString().slice(-8);

      let htmlForDownload = previewHtml;
      if (previewParts) {
        const parts = [];
        if (!previewParts.excluded?.contract && previewParts.contractHtml) parts.push(previewParts.contractHtml);
        if (!prioritario && previewParts.pagareHtml && !previewParts.excluded?.pagare) parts.push(previewParts.pagareHtml);
        if (!prioritario && previewParts.descuentoHtml && !previewParts.excluded?.descuento) parts.push(previewParts.descuentoHtml);
        if (parts.length === 0 && previewParts.contractHtml) parts.push(previewParts.contractHtml);
        if (parts.length > 0) htmlForDownload = parts.join('<div style="page-break-after: always;"></div>');
      }

      const pdfBlob = await generatePDFFromHTML({
        htmlContent: htmlForDownload,
        includeHeader: true,
        includeSignatureSection: true,
        folioNumber,
        guardianRun: guardian.run,
      });
      downloadPDFBlob(pdfBlob, `Contrato_Prestacion_${year}_${guardian?.run || 'documento'}.pdf`);
      toast.success('PDF descargado exitosamente', { id: 'pdf-download' });
    } catch (err) {
      console.error('Download PDF error:', err?.message || err);
      const errMsg = err?.message || '';
      if (errMsg.includes('ERR_CONNECTION_REFUSED') || errMsg.includes('Failed to fetch')) {
        toast.error('No se pudo conectar con el servicio de generación de PDF. Por favor, intente nuevamente en unos momentos.', { id: 'pdf-download' });
      } else {
        toast.error('Error al generar el PDF. Por favor, intente nuevamente o contacte a soporte técnico si el problema persiste.', { id: 'pdf-download' });
      }
    }
  }, [previewHtml, guardian, documentRecord, previewParts, prioritario, year]);

  // ---------- PRINT ----------

  const handlePrint = useCallback(async () => {
    if (!previewHtml) {
      toast.error('Debe generar el contrato primero usando el botón "Generar Vista Previa" antes de poder imprimirlo.');
      return;
    }
    try {
      const printWindow = window.open('', '_blank');
      if (!printWindow) { toast.error('No se pudo abrir la ventana de impresión'); return; }
      printWindow.document.open();
      printWindow.document.write(`<!DOCTYPE html><html><head><meta charset="utf-8" /></head><body>`);
      printWindow.document.write(previewHtml);
      printWindow.document.write('</body></html>');
      printWindow.document.close();
      printWindow.focus();
      setTimeout(() => printWindow.print(), 500);
    } catch (err) {
      console.error('Print error:', err?.message || err);
      toast.error('Error al abrir la ventana de impresión. Verifique que su navegador permita ventanas emergentes.');
    }
  }, [previewHtml]);

  // ---------- INDIVIDUAL PDF DOWNLOAD ----------

  const handleDownloadIndividualPDF = useCallback(async (type) => {
    if (!guardian || !enrollment) return;
    try {
      toast.loading(`Generando ${type}...`, { id: 'pdf-download-single' });
      const meta = enrollment.meta || {};
      const econNumbers = {
        monto_matricula: Number(meta.monto_matricula ?? economic.monto_matricula) || undefined,
        colegiatura_anual: Number(meta.colegiatura_anual ?? economic.colegiatura_anual) || undefined,
        cantidad_cuotas: Number(meta.cantidad_cuotas ?? economic.cantidad_cuotas) || undefined,
        monto_cuota: Number(meta.monto_cuota ?? economic.monto_cuota) || undefined,
        dia_vencimiento: Number(meta.dia_vencimiento ?? economic.dia_vencimiento) || undefined,
      };

      const descuentoMetaPorcentaje = Number(meta.porcentaje_descuento ?? descuentoInfo.porcentaje_descuento) || 0;
      const perStudentEconomic = students.map(s => {
        const econ = studentEconomicMap?.[s.id] || {};
        const colegAnual = Number(econ.colegiatura_anual ?? economic.colegiatura_anual) || 0;
        const porcentajeDescAlumno = typeof econ.porcentaje_descuento === 'number' ? econ.porcentaje_descuento : descuentoMetaPorcentaje;
        const montoTotalDescAlumno = colegAnual > 0 && porcentajeDescAlumno > 0 ? Math.round(colegAnual * (porcentajeDescAlumno / 100)) : 0;
        return { student_id: s.id, colegiatura_anual: colegAnual, porcentaje_descuento: porcentajeDescAlumno, monto_total_descuento: montoTotalDescAlumno, monto_neto_anual: Math.max(0, colegAnual - montoTotalDescAlumno) };
      });

      const payload = buildPrestacionPayload({
        guardian, year, students: _buildStudentsWithCourse(), economic: econNumbers, paymentMethod, cheques, perStudentEconomic,
        descuento: descuentoMetaPorcentaje > 0 ? { porcentaje: descuentoMetaPorcentaje, motivo: descuentoInfo.motivo || '', condiciones: descuentoInfo.condiciones || '' } : null,
        paymentPlan: paymentPlan || null,
      });

      const enrollmentFolioFromMeta = enrollment?.meta?.folio;
      const folioNumber = enrollmentFolioFromMeta
        || (documentRecord?.id
          ? documentRecord.id.substring(0, 8).toUpperCase()
          : (enrollment?.id ? String(enrollment.id).slice(0, 8) : Date.now().toString().slice(-8)).toUpperCase());
      payload.folio_number = folioNumber;

      const html = renderSingleDocument(payload, type);
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: html, includeHeader: true, includeSignatureSection: true, folioNumber, guardianRun: guardian.run,
      });
      const filename = `${type === 'contract' ? 'Contrato' : type === 'pagare' ? 'Pagare' : 'Anexo_Descuento'}_${year}_${guardian.run}.pdf`;
      downloadPDFBlob(pdfBlob, filename);
      toast.success('Descarga completada', { id: 'pdf-download-single' });
    } catch (e) {
      console.error('Error downloading single PDF:', e?.message || e);
      toast.error('Error al descargar documento', { id: 'pdf-download-single' });
    }
  }, [guardian, enrollment, year, economic, studentEconomicMap, paymentMethod, cheques, descuentoInfo, paymentPlan, documentRecord, _buildStudentsWithCourse]);

  // ---------- EMAIL ----------

  const handleSendPagareEmail = useCallback(async () => {
    if (!previewHtml || !guardian) {
      if (!previewHtml) toast.error('Debe generar el contrato primero usando el botón "Generar Vista Previa" antes de enviarlo por correo.');
      else toast.error('No se encontraron los datos del apoderado. Por favor, actualice la página.');
      return;
    }
    if (!guardian.email) {
      toast.error('No tiene un correo electrónico registrado en el sistema. Por favor, contacte a secretaría administrativa para actualizar su información de contacto.');
      return;
    }
    try {
      setSendingPagare(true);
      toast.loading('Generando y enviando Pagaré...', { id: 'pagare-send' });
      const folioNumber = documentRecord?.id ? documentRecord.id.substring(0, 8).toUpperCase() : Date.now().toString().slice(-8);
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: previewHtml, includeHeader: true, includeSignatureSection: true, folioNumber, guardianRun: guardian.run,
      });
      const base64 = await blobToBase64(pdfBlob);
      const filename = `Contrato_Prestacion_${year}_${guardian?.run || 'documento'}.pdf`;
      const subject = `Contrato de Prestación Matrícula ${year} - Winterhill`;
      const html = `<p>Estimado(a) ${guardian.first_name} ${guardian.last_name},</p>
        <p>Adjuntamos el Contrato de Prestación (y anexos, si corresponden) para la matrícula ${year}. Por favor, revise el documento y conserve una copia para sus registros.</p>
        <p>Saludos cordiales,<br/>Corporación Educacional Winterhill</p>`;
      await sendEmailViaFunction({
        to: guardian.email, subject, html, type: 'prestacion', related_id: documentRecord?.id || undefined,
        attachments: [{ filename, content: base64, type: 'application/pdf' }],
      });
      toast.success('Contrato de Prestación enviado por correo', { id: 'pagare-send' });
    } catch (err) {
      console.error('Enviar pagaré error:', err?.message || err);
      toast.error(err?.message || 'No se pudo enviar el pagaré', { id: 'pagare-send' });
    } finally {
      setSendingPagare(false);
    }
  }, [previewHtml, guardian, documentRecord, year]);

  // ---------- SIGN ----------

  const handleSign = useCallback(async () => {
    if (!documentRecord) return;
    setLoading(true);
    const ok = await signEnrollmentDocument(documentRecord.id, 'checkbox', user?.id);
    setLoading(false);
    if (ok) toast.success('Contrato firmado');
  }, [documentRecord, user, setLoading]);

  // ---------- FINALIZE ----------

  const handleFinalizePreview = useCallback(async () => {
    if (!enrollment?.id) return;
    try {
      setFinalizing(true);
      setFinalizeAlert(null);
      toast.loading('Preparando finalización...', { id: 'finalize-enrollment' });

      const studentsCount = Array.isArray(students) ? students.length : 0;
      const useAggregated = aggregatedEconomicTotals.totalColegiatura > 0;
      const fallbackTotal = studentsCount > 1 ? (Number(economic.colegiatura_anual) || 0) * studentsCount : Number(economic.colegiatura_anual) || 0;
      const planColegiatura = useAggregated ? aggregatedEconomicTotals.totalColegiatura : fallbackTotal;
      const userMontoCuota = totalNetMonthlyInstallment > 0 ? totalNetMonthlyInstallment : Number(economic.monto_cuota) || 0;
      const cuotasCount = aggregatedEconomicTotals.cantidadCuotas > 0 ? aggregatedEconomicTotals.cantidadCuotas : Number(economic.cantidad_cuotas) || 10;
      const derivedMontoCuota = cuotasCount > 0 ? Math.round(planColegiatura / cuotasCount) : 0;
      const planMontoCuota = prioritario ? 0 : userMontoCuota > 0 ? userMontoCuota : derivedMontoCuota;
      const diaVencimiento = aggregatedEconomicTotals.diaVencimiento > 0 ? aggregatedEconomicTotals.diaVencimiento : Number(economic.dia_vencimiento) || 5;

      let planToSend = null;
      if (prioritario) {
        planToSend = buildEnrollmentPaymentPlan({ enrollmentYear: year, economic: { colegiatura_anual: 0, cantidad_cuotas: 0, monto_cuota: 0, dia_vencimiento: 5 }, paymentMethodFlags: paymentMethod });
      } else if (planColegiatura > 0 || userMontoCuota > 0) {
        planToSend = buildEnrollmentPaymentPlan({ enrollmentYear: year, economic: { colegiatura_anual: planColegiatura, cantidad_cuotas: cuotasCount, monto_cuota: planMontoCuota, dia_vencimiento: diaVencimiento }, paymentMethodFlags: paymentMethod });
      }

      const options = {};
      if (planToSend) {
        options.payment_plan = planToSend;
        options.plan_pago = planToSend;
        options.paymentPlan = planToSend;
      }

      // Build per-student payment plans so each sibling gets their own cuota amount
      if (!prioritario && students.length > 0 && studentEconomicMap) {
        const perStudentPlans = {};
        students.forEach(st => {
          const econ = studentEconomicMap[st.id];
          if (!econ) return;
          const stColegiatura = Number(econ.colegiatura_anual) || 0;
          const stDescuento = Number(econ.monto_total_descuento) || 0;
          const stCuotas = Math.max(1, Number(econ.cantidad_cuotas) || cuotasCount || 10);
          const stNeto = Math.max(0, stColegiatura - stDescuento);
          const stMontoCuota = stCuotas > 0 ? Math.round(stNeto / stCuotas) : 0;
          const stPlan = buildEnrollmentPaymentPlan({
            enrollmentYear: year,
            economic: {
              colegiatura_anual: stNeto,
              cantidad_cuotas: stCuotas,
              monto_cuota: stMontoCuota,
              dia_vencimiento: diaVencimiento,
            },
            paymentMethodFlags: paymentMethod,
          });
          if (stPlan) {
            perStudentPlans[st.id] = stPlan;
          }
        });
        if (Object.keys(perStudentPlans).length > 0) {
          options.per_student_plans = perStudentPlans;
          // Persist per_student_plans in enrollment meta so confirm can use them
          try {
            await updateEnrollmentMeta(enrollment.id, { per_student_plans: perStudentPlans });
            setEnrollment(prev => prev ? { ...prev, meta: { ...(prev.meta || {}), per_student_plans: perStudentPlans } } : prev);
          } catch (metaErr) {
            console.warn('Could not persist per_student_plans to meta', metaErr);
          }
        }
      }

      const preview = await finalizeEnrollmentPreview(enrollment.id, options);
      setFinalizePreview(preview);
      setFinalizeOpen(true);
      toast.dismiss('finalize-enrollment');
    } catch (error) {
      console.error('Error previewing finalization:', error?.message || error);
      const errorMsg = error?.message || '';
      if (errorMsg.includes('PLAN_MISSING')) toast.error('Falta el plan de pagos. Por favor, complete los datos económicos y genere el contrato antes de finalizar.');
      else if (errorMsg.includes('NO_STUDENTS')) toast.error('Debe agregar al menos un estudiante para finalizar la matrícula.');
      else if (errorMsg.includes('MISSING_RELATION')) toast.error('Falta la relación entre estudiante y apoderado. Contacte a secretaría administrativa.');
      else toast.error('Error al preparar la confirmación de matrícula. Verifique que haya completado todos los pasos.', { id: 'finalize-enrollment' });
    } finally {
      setFinalizing(false);
    }
  }, [enrollment, students, economic, aggregatedEconomicTotals, totalNetMonthlyInstallment, prioritario, year, paymentMethod, studentEconomicMap]);

  const handleFinalizeConfirm = useCallback(async () => {
    if (!enrollment?.id) return;
    try {
      setFinalizing(true);
      toast.loading('Finalizando matrícula...', { id: 'finalize-enrollment' });
      await syncEnrollmentStudentCourses({
        students,
        studentEconomicMap,
        availableYearCourses,
      });
      // Pass per_student_plans so each student gets individual cuota amounts
      const confirmOptions = {};
      const perStudentPlans = enrollment?.meta?.per_student_plans;
      if (perStudentPlans && typeof perStudentPlans === 'object') {
        confirmOptions.per_student_plans = perStudentPlans;
      }
      const result = await finalizeEnrollmentConfirm(enrollment.id, confirmOptions);
      setFinalizeAlert({ type: 'success', message: `Matrícula finalizada correctamente. Folio: ${result.folio || 'N/A'}` });
      setEnrollmentFolio(result.folio || null);
      setEnrollment(prev => ({ ...prev, status: 'completed' }));
      if (reloadEnrollmentStudents) await reloadEnrollmentStudents();
      toast.success('Matrícula finalizada exitosamente', { id: 'finalize-enrollment' });
    } catch (error) {
      console.error('Error finalizing enrollment:', error?.message || error);
      const rawMessage = error?.message || '';
      const isDuplicateFeeError = rawMessage.includes('unique_fee_student_guardian_quota') || rawMessage.includes('duplicate key value') || rawMessage.includes('ya existen cuotas');
      setFinalizeAlert({
        type: 'error',
        message: isDuplicateFeeError
          ? 'No se pudo finalizar la matrícula porque ya existen cuotas generadas para este estudiante y apoderado. Verifica que no hayas finalizado esta matrícula antes o que no existan cuotas duplicadas para este alumno. Si el problema persiste, contacta al administrador indicando el RUT del alumno y del apoderado.'
          : rawMessage || 'Error al finalizar matrícula',
      });
    } finally {
      setFinalizing(false);
    }
  }, [enrollment, setEnrollment, reloadEnrollmentStudents, students, studentEconomicMap, availableYearCourses]);

  // ---------- ENROLLMENT RECEIPT ----------

  const _buildReceiptStudents = useCallback(() => {
    return students.map(s => {
      const econ = studentEconomicMap?.[s.id];
      const cursoId = econ?.curso_sugerido;
      let courseName = s.target_course || s.curso_nombre || s.curso;
      if (cursoId && Array.isArray(availableYearCourses)) {
        const found = availableYearCourses.find(c => c.id === cursoId);
        if (found) courseName = found.nom_curso || `${found.nivel || ''} ${found.letra_curso || ''}`.trim();
      }
      return { name: s.whole_name || `${s.first_name} ${s.last_name}`, nivel: s.target_nivel || s.nivel, course: courseName };
    });
  }, [students, studentEconomicMap, availableYearCourses]);

  const handleDownloadEnrollmentReceipt = useCallback(async () => {
    if (!enrollmentFolio || !guardian) return;
    try {
      toast.loading('Generando comprobante...', { id: 'receipt-dl' });
      const receiptData = {
        folio: enrollmentFolio,
        guardianName: `${guardian.first_name} ${guardian.last_name}`,
        guardianRun: guardian.run,
        guardianEmail: guardian.email,
        year: enrollment?.year || year,
        createdAt: new Date().toISOString(),
        students: _buildReceiptStudents(),
      };
      await generateEnrollmentReceiptPdf(receiptData, 'download');
      toast.success('Comprobante descargado', { id: 'receipt-dl' });
    } catch (error) {
      console.error('Error downloading receipt:', error?.message || error);
      toast.error(error?.message?.includes('folio') ? 'Falta el número de folio. Por favor, finalice la matrícula primero.' : 'Error al generar el comprobante de matrícula. Por favor, intente nuevamente.', { id: 'receipt-dl' });
    }
  }, [enrollmentFolio, guardian, enrollment, year, _buildReceiptStudents]);

  const handleEmailEnrollmentReceipt = useCallback(async () => {
    if (!enrollmentFolio || !guardian?.email) return;
    try {
      setSendingEnrollmentReceipt(true);
      toast.loading('Enviando comprobante...', { id: 'receipt-email' });

      const guardianFullName = `${guardian.first_name} ${guardian.last_name}`.trim();
      const studentNames = (Array.isArray(students) ? students : []).map(s => (s?.whole_name || `${s?.first_name || ''} ${s?.last_name || ''}`.trim()).trim()).filter(Boolean);
      const studentsLabel = studentNames.length ? studentNames.join(', ') : 'estudiante(s)';

      const emailSubject = `Comprobante de Matrícula ${year} — Folio ${enrollmentFolio}`;
      const emailBodyHtml = [
        `<p>Hola ${guardianFullName || 'Apoderado(a)'},</p>`,
        `<p>Adjuntamos el comprobante de matrícula del/los estudiante(s) <strong>${studentsLabel}</strong> correspondiente al año <strong>${enrollment?.year || year}</strong>.</p>`,
        `<p>Folio: <strong>${enrollmentFolio}</strong></p>`,
        `<p>Saludos,<br/>Colegio Winterhill</p>`,
      ].join('');

      const receiptData = {
        folio: enrollmentFolio,
        guardianName: guardianFullName,
        guardianRun: guardian.run,
        guardianEmail: guardian.email,
        year: enrollment?.year || year,
        createdAt: new Date().toISOString(),
        students: _buildReceiptStudents(),
      };

      const html = buildEnrollmentReceiptHtml(receiptData);

      let pdfBlob;
      try {
        pdfBlob = await generatePDFFromHTML({ htmlContent: html, orientation: 'portrait', format: 'a4', margin: 0, includeHeader: false, includeSignatureSection: false, folioNumber: enrollmentFolio });
      } catch (pdfError) {
        console.warn('PDF generation failed, falling back to HTML email:', pdfError?.message || pdfError);
        await sendEmailViaFunction({ to: guardian.email, subject: emailSubject, html, type: 'comprobante' });
        toast.success('Comprobante enviado como correo HTML (PDF no disponible)', { id: 'receipt-email' });
        return;
      }

      const base64 = await blobToBase64(pdfBlob);
      await sendEmailViaFunction({
        to: guardian.email, subject: emailSubject, html: emailBodyHtml, type: 'comprobante',
        attachments: [{ filename: `Comprobante_Matricula_${enrollmentFolio}.pdf`, content: base64, type: 'application/pdf' }],
      });
      toast.success('Comprobante enviado por correo', { id: 'receipt-email', duration: 8000 });
    } catch (error) {
      console.error('Error emailing receipt:', error?.message || error);
      const errMsg = error?.message || '';
      if (errMsg.includes('tardó demasiado') || errMsg.includes('PDF service error')) toast.error(errMsg, { id: 'receipt-email', duration: 6000 });
      else if (errMsg.includes('email') || errMsg.includes('mail')) toast.error('Error al enviar el correo. Verifique que su dirección de correo sea válida o intente nuevamente más tarde.', { id: 'receipt-email' });
      else toast.error('Error al enviar el comprobante por correo. Por favor, descárguelo manualmente.', { id: 'receipt-email' });
    } finally {
      setSendingEnrollmentReceipt(false);
    }
  }, [enrollmentFolio, guardian, students, enrollment, year, _buildReceiptStudents]);

  return {
    previewHtml,
    setPreviewHtml,
    previewParts,
    setPreviewParts,
    documentRecord,
    setDocumentRecord,
    sendingPagare,
    autoDocSyncing,
    // Finalize
    finalizing,
    finalizeOpen,
    setFinalizeOpen,
    finalizePreview,
    finalizeAlert,
    setFinalizeAlert,
    enrollmentFolio,
    sendingEnrollmentReceipt,
    showSuccessModal,
    setShowSuccessModal,
    // Handlers
    handleGeneratePagare,
    handleDownloadPDF,
    handlePrint,
    handleDownloadIndividualPDF,
    handleSendPagareEmail,
    handleSign,
    handleFinalizePreview,
    handleFinalizeConfirm,
    handleDownloadEnrollmentReceipt,
    handleEmailEnrollmentReceipt,
  };
}
