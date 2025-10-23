import { supabase } from './supabase';
import toast from 'react-hot-toast';

// Types (lightweight to avoid adding global type deps now)
export interface GuardianRecord {
  id: string;
  owner_id: string;
  first_name?: string;
  last_name?: string;
  run?: string;
  email?: string;
  address?: string;
  phone?: string;
  relationship_type?: string;
  tipo_apoderado?: string;
  comuna?: string;
  date_birth?: string;
  nivel_educacional?: string;
  family_tie?: string;
}

export interface StudentRecord {
  id: string;
  whole_name?: string;
  run?: string;
  curso?: string; // assembled client-side if needed
  curso_id?: string;
  first_name?: string;
  last_name?: string;
  grade?: string;
  date_of_birth?: string;
}

export interface GuardianLinkedStudent {
  id: string;
  first_name: string | null;
  last_name: string | null;
  whole_name: string | null;
  run: string | null;
  date_of_birth: string | null;
  grade: string | null;
  curso_id: string | null;
  curso_label: string | null;
  nombre_social: string | null;
  genero: string | null;
  nacionalidad: string | null;
  direccion: string | null;
  comuna: string | null;
  convive_con: string | null;
}

export interface EnrollmentRecord {
  id: string;
  guardian_id: string;
  year: number;
  status: string;
  meta: any;
}

export interface DocumentTemplate {
  id: string;
  type: string;
  version: number;
  title: string | null;
  content: string;
  placeholders: string[];
  active: boolean;
}

export interface EnrollmentDocumentRecord {
  id: string;
  enrollment_id: string;
  type: string;
  template_version: number;
  status: string;
  pdf_url: string | null;
  storage_path: string | null;
  generated_payload: any;
  signed_at?: string | null;
  final_content?: string | null;
  content_hash?: string | null;
  pdf_hash?: string | null;
}

// Caching & safe single-attempt RPC creation flags (avoid spamming console when function missing)
let _guardianCache: Record<string, GuardianRecord | null | undefined> = {};
let _guardianFetchInFlight: Record<string, Promise<GuardianRecord | null> | undefined> = {};
let _missingEnsureGuardianFn = false;
let _attemptedAutoCreate: Record<string, boolean> = {};

// 1. Fetch guardian for current user (assuming one guardian per owner/user)
export async function fetchCurrentGuardian(userId: string): Promise<GuardianRecord | null> {
  if (!userId) return null;
  if (_guardianCache[userId] !== undefined) return _guardianCache[userId] || null;
  if (Object.prototype.hasOwnProperty.call(_guardianFetchInFlight, userId) && _guardianFetchInFlight[userId]) {
    return _guardianFetchInFlight[userId] as Promise<GuardianRecord | null>;
  }

  _guardianFetchInFlight[userId] = (async () => {
    try {
      const { data, error } = await supabase
        .from('guardians')
        .select('*')
        .eq('owner_id', userId)
        .limit(1);
      if (error) {
        console.error('fetchCurrentGuardian error', error);
        toast.error('Error cargando apoderado');
        _guardianCache[userId] = null;
        return null;
      }
      let guardian = data?.[0] || null;

      // Auto-create attempt only if function exists (skip if previously flagged missing)
      if (!guardian && !_missingEnsureGuardianFn && !_attemptedAutoCreate[userId]) {
        _attemptedAutoCreate[userId] = true;
        try {
          const { data: rpcRes, error: rpcErr } = await supabase.rpc('ensure_guardian_for_user');
          if (rpcErr) {
            // If 404 / PGRST202 function not found, mark so we don't retry
            if (rpcErr.code === 'PGRST202') {
              _missingEnsureGuardianFn = true;
              // Silent after first detection
              console.warn('[guardians] RPC ensure_guardian_for_user ausente. Omite auto-creación. Puedes crearla o desactivar este flujo.');
            } else {
              console.error('RPC ensure_guardian_for_user error', rpcErr);
            }
          } else if (rpcRes) {
            // Re-query once if RPC succeeded
            const { data: again, error: againErr } = await supabase
              .from('guardians')
              .select('*')
              .eq('owner_id', userId)
              .limit(1);
            if (!againErr) guardian = again?.[0] || null;
          }
        } catch (e) {
          // swallow unexpected errors to avoid loop; guardian stays null
        }
      }
      _guardianCache[userId] = guardian;
      return guardian;
    } finally {
      delete _guardianFetchInFlight[userId];
    }
  })();

  return _guardianFetchInFlight[userId];
}

// 2. Get or create enrollment for guardian/year
export async function getOrCreateEnrollment(guardianId: string, year: number): Promise<EnrollmentRecord | null> {
  // Try select first
  let { data: existing, error: selError } = await supabase
    .from('enrollments')
    .select('*')
    .eq('guardian_id', guardianId)
    .eq('year', year)
    .limit(1);
  if (selError) {
    console.error('getOrCreateEnrollment select error', selError);
    toast.error('No se pudo revisar matrícula existente');
    return null;
  }
  if (existing && existing.length) return existing[0];

  const { data, error } = await supabase
    .from('enrollments')
    .insert({ guardian_id: guardianId, year, status: 'draft', meta: {} })
    .select()
    .single();
  if (error) {
    console.error('getOrCreateEnrollment insert error', error);
    toast.error('No se pudo crear matrícula');
    return null;
  }
  return data;
}

// 3. Manage enrollment_students
export async function listEnrollmentStudents(enrollmentId: string): Promise<StudentRecord[]> {
  type Row = { student_id: string; students: { id: string; whole_name?: string; run?: string } | null };
  const { data, error } = await supabase
    .from('enrollment_students')
    .select('student_id, students:student_id(id, whole_name, run)')
    .eq('enrollment_id', enrollmentId) as { data: Row[] | null; error: any };
  if (error) {
    console.error('listEnrollmentStudents error', error);
    toast.error('Error cargando alumnos de la matrícula');
    return [];
  }
  return (data || []).map(r => ({ id: r.students?.id || r.student_id, whole_name: r.students?.whole_name, run: r.students?.run }));
}

export async function fetchGuardianStudents(guardianId: string): Promise<GuardianLinkedStudent[]> {
  if (!guardianId) return [];
  const { data: links, error: linkErr } = await supabase
    .from('student_guardian')
    .select('student_id')
    .eq('guardian_id', guardianId);
  if (linkErr) {
    console.error('fetchGuardianStudents link error', linkErr);
    return [];
  }
  const studentIds = (links || []).map(l => l.student_id).filter(Boolean);
  if (!studentIds.length) return [];

  // Fetch students WITHOUT curso join first (to avoid RLS issues)
  const { data: studentRows, error: studentsErr } = await supabase
    .from('students')
    .select(`
      id,
      first_name,
      apellido_paterno,
      apellido_materno,
      whole_name,
      run,
      date_of_birth,
      nivel,
      curso,
      nombre_social,
      genero,
      nacionalidad,
      direccion,
      comuna,
      con_quien_vive,
      institucion_procedencia
    `)
    .in('id', studentIds);
  
  if (studentsErr) {
    console.error('fetchGuardianStudents students error', studentsErr);
    return [];
  }

  // Fetch curso names separately if needed
  const cursoIds = (studentRows || []).map(s => s.curso).filter(Boolean);
  let cursoMap: Record<string, string> = {};
  
  if (cursoIds.length > 0) {
    const { data: cursoRows } = await supabase
      .from('cursos')
      .select('id, nom_curso')
      .in('id', cursoIds);
    
    if (cursoRows) {
      cursoMap = cursoRows.reduce((acc: any, c: any) => {
        acc[c.id] = c.nom_curso;
        return acc;
      }, {});
    }
  }

  return (studentRows || []).map((row: any) => {
    const lastName = [row.apellido_paterno, row.apellido_materno].filter(Boolean).join(' ').trim() || null;
    return {
      id: row.id,
      first_name: row.first_name ?? null,
      last_name: lastName,
      whole_name: row.whole_name ?? null,
      run: row.run ?? null,
      date_of_birth: row.date_of_birth ?? null,
      grade: row.nivel ?? null,
      curso_id: row.curso ?? null,
      curso_label: (row.curso ? cursoMap[row.curso] : null) ?? row.nivel ?? null,
      nombre_social: row.nombre_social ?? null,
      genero: row.genero ?? null,
      nacionalidad: row.nacionalidad ?? null,
      direccion: row.direccion ?? null,
      comuna: row.comuna ?? null,
      convive_con: row.con_quien_vive ?? null,
      institucion_procedencia: row.institucion_procedencia ?? null
    };
  });
}

export async function addStudentToEnrollment(enrollmentId: string, studentId: string) {
  const { error } = await supabase
    .from('enrollment_students')
    .insert({ enrollment_id: enrollmentId, student_id: studentId });
  if (error) {
    if (error.code === '23505') { // duplicate
      toast('Alumno ya está agregado');
      return;
    }
    console.error('addStudentToEnrollment error', error);
    toast.error('No se pudo agregar alumno');
  } else {
    toast.success('Alumno agregado');
  }
}

export async function removeStudentFromEnrollment(enrollmentId: string, studentId: string) {
  const { error } = await supabase
    .from('enrollment_students')
    .delete()
    .eq('enrollment_id', enrollmentId)
    .eq('student_id', studentId);
  if (error) {
    console.error('removeStudentFromEnrollment error', error);
    toast.error('No se pudo remover alumno');
  } else {
    toast.success('Alumno removido');
  }
}

// 4. Economic meta update
export async function updateEnrollmentMeta(enrollmentId: string, metaPatch: Record<string, any>) {
  const { data: existing, error: selError } = await supabase
    .from('enrollments')
    .select('meta')
    .eq('id', enrollmentId)
    .single();
  if (selError) {
    console.error('updateEnrollmentMeta select error', selError);
    toast.error('No se pudo leer matrícula');
    return;
  }
  const newMeta = { ...(existing?.meta || {}), ...metaPatch };
  const { error } = await supabase
    .from('enrollments')
    .update({ meta: newMeta })
    .eq('id', enrollmentId);
  if (error) {
    console.error('updateEnrollmentMeta update error', error);
    toast.error('No se pudo actualizar datos económicos');
  } else {
    toast.success('Datos guardados');
  }
}

// 5. Templates
export async function getActivePagareTemplate(): Promise<DocumentTemplate | null> {
  const { data, error } = await supabase
    .from('document_templates')
    .select('*')
    .eq('type', 'PAGARE')
    .eq('active', true)
    .order('version', { ascending: false })
    .limit(1);
  if (error) {
    console.error('getActivePagareTemplate error', error);
    toast.error('No se pudo cargar plantilla Pagaré');
    return null;
  }
  return data?.[0] || null;
}

// 6. Payload builder
export interface PagarePayload {
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_phone: string;
  year: number;
  students_table: string; // HTML fragment
  colegiatura_anual?: number;
  cantidad_cuotas?: number;
  monto_cuota?: number;
  dia_vencimiento?: number;
  [k: string]: any;
}

export function buildPagarePayload(opts: {
  guardian: GuardianRecord;
  year: number;
  students: StudentRecord[];
  economic?: { colegiatura_anual?: number; cantidad_cuotas?: number; monto_cuota?: number; dia_vencimiento?: number };
}): PagarePayload {
  const { guardian, year, students, economic } = opts;
  const tableRows = students.map((s, idx) => `<tr><td>${idx + 1}</td><td>${escapeHtml(s.whole_name || '')}</td><td>${escapeHtml(s.run || '')}</td><td>${escapeHtml(s.curso || '')}</td></tr>`).join('');
  const studentsTable = `<table><thead><tr><th>#</th><th>Nombre</th><th>RUN</th><th>Curso</th></tr></thead><tbody>${tableRows}</tbody></table>`;
  return {
    guardian_full_name: [guardian.first_name, guardian.last_name].filter(Boolean).join(' ') || '—',
    guardian_run: guardian.run || '—',
    guardian_address: guardian.address || '—',
    guardian_email: guardian.email || '—',
    guardian_phone: guardian.phone || '—',
    year,
    students_table: studentsTable,
    ...economic
  };
}

// 7. Render template with placeholders {{key}}
export function renderTemplate(raw: string, payload: Record<string, any>): string {
  return raw.replace(/{{\s*([a-zA-Z0-9_]+)\s*}}/g, (_m, key) => {
    const v = payload[key];
    if (v === undefined || v === null) return `{{${key}}}`; // leave marker if missing
    return typeof v === 'string' ? v : String(v);
  });
}

// 8. Create enrollment document (PAGARE)
export async function createPagareDocument(params: {
  enrollmentId: string;
  template: DocumentTemplate;
  payload: PagarePayload;
  finalContent: string;
  contentHash?: string; // computed client-side (e.g., SHA-256)
}): Promise<EnrollmentDocumentRecord | null> {
  const { enrollmentId, template, payload, finalContent, contentHash } = params;
  const insertObj: any = {
    enrollment_id: enrollmentId,
    type: 'PAGARE',
    template_version: template.version,
    status: 'generated',
    generated_payload: payload,
    final_content: finalContent,
    content_hash: contentHash || null
  };
  const { data, error } = await supabase
    .from('enrollment_documents')
    .insert(insertObj)
    .select()
    .single();
  if (error) {
    console.error('createPagareDocument error', error);
    toast.error('No se pudo crear el documento');
    return null;
  }
  toast.success('Pagaré generado');
  return data;
}

// 9. Sign document (guardian)
export async function signEnrollmentDocument(documentId: string, method: 'checkbox' | 'drawn' | 'upload', signerUserId?: string) {
  const { error: signErr } = await supabase
    .from('signatures')
    .insert({ enrollment_document_id: documentId, signer_type: 'GUARDIAN', signer_user_id: signerUserId || null, method });
  if (signErr) {
    console.error('signEnrollmentDocument error', signErr);
    toast.error('No se pudo registrar la firma');
    return false;
  }
  const { error: updErr } = await supabase
    .from('enrollment_documents')
    .update({ status: 'signed', signed_at: new Date().toISOString() })
    .eq('id', documentId);
  if (updErr) {
    console.error('signEnrollmentDocument update error', updErr);
    toast.error('Firma registrada, pero fallo actualización de estado');
    return false;
  }
  toast.success('Documento firmado');
  return true;
}

// Utility simple HTML escape
function escapeHtml(str: string): string {
  return str.replace(/[&<>"]+/g, s => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[s] as string));
}

// (Optional future) compute SHA-256 hash of a string (browser SubtleCrypto)
export async function sha256(text: string): Promise<string> {
  const enc = new TextEncoder().encode(text);
  const buf = await crypto.subtle.digest('SHA-256', enc);
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}
