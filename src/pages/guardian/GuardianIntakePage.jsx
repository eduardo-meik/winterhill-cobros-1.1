import React, { useEffect, useState, useCallback, useRef } from 'react';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { fetchCurrentIntake, saveIntakeDraft, submitIntake } from '../../services/guardianIntake';
import { normalizeRun, validateRun, formatRunDisplay } from '../../utils/rut';
import { useGuardianData } from '../../contexts/GuardianContext';

// Basic required fields for validation before submit
const REQUIRED_FIELDS = [
  'guardian_first_name',
  'guardian_last_name_paterno',
  'guardian_relationship',
  'guardian_rut',
  'guardian_email',
  'guardian_phone',
  'student_first_names',
  'student_last_name_paterno',
  'student_run',
  'student_course',
  'student_birth_date'
];

const EMPTY_FORM = {
  guardian_first_name: '',
  guardian_last_name_paterno: '',
  guardian_last_name_materno: '',
  guardian_relationship: '',
  guardian_rut: '',
  guardian_education_level: '',
  guardian_address: '',
  guardian_commune: '',
  guardian_email: '',
  guardian_phone: '',
  student_first_names: '',
  student_last_name_paterno: '',
  student_last_name_materno: '',
  student_run: '',
  student_course: '',
  student_birth_date: '',
  student_nationality: '',
  student_gender: '',
  student_social_name: '',
  student_enrollment_date: '',
  student_previous_institution: '',
  student_address: '',
  student_commune: '',
  student_lives_with: [],
  alt_contact_name: '',
  alt_contact_phone: '',
  scholarship_percentage: '',
  payment_form_prioritario: false,
  payment_form_cheques: false,
  payment_form_pagare: false,
  payment_form_credit_card: false,
  payment_form_transfer: false,
  payment_form_planilla: false,
  financial_institution: ''
};

const ARRAY_FIELDS = ['student_lives_with'];
const BOOLEAN_FIELDS = [
  'payment_form_prioritario',
  'payment_form_cheques',
  'payment_form_pagare',
  'payment_form_credit_card',
  'payment_form_transfer',
  'payment_form_planilla'
];
const NUMERIC_STRING_FIELDS = ['scholarship_percentage'];

const normalizeForm = (raw = {}) => {
  const normalized = { ...EMPTY_FORM };
  Object.keys(EMPTY_FORM).forEach((key) => {
    const defaultValue = EMPTY_FORM[key];
    const value = Object.prototype.hasOwnProperty.call(raw, key) ? raw[key] : defaultValue;
    if (ARRAY_FIELDS.includes(key)) {
      if (Array.isArray(value)) {
        normalized[key] = value.map((v) => (v == null ? '' : String(v).trim())).filter(Boolean);
      } else if (typeof value === 'string') {
        normalized[key] = value.split(/[,|;]/).map((v) => v.trim()).filter(Boolean);
      } else {
        normalized[key] = [];
      }
    } else if (BOOLEAN_FIELDS.includes(key)) {
      normalized[key] = Boolean(value);
    } else if (NUMERIC_STRING_FIELDS.includes(key)) {
      normalized[key] = value === null || value === undefined ? '' : String(value);
    } else {
      normalized[key] = value === null || value === undefined ? '' : String(value);
    }
  });
  return normalized;
};

function Section({ title, children }) {
  return (
    <div className="border rounded-md p-4 space-y-4 bg-white shadow-sm">
      <h2 className="text-lg font-semibold tracking-tight">{title}</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">{children}</div>
    </div>
  );
}

function Field({ label, children, required }) {
  return (
    <label className="flex flex-col gap-1 text-sm font-medium">
      <span>{label}{required && <span className="text-red-500"> *</span>}</span>
      {children}
    </label>
  );
}

export const GuardianIntakePage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { data: bootstrapData, loading: bootstrapLoading, refresh: refreshGuardianData } = useGuardianData();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState('draft');
  const [errors, setErrors] = useState({});
  const autosaveTimer = useRef(null);
  const lastSavedSnapshot = useRef(null);
  const [form, setForm] = useState(() => normalizeForm());
  const initializedRef = useRef(false);

  const applyPrefillFallbacks = useCallback((baseForm) => {
    let updated = normalizeForm(baseForm);
    const guardian = bootstrapData?.guardian;
    if (guardian) {
      if (!updated.guardian_rut && guardian.run) updated.guardian_rut = formatRunDisplay(guardian.run);
      if (!updated.guardian_address && guardian.address) updated.guardian_address = guardian.address;
      if (!updated.guardian_phone && guardian.phone) updated.guardian_phone = guardian.phone;
      if (!updated.guardian_email && guardian.email) updated.guardian_email = guardian.email;
      if (!updated.guardian_commune && guardian.comuna) updated.guardian_commune = guardian.comuna;
      const firstName = guardian.first_name || '';
      const lastName = guardian.last_name || '';
      if (!updated.guardian_first_name && firstName) updated.guardian_first_name = firstName;
      if (!updated.guardian_last_name_paterno && lastName) {
        const tokens = lastName.trim().split(/\s+/);
        updated.guardian_last_name_paterno = tokens[0] || lastName;
        if (!updated.guardian_last_name_materno && tokens.length > 1) {
          updated.guardian_last_name_materno = tokens.slice(1).join(' ');
        }
      }
      if (!updated.guardian_relationship) {
        updated.guardian_relationship = guardian.family_tie || guardian.relationship_type || '';
      }
    }

    const student = bootstrapData?.students?.[0];
    if (student) {
      if (!updated.student_first_names && student.first_name) {
        updated.student_first_names = student.first_name;
      }
      if (!updated.student_last_name_paterno && student.last_name) {
        const tokens = (student.last_name || '').trim().split(/\s+/).filter(Boolean);
        updated.student_last_name_paterno = tokens[0] || '';
        if (!updated.student_last_name_materno && tokens.length > 1) {
          updated.student_last_name_materno = tokens.slice(1).join(' ');
        }
      }
      if (!updated.student_run && student.run) {
        updated.student_run = formatRunDisplay(student.run);
      }
      if (!updated.student_course && student.curso_label) {
        updated.student_course = student.curso_label;
      }
      if (!updated.student_birth_date && student.date_of_birth) {
        updated.student_birth_date = student.date_of_birth;
      }
      if (!updated.student_nationality && student.nacionalidad) updated.student_nationality = student.nacionalidad;
      if (!updated.student_gender && student.genero) updated.student_gender = student.genero;
      if (!updated.student_social_name && student.nombre_social) updated.student_social_name = student.nombre_social;
      if (!updated.student_address && student.direccion) updated.student_address = student.direccion;
      if (!updated.student_commune && student.comuna) updated.student_commune = student.comuna;
      if (!updated.student_previous_institution && student.institucion_procedencia) {
        updated.student_previous_institution = student.institucion_procedencia;
      }
      if (!updated.student_lives_with.length && student.convive_con) {
        updated.student_lives_with = student.convive_con
          .split(/[,|;]/)
          .map((token) => token.trim())
          .filter(Boolean);
      }
    }

    return normalizeForm(updated);
  }, [bootstrapData]);

  // load existing draft
  useEffect(() => {
    let ignore = false;
    const load = async () => {
      if (!user || bootstrapLoading || initializedRef.current) return;
      setLoading(true);
      try {
        const existing = await fetchCurrentIntake();
        if (ignore) return;
        const intakeSource = existing || bootstrapData?.intake || null;
        if (intakeSource) {
          setStatus(intakeSource.status ?? 'draft');
        }
        const merged = normalizeForm({
          ...EMPTY_FORM,
          ...(intakeSource || {}),
          scholarship_percentage: intakeSource?.scholarship_percentage ?? ''
        });
        const prefilled = applyPrefillFallbacks(merged);
        setForm(prefilled);
        lastSavedSnapshot.current = JSON.stringify(prefilled);
        initializedRef.current = true;
      } catch (e) {
        toast.error('Error cargando encuesta');
      } finally {
        if (!ignore) setLoading(false);
      }
    };
    load();
    return () => { ignore = true; };
  }, [user, bootstrapLoading, bootstrapData, applyPrefillFallbacks]);

  const updateField = (name, value) => {
    setForm((prev) => {
      const next = normalizeForm({ ...prev, [name]: value });
      if (status !== 'submitted') {
        if (autosaveTimer.current) clearTimeout(autosaveTimer.current);
        autosaveTimer.current = setTimeout(() => {
          autosaveTimer.current = null;
          const snapshot = JSON.stringify(next);
          if (snapshot === lastSavedSnapshot.current) return;
          doSave(true, next);
        }, 1200);
      }
      return next;
    });
  };

  const toggleLivesWith = (option) => {
    setForm((prev) => {
      const current = new Set(prev.student_lives_with || []);
      if (current.has(option)) current.delete(option); else current.add(option);
      const next = normalizeForm({ ...prev, student_lives_with: Array.from(current) });
      if (status !== 'submitted') {
        if (autosaveTimer.current) clearTimeout(autosaveTimer.current);
        autosaveTimer.current = setTimeout(() => {
          autosaveTimer.current = null;
          const snapshot = JSON.stringify(next);
          if (snapshot === lastSavedSnapshot.current) return;
          doSave(true, next);
        }, 1200);
      }
      return next;
    });
  };

  const doSave = useCallback(async (silent = false, nextFormState = null) => {
    setSaving(true);
    try {
      const currentForm = nextFormState ? normalizeForm(nextFormState) : form;
      const payload = {
        ...currentForm,
        scholarship_percentage: currentForm.scholarship_percentage === ''
          ? null
          : Number(currentForm.scholarship_percentage)
      };
      const saved = await saveIntakeDraft(payload);
      setStatus(saved.status);
      const normalizedSaved = normalizeForm({
        ...currentForm,
        ...saved,
        scholarship_percentage: saved?.scholarship_percentage ?? currentForm.scholarship_percentage
      });
      lastSavedSnapshot.current = JSON.stringify(normalizedSaved);
      setForm(normalizedSaved);
      if (!silent) toast.success('Borrador guardado');
    } catch (e) {
      if (!silent) toast.error('Error guardando');
    } finally {
      setSaving(false);
      }
    }, [form]);

    useEffect(() => {
      return () => {
        if (autosaveTimer.current) {
          clearTimeout(autosaveTimer.current);
          autosaveTimer.current = null;
        }
      };
    }, []);

  // Validate required + RUTs
  useEffect(() => {
  const newErrors = {};
    REQUIRED_FIELDS.forEach(f => {
      const v = form[f];
      if (v === undefined || v === null || (typeof v === 'string' && v.trim() === '')) newErrors[f] = 'Requerido';
    });
    if (form.guardian_rut) {
      const { valid } = validateRun(form.guardian_rut);
      if (!valid) newErrors.guardian_rut = 'RUT inválido';
    }
    if (form.student_run) {
      const { valid } = validateRun(form.student_run);
      if (!valid) newErrors.student_run = 'RUN inválido';
    }
    setErrors(newErrors);
  }, [form]);

  const missingRequired = Object.keys(errors).filter(k => errors[k] === 'Requerido');

  const canSubmit = missingRequired.length === 0 && status !== 'submitted';

  const doSubmit = async () => {
    if (!canSubmit) {
      toast.error('Completa los campos obligatorios');
      return;
    }
    setSubmitting(true);
    try {
      // ensure latest draft persisted before submit
      await doSave();
      await submitIntake();
      setStatus('submitted');
      toast.success('Encuesta enviada');
      await refreshGuardianData({ force: true });
      navigate('/apoderado/matricula', { replace: true });
    } catch (e) {
      toast.error('Error al enviar');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="p-6">Cargando encuesta...</div>;

  return (
    <div className="max-w-5xl mx-auto p-6 space-y-8">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Encuesta Anual de Ingreso</h1>
          <p className="text-sm text-gray-600">Año {new Date().getFullYear()} · Estado: <span className="font-medium capitalize">{status}</span></p>
          {status !== 'submitted' && missingRequired.length > 0 && (
            <p className="text-xs text-red-600 mt-1">Faltan {missingRequired.length} campos obligatorios</p>
          )}
        </div>
        <div className="flex gap-2">
          {status !== 'submitted' && (
            <>
              <button
                onClick={doSave}
                disabled={saving}
                className="px-4 py-2 rounded-md bg-gray-200 hover:bg-gray-300 text-sm disabled:opacity-60"
              >{saving ? 'Guardando...' : 'Guardar Borrador'}</button>
              <button
                onClick={doSubmit}
                disabled={!canSubmit || submitting}
                className="px-4 py-2 rounded-md bg-primary text-white text-sm disabled:opacity-60"
              >{submitting ? 'Enviando...' : 'Enviar Encuesta'}</button>
            </>
          )}
          {status === 'submitted' && <span className="text-green-600 text-sm font-medium">Enviada</span>}
        </div>
      </div>

      <Section title="Datos del Apoderado">
        <Field label="Nombres" required><input value={form.guardian_first_name} onChange={e=>updateField('guardian_first_name', e.target.value)} className="input" /></Field>
        <Field label="Apellido Paterno" required><input value={form.guardian_last_name_paterno} onChange={e=>updateField('guardian_last_name_paterno', e.target.value)} className="input" /></Field>
        <Field label="Apellido Materno"><input value={form.guardian_last_name_materno} onChange={e=>updateField('guardian_last_name_materno', e.target.value)} className="input" /></Field>
        <Field label="Relación con el estudiante" required>
          <select value={form.guardian_relationship} onChange={e=>updateField('guardian_relationship', e.target.value)} className="input">
            <option value="">Seleccione...</option>
            <option value="madre">Madre</option>
            <option value="padre">Padre</option>
            <option value="tutor">Tutor</option>
            <option value="otro">Otro</option>
          </select>
        </Field>
        <Field label="RUT" required>
          <input
            value={form.guardian_rut}
            onChange={e=>updateField('guardian_rut', e.target.value)}
            onBlur={e=>{
              if (!e.target.value) return;
              const norm = normalizeRun(e.target.value);
              const vr = validateRun(norm);
              updateField('guardian_rut', vr.valid ? formatRunDisplay(norm) : e.target.value);
            }}
            className={`input ${errors.guardian_rut ? 'border-red-400' : ''}`}
            placeholder="12.345.678-9"
          />
          {errors.guardian_rut && <span className="text-xs text-red-600">{errors.guardian_rut}</span>}
        </Field>
        <Field label="Nivel Educacional"><input value={form.guardian_education_level} onChange={e=>updateField('guardian_education_level', e.target.value)} className="input" /></Field>
        <Field label="Dirección"><input value={form.guardian_address} onChange={e=>updateField('guardian_address', e.target.value)} className="input" /></Field>
        <Field label="Comuna"><input value={form.guardian_commune} onChange={e=>updateField('guardian_commune', e.target.value)} className="input" /></Field>
        <Field label="Email" required><input type="email" value={form.guardian_email} onChange={e=>updateField('guardian_email', e.target.value)} className="input" /></Field>
        <Field label="Teléfono" required><input value={form.guardian_phone} onChange={e=>updateField('guardian_phone', e.target.value)} className="input" /></Field>
      </Section>

      <Section title="Datos del Estudiante">
        <Field label="Nombres" required><input value={form.student_first_names} onChange={e=>updateField('student_first_names', e.target.value)} className="input" /></Field>
        <Field label="Apellido Paterno" required><input value={form.student_last_name_paterno} onChange={e=>updateField('student_last_name_paterno', e.target.value)} className="input" /></Field>
        <Field label="Apellido Materno"><input value={form.student_last_name_materno} onChange={e=>updateField('student_last_name_materno', e.target.value)} className="input" /></Field>
        <Field label="RUN Estudiante" required>
          <input
            value={form.student_run}
            onChange={e=>updateField('student_run', e.target.value)}
            onBlur={e=>{
              if (!e.target.value) return;
              const norm = normalizeRun(e.target.value);
              const vr = validateRun(norm);
              updateField('student_run', vr.valid ? formatRunDisplay(norm) : e.target.value);
            }}
            className={`input ${errors.student_run ? 'border-red-400' : ''}`}
          />
          {errors.student_run && <span className="text-xs text-red-600">{errors.student_run}</span>}
        </Field>
        <Field label="Curso" required><input value={form.student_course} onChange={e=>updateField('student_course', e.target.value)} className="input" placeholder="Ej: 3° Básico" /></Field>
        <Field label="Fecha Nacimiento" required><input type="date" value={form.student_birth_date || ''} onChange={e=>updateField('student_birth_date', e.target.value)} className="input" /></Field>
        <Field label="Nacionalidad"><input value={form.student_nationality} onChange={e=>updateField('student_nationality', e.target.value)} className="input" /></Field>
        <Field label="Género"><input value={form.student_gender} onChange={e=>updateField('student_gender', e.target.value)} className="input" /></Field>
        <Field label="Nombre Social"><input value={form.student_social_name} onChange={e=>updateField('student_social_name', e.target.value)} className="input" /></Field>
        <Field label="Fecha de Matrícula"><input type="date" value={form.student_enrollment_date || ''} onChange={e=>updateField('student_enrollment_date', e.target.value)} className="input" /></Field>
        <Field label="Institución Anterior"><input value={form.student_previous_institution} onChange={e=>updateField('student_previous_institution', e.target.value)} className="input" /></Field>
        <Field label="Dirección"><input value={form.student_address} onChange={e=>updateField('student_address', e.target.value)} className="input" /></Field>
        <Field label="Comuna"><input value={form.student_commune} onChange={e=>updateField('student_commune', e.target.value)} className="input" /></Field>
        <div className="md:col-span-2">
          <Field label="Con quién vive el estudiante">
            <div className="flex flex-wrap gap-2">
              {['madre','padre','apoderado','hermanos','abuelos','otro'].map(opt => (
                <button
                  key={opt}
                  type="button"
                  onClick={()=>toggleLivesWith(opt)}
                  className={`px-3 py-1 rounded-full border text-xs ${form.student_lives_with.includes(opt) ? 'bg-primary text-white border-primary' : 'bg-white'}`}
                >{opt}</button>
              ))}
            </div>
          </Field>
        </div>
      </Section>

      <Section title="Contacto Alternativo y Becas">
        <Field label="Nombre Contacto Alternativo"><input value={form.alt_contact_name} onChange={e=>updateField('alt_contact_name', e.target.value)} className="input" /></Field>
        <Field label="Teléfono Contacto Alternativo"><input value={form.alt_contact_phone} onChange={e=>updateField('alt_contact_phone', e.target.value)} className="input" /></Field>
        <Field label="Porcentaje Beca"><input type="number" min="0" max="100" value={form.scholarship_percentage} onChange={e=>updateField('scholarship_percentage', e.target.value)} className="input" /></Field>
        <Field label="Institución Financiera (si aplica)"><input value={form.financial_institution} onChange={e=>updateField('financial_institution', e.target.value)} className="input" /></Field>
      </Section>

      <Section title="Forma de Pago Preferida">
        <div className="col-span-1 md:col-span-2 grid grid-cols-2 md:grid-cols-3 gap-3">
          {[
            ['payment_form_prioritario','Prioritario'],
            ['payment_form_cheques','Cheques'],
            ['payment_form_pagare','Pagaré'],
            ['payment_form_credit_card','Tarjeta Crédito'],
            ['payment_form_transfer','Transferencia'],
            ['payment_form_planilla','Planilla']
          ].map(([key,label]) => (
            <label key={key} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={!!form[key]}
                onChange={e=>updateField(key, e.target.checked)}
              />
              <span>{label}</span>
            </label>
          ))}
        </div>
      </Section>

      {status !== 'submitted' && (
        <div className="flex gap-3 justify-end pt-2">
          <button
            onClick={doSave}
            disabled={saving}
            className="px-5 py-2 rounded-md bg-gray-200 hover:bg-gray-300 text-sm disabled:opacity-60"
          >{saving ? 'Guardando...' : 'Guardar Borrador'}</button>
          <button
            onClick={doSubmit}
            disabled={!canSubmit || submitting}
            className="px-5 py-2 rounded-md bg-primary text-white text-sm disabled:opacity-60"
          >{submitting ? 'Enviando...' : 'Enviar Encuesta'}</button>
        </div>
      )}

      {status === 'submitted' && (
        <div className="p-4 border rounded bg-green-50 text-green-700 text-sm">Encuesta enviada correctamente. Gracias.</div>
      )}
    </div>
  );
};

export default GuardianIntakePage;
