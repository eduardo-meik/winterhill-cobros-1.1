import React, { useEffect, useState, useCallback } from 'react';
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
  signEnrollmentDocument,
  sha256
} from '../../services/matricula';
import { generatePDFFromHTML, downloadPDFBlob } from '../../services/pdfGenerator';
import { supabase } from '../../services/supabase';

// Simple wizard steps definition
const STEPS = [
  'Seleccionar Alumnos',
  'Datos Económicos',
  'Vista Previa y Descarga'
];

export function MatriculaWizard() {
  const { user } = useAuth();
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState(currentYear);
  const [guardian, setGuardian] = useState(null);
  const [enrollment, setEnrollment] = useState(null);
  const [students, setStudents] = useState([]);
  const [allMyStudents, setAllMyStudents] = useState([]); // potential associated students via student_guardian
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
    tarjeta: false
  });
  const [step, setStep] = useState(0);
  const [template, setTemplate] = useState(null);
  const [previewHtml, setPreviewHtml] = useState('');
  const [documentRecord, setDocumentRecord] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Assisted mode (ADMIN/ASIST)
  const assistedMode = user?.profile === 'ADMIN' || user?.profile === 'ASIST';
  const [assistedGuardian, setAssistedGuardian] = useState(null);
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
          g = await fetchCurrentGuardian(user.id);
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
    
    // Load payment methods
    setPaymentMethod(prev => ({
      ...prev,
      cheques: enrollment.meta.forma_pago_cheques ?? prev.cheques,
      transferencia: enrollment.meta.forma_pago_transferencia ?? prev.transferencia,
      efectivo: enrollment.meta.forma_pago_efectivo ?? prev.efectivo,
      tarjeta: enrollment.meta.forma_pago_tarjeta ?? prev.tarjeta
    }));
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

  const loadAssociatedStudents = useCallback(async () => {
    if (!guardian) return;
    const { data, error } = await supabase
      .from('student_guardian')
      .select(`student_id, students:student_id(id, whole_name, run)`) // adjust as needed
      .eq('guardian_id', guardian.id);
    if (error) {
      console.error('loadAssociatedStudents error', error);
      return;
    }
    const list = (data || []).map(r => ({ id: r.students?.id, whole_name: r.students?.whole_name, run: r.students?.run }));
    setAllMyStudents(list);
  }, [guardian]);

  useEffect(() => { loadAssociatedStudents(); }, [loadAssociatedStudents]);

  // Step navigation guards
  const canProceed = () => {
    if (step === 0) return students.length > 0; // need at least one student
    if (step === 1) return economic.colegiatura_anual && economic.cantidad_cuotas && economic.dia_vencimiento;
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
      forma_pago_tarjeta: paymentMethod.tarjeta || false
    };
    
    console.log('💾 Guardando datos económicos y formas de pago:', patch);
    await updateEnrollmentMeta(enrollment.id, patch);
    
    // Auto-calculate monto_cuota if not provided
    if (!economic.monto_cuota && patch.colegiatura_anual && patch.cantidad_cuotas) {
      const calc = Math.round(patch.colegiatura_anual / patch.cantidad_cuotas);
      setEconomic(e => ({ ...e, monto_cuota: calc.toString() }));
    }
    
    toast.success('Datos económicos guardados correctamente');
  };

  // Generate pagaré HTML preview (no PDF yet)
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
    
    const tmpl = await getActivePagareTemplate();
    if (!tmpl) { 
      setLoading(false); 
      toast.error('No se encontró plantilla activa');
      return; 
    }
    
    console.log('📄 Template loaded:');
    console.log('  - ID:', tmpl.id);
    console.log('  - Type:', tmpl.type);
    console.log('  - Version:', tmpl.version);
    console.log('  - Content length:', tmpl.content?.length || 0);
    console.log('  - Content preview (first 300 chars):', tmpl.content?.substring(0, 300));
    
    setTemplate(tmpl);
    const econNumbers = {
      monto_matricula: Number(economic.monto_matricula) || undefined,
      colegiatura_anual: Number(economic.colegiatura_anual) || undefined,
      cantidad_cuotas: Number(economic.cantidad_cuotas) || undefined,
      monto_cuota: Number(economic.monto_cuota) || undefined,
      dia_vencimiento: Number(economic.dia_vencimiento) || undefined,
    };
    
    console.log('💵 Economic numbers parsed:', JSON.stringify(econNumbers, null, 2));
    
    const payload = buildPagarePayload({ 
      guardian, 
      year, 
      students, 
      economic: econNumbers,
      paymentMethod 
    });
    
    console.log('📦 Payload COMPLETO generated:', JSON.stringify(payload, null, 2));
    
    const html = renderTemplate(tmpl.content, payload);
    
    console.log('📄 HTML AFTER renderTemplate (length):', html.length);
    console.log('📄 HTML AFTER renderTemplate (first 500 chars):', html.substring(0, 500));
    console.log('📄 Checking if placeholders were replaced:');
    console.log('  - Contains {{fecha_actual}}?', html.includes('{{fecha_actual}}'));
    console.log('  - Contains {{guardian_full_name}}?', html.includes('{{guardian_full_name}}'));
    console.log('  - Contains {{guardian_run}}?', html.includes('{{guardian_run}}'));
    
    setPreviewHtml(html);
    
    // Create document record (HTML only, PDF generated client-side on download)
    const contentHash = await sha256(html);
    const doc = await createPagareDocument({ 
      enrollmentId: enrollment.id, 
      template: tmpl, 
      payload, 
      finalContent: html, 
      contentHash
    });
    setDocumentRecord(doc);
    setLoading(false);
    if (doc) {
      setStep(2); // Stay on step 2 to show HTML preview (was step 3 before)
      toast.success('Vista previa generada. Revise el documento antes de descargar.');
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
      
      // Generate PDF from HTML (client-side, no server upload)
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: previewHtml,
        includeHeader: true,
        includeSignatureSection: true,
        watermark: documentRecord?.status === 'signed' ? undefined : 'NO FIRMADO',
        guardianRun: guardian.run
      });
      
      // Download directly
      downloadPDFBlob(pdfBlob, `Pagare_${year}_${guardian?.run || 'documento'}.pdf`);
      
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

  // Sign document
  const handleSign = async () => {
    if (!documentRecord) return;
    setLoading(true);
    const ok = await signEnrollmentDocument(documentRecord.id, 'checkbox', user?.id);
    setLoading(false);
    if (ok) {
      toast.success('Pagaré firmado');
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

      {/* STEP 0 */}
      {step === 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">Seleccionar Año y Alumnos</h2>
              <div className="flex items-center gap-2">
                <label className="text-sm">Año:</label>
                <input type="number" value={year} onChange={e => setYear(Number(e.target.value))} className="w-28 px-2 py-1 border rounded" />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h3 className="font-medium mb-2 text-sm">Mis Alumnos Asociados</h3>
                <ul className="space-y-1 max-h-72 overflow-auto text-sm">
                  {allMyStudents.map(st => (
                    <li key={st.id} className="flex items-center justify-between gap-2 bg-gray-50 dark:bg-dark/40 px-2 py-1 rounded">
                      <span>{st.whole_name || st.run}</span>
                      <Button variant="outline" size="xs" onClick={() => handleAddStudent(st.id)}>Agregar</Button>
                    </li>
                  ))}
                  {allMyStudents.length === 0 && <li className="text-gray-500">No hay alumnos asociados</li>}
                </ul>
              </div>
              <div>
                <h3 className="font-medium mb-2 text-sm">Alumnos en la Matrícula</h3>
                <ul className="space-y-1 max-h-72 overflow-auto text-sm">
                  {students.map(st => (
                    <li key={st.id} className="flex items-center justify-between gap-2 bg-primary/5 dark:bg-primary/10 px-2 py-1 rounded">
                      <span>{st.whole_name || st.run}</span>
                      <Button variant="destructive" size="xs" onClick={() => handleRemoveStudent(st.id)}>Quitar</Button>
                    </li>
                  ))}
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
            {/* Economic Data Section */}
            <div>
              <h3 className="font-medium text-base mb-3 text-gray-700 dark:text-gray-300">💰 Información Económica</h3>
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs mb-1 font-medium">Monto Matrícula (CLP)</label>
                  <input 
                    type="number" 
                    className="w-full border rounded px-2 py-1" 
                    value={economic.monto_matricula} 
                    onChange={e => setEconomic({ ...economic, monto_matricula: e.target.value })} 
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
                    placeholder="Ej: 5"
                  />
                </div>
              </div>
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
                    onChange={e => setPaymentMethod({ ...paymentMethod, cheques: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>📝 Cheques</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.transferencia} 
                    onChange={e => setPaymentMethod({ ...paymentMethod, transferencia: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💸 Transferencia Electrónica</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.efectivo} 
                    onChange={e => setPaymentMethod({ ...paymentMethod, efectivo: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💵 Pago en Efectivo</span>
                </label>
                <label className="flex items-center gap-2 p-3 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800">
                  <input 
                    type="checkbox" 
                    checked={paymentMethod.tarjeta} 
                    onChange={e => setPaymentMethod({ ...paymentMethod, tarjeta: e.target.checked })} 
                    className="w-4 h-4"
                  />
                  <span>💳 Tarjeta de Crédito</span>
                </label>
              </div>
            </div>

            <Button onClick={handleSaveEconomic} className="mt-4">💾 Guardar Datos</Button>
          </CardContent>
        </Card>
      )}

      {/* STEP 2: Preview Pagaré and Generate PDF */}
      {step === 2 && (
        <Card>
          <CardHeader className="flex items-center justify-between">
            <h2 className="font-semibold">Vista Previa del Pagaré</h2>
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
                <Button onClick={handleGeneratePagare} disabled={loading || students.length === 0}>
                  📄 Generar Vista Previa
                </Button>
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
                  <div 
                    className="border-2 border-gray-300 dark:border-gray-600 rounded-lg p-6 max-h-[600px] overflow-auto bg-white dark:bg-gray-800 shadow-lg prose prose-sm dark:prose-invert max-w-none"
                    style={{ fontFamily: 'Arial, sans-serif' }}
                    dangerouslySetInnerHTML={{ __html: previewHtml.replace(/\n/g, '<br/>') }} 
                  />
                </div>

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
                      onClick={() => { setStep(1); setPreviewHtml(''); setDocumentRecord(null); }}
                      disabled={loading}
                    >
                      ✏️ Editar Datos
                    </Button>
                  </div>
                  <div className="mt-4 pt-4 border-t border-blue-200 dark:border-blue-700">
                    <p className="text-xs text-blue-600 dark:text-blue-400">
                      💡 <strong>Importante:</strong> El PDF se genera con formato profesional incluyendo:
                    </p>
                    <ul className="text-xs text-blue-600 dark:text-blue-400 mt-2 ml-4 space-y-1">
                      <li>✓ Logo y datos del colegio</li>
                      <li>✓ Secciones con bordes profesionales</li>
                      <li>✓ Áreas de firma para apoderado y corporación</li>
                      <li>✓ Marca de agua "NO FIRMADO" (hasta firmar digitalmente)</li>
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
          {step < 2 && <Button onClick={next} disabled={!canProceed() || loading}>Siguiente</Button>}
        </div>
      )}
        </>
      )}
    </main>
  );
}

export default MatriculaWizard;
