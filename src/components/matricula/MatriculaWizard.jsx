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
import { supabase } from '../../services/supabase';

// Simple wizard steps definition
const STEPS = [
  'Seleccionar Año y Alumnos',
  'Datos Económicos',
  'Generar Pagaré',
  'Revisar y Firmar'
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
    colegiatura_anual: '',
    cantidad_cuotas: '10',
    monto_cuota: '',
    dia_vencimiento: '5'
  });
  const [step, setStep] = useState(0);
  const [template, setTemplate] = useState(null);
  const [previewHtml, setPreviewHtml] = useState('');
  const [documentRecord, setDocumentRecord] = useState(null);
  const [loading, setLoading] = useState(false);

  // Load guardian & enrollment baseline
  useEffect(() => {
    if (!user) return;
    (async () => {
      setLoading(true);
      const g = await fetchCurrentGuardian(user.id);
      if (!g) { setLoading(false); return; }
      setGuardian(g);
      const enr = await getOrCreateEnrollment(g.id, year);
      if (enr) setEnrollment(enr);
      setLoading(false);
    })();
  }, [user, year]);

  // Load enrolled students & potential students (simplified: all students joined to guardian via student_guardian)
  const reloadEnrollmentStudents = useCallback(async () => {
    if (!enrollment) return;
    const list = await listEnrollmentStudents(enrollment.id);
    setStudents(list);
  }, [enrollment]);

  useEffect(() => { reloadEnrollmentStudents(); }, [reloadEnrollmentStudents]);

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
      colegiatura_anual: Number(economic.colegiatura_anual) || 0,
      cantidad_cuotas: Number(economic.cantidad_cuotas) || 0,
      monto_cuota: Number(economic.monto_cuota) || 0,
      dia_vencimiento: Number(economic.dia_vencimiento) || 0
    };
    await updateEnrollmentMeta(enrollment.id, patch);
    if (!economic.monto_cuota && patch.colegiatura_anual && patch.cantidad_cuotas) {
      const calc = (patch.colegiatura_anual / patch.cantidad_cuotas).toFixed(0);
      setEconomic(e => ({ ...e, monto_cuota: calc }));
    }
  };

  // Generate pagaré preview
  const handleGeneratePagare = async () => {
    if (!guardian || !enrollment) return;
    setLoading(true);
    const tmpl = await getActivePagareTemplate();
    if (!tmpl) { setLoading(false); return; }
    setTemplate(tmpl);
    const econNumbers = {
      colegiatura_anual: Number(economic.colegiatura_anual) || undefined,
      cantidad_cuotas: Number(economic.cantidad_cuotas) || undefined,
      monto_cuota: Number(economic.monto_cuota) || undefined,
      dia_vencimiento: Number(economic.dia_vencimiento) || undefined,
    };
    const payload = buildPagarePayload({ guardian, year, students, economic: econNumbers });
    const html = renderTemplate(tmpl.content, payload).replace('{{students_table}}', payload.students_table);
    setPreviewHtml(html);
    // Create doc record now (without PDF yet)
    const contentHash = await sha256(html);
    const doc = await createPagareDocument({ enrollmentId: enrollment.id, template: tmpl, payload, finalContent: html, contentHash });
    setDocumentRecord(doc);
    setLoading(false);
    if (doc) setStep(3); // jump to final step for review & sign
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

      {/* STEP 1 */}
      {step === 1 && (
        <Card>
          <CardHeader>
            <h2 className="font-semibold">Datos Económicos</h2>
          </CardHeader>
          <CardContent className="space-y-4 text-sm">
            <div className="grid md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs mb-1">Coleg. Anual (CLP)</label>
                <input className="w-full border rounded px-2 py-1" value={economic.colegiatura_anual} onChange={e => setEconomic({ ...economic, colegiatura_anual: e.target.value })} />
              </div>
              <div>
                <label className="block text-xs mb-1">Cantidad Cuotas</label>
                <input className="w-full border rounded px-2 py-1" value={economic.cantidad_cuotas} onChange={e => setEconomic({ ...economic, cantidad_cuotas: e.target.value })} />
              </div>
              <div>
                <label className="block text-xs mb-1">Monto por Cuota (CLP)</label>
                <input className="w-full border rounded px-2 py-1" value={economic.monto_cuota} onChange={e => setEconomic({ ...economic, monto_cuota: e.target.value })} />
              </div>
              <div>
                <label className="block text-xs mb-1">Día Vencimiento (1-28)</label>
                <input className="w-full border rounded px-2 py-1" value={economic.dia_vencimiento} onChange={e => setEconomic({ ...economic, dia_vencimiento: e.target.value })} />
              </div>
            </div>
            <Button onClick={handleSaveEconomic}>Guardar Datos</Button>
          </CardContent>
        </Card>
      )}

      {/* STEP 2 */}
      {step === 2 && (
        <Card>
          <CardHeader>
            <h2 className="font-semibold">Generar Pagaré</h2>
          </CardHeader>
            <CardContent className="space-y-4 text-sm">
              <p className="text-gray-600 dark:text-gray-400">Se construirá el documento usando la plantilla activa y los datos ingresados.</p>
              <Button onClick={handleGeneratePagare} disabled={loading}>Generar Documento</Button>
            </CardContent>
        </Card>
      )}

      {/* STEP 3 */}
      {step === 3 && (
        <Card>
          <CardHeader className="flex items-center justify-between">
            <h2 className="font-semibold">Revisión y Firma</h2>
            {documentRecord?.status === 'signed' && <span className="text-xs px-2 py-1 rounded bg-green-600 text-white">Firmado</span>}
          </CardHeader>
          <CardContent className="space-y-4">
            {!previewHtml && <p className="text-sm text-gray-500">Aún no hay contenido</p>}
            {previewHtml && (
              <div className="border rounded p-3 max-h-[500px] overflow-auto prose prose-sm dark:prose-invert bg-white dark:bg-dark/40 shadow-inner" dangerouslySetInnerHTML={{ __html: previewHtml.replace(/\n/g, '<br/>') }} />
            )}
            <div className="flex gap-2">
              {documentRecord?.status !== 'signed' && <Button onClick={handleSign} disabled={loading}>Firmar</Button>}
              <Button variant="outline" onClick={() => { setStep(2); }}>Regenerar</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Navigation */}
      <div className="flex justify-between pt-2">
        <Button variant="outline" onClick={back} disabled={step === 0}>Atrás</Button>
        {step < 2 && <Button onClick={next} disabled={!canProceed()}>Siguiente</Button>}
      </div>
    </main>
  );
}

export default MatriculaWizard;
