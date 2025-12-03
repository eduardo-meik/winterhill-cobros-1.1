import { supabase } from './supabase';
import { computeEnrollmentDocumentPlan } from './autodoc';
import { templates } from '../contracts/templates';
import toast from 'react-hot-toast';
import type { GuardianIntakeRecord } from './guardianIntake';
import { normalizeRun, validateRun, isRutFormatValid, formatRunDisplay } from '../utils/rut';

// Types (lightweight to avoid adding global type deps now)
export interface GuardianRecord {
  id: string;
  owner_id: string | null;
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
  nacionalidad?: string;
  profesion?: string;
  estado_civil?: string;
}

export interface StudentRecord {
  id: string;
  whole_name?: string;
  run?: string;
  curso?: string; // UUID del curso
  curso_nombre?: string; // Nombre del curso (ej: "4° MEDIO A")
  curso_id?: string;
  first_name?: string;
  last_name?: string;
  grade?: string;
  nivel?: string;
  date_of_birth?: string;
}

export interface PaymentMethodFlags {
  cheques?: boolean;
  transferencia?: boolean;
  efectivo?: boolean;
  tarjeta?: boolean;
  pagare?: boolean;
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
let _attemptedManualCreate: Record<string, boolean> = {};

// 1. Fetch guardian for current user (assuming one guardian per owner/user)
export async function fetchCurrentGuardian(userId: string, userEmail?: string | null): Promise<GuardianRecord | null> {
  console.log('🔍 fetchCurrentGuardian called with userId:', userId, 'userEmail:', userEmail);
  if (!userId) return null;
  if (_guardianCache[userId] !== undefined) {
    console.log('🔍 fetchCurrentGuardian: Returning from cache:', _guardianCache[userId]);
    return _guardianCache[userId] || null;
  }
  if (Object.prototype.hasOwnProperty.call(_guardianFetchInFlight, userId) && _guardianFetchInFlight[userId]) {
    console.log('🔍 fetchCurrentGuardian: Returning existing promise');
    return _guardianFetchInFlight[userId] as Promise<GuardianRecord | null>;
  }

  _guardianFetchInFlight[userId] = (async () => {
    try {
      console.log('🔍 fetchCurrentGuardian: Querying database for owner_id:', userId);
      const { data, error } = await supabase
        .from('guardians')
        .select('*')
        .eq('owner_id', userId)
        .limit(1);
      console.log('🔍 fetchCurrentGuardian: Query result - data:', data, 'error:', error);
      if (error) {
        console.error('fetchCurrentGuardian error', error);
        toast.error('Error cargando apoderado');
        _guardianCache[userId] = null;
        return null;
      }
      let guardian = data?.[0] || null;
      console.log('🔍 fetchCurrentGuardian: Guardian from query:', guardian);

      const normalizedEmail = userEmail?.trim().toLowerCase() || '';

      if (!guardian && normalizedEmail) {
        console.log('🔍 fetchCurrentGuardian: Attempting email lookup for:', normalizedEmail);
        const { data: emailMatches, error: emailError } = await supabase
          .from('guardians')
          .select('*')
          .ilike('email', normalizedEmail)
          .limit(1);
        if (emailError) {
          console.error('fetchCurrentGuardian email lookup error', emailError);
        }
        guardian = emailMatches?.[0] || null;
        if (guardian) {
          console.log('🔍 fetchCurrentGuardian: Found guardian by email:', guardian.id);
          if (!guardian.owner_id) {
            const { error: updateError } = await supabase
              .from('guardians')
              .update({ owner_id: userId })
              .eq('id', guardian.id)
              .is('owner_id', null);
            if (updateError) {
              console.warn('🔍 fetchCurrentGuardian: Failed to attach owner_id via email lookup', updateError);
            } else {
              guardian = { ...guardian, owner_id: userId };
            }
          }
        }
      }

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

      if (!guardian && normalizedEmail && !_attemptedManualCreate[userId]) {
        _attemptedManualCreate[userId] = true;
        try {
          const initialNames = normalizedEmail.split('@')[0]?.split('.') || [];
          const sanitizedFirst = initialNames[0]?.replace(/[^a-zA-ZÀ-ÿ\s'-]/g, ' ')?.trim();
          const payload: Partial<GuardianRecord> & { owner_id: string | null; email: string } = {
            owner_id: userId,
            email: normalizedEmail,
            first_name: sanitizedFirst || null,
          } as any;

          const { data: inserted, error: insertError } = await supabase
            .from('guardians')
            .insert(payload)
            .select('*')
            .maybeSingle();

          if (insertError) {
            console.warn('🔍 fetchCurrentGuardian: Manual guardian create failed', insertError);
          } else if (inserted) {
            guardian = inserted as GuardianRecord;
            console.log('🔍 fetchCurrentGuardian: Created guardian placeholder for user:', guardian.id);
          }
        } catch (creationError) {
          console.warn('🔍 fetchCurrentGuardian: Exception during manual guardian create', creationError);
        }
      }
      _guardianCache[userId] = guardian;
      console.log('🔍 fetchCurrentGuardian: Final result - caching and returning:', guardian);
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
    const code = `${(error as any)?.code || ''}`;
    const message = `${(error as any)?.message || ''}`;
    const details = `${(error as any)?.details || ''}`;
    const isDuplicate = code === '23505' || /duplicate/i.test(message) || /duplicate/i.test(details) || /enrollments_guardian_id_year_key/i.test(message + details);

    if (isDuplicate) {
      console.warn('getOrCreateEnrollment detected duplicate, fetching existing row instead');
      const { data: dupeExisting, error: dupeError } = await supabase
        .from('enrollments')
        .select('*')
        .eq('guardian_id', guardianId)
        .eq('year', year)
        .limit(1)
        .single();
      if (!dupeError && dupeExisting) {
        return dupeExisting;
      }
      if (dupeError) {
        console.error('getOrCreateEnrollment duplicate fallback failed', dupeError);
      }
    }

    console.error('getOrCreateEnrollment insert error', error);
    toast.error('No se pudo crear matrícula');
    return null;
  }
  return data;
}

// 3. Manage enrollment_students
export async function listEnrollmentStudents(enrollmentId: string): Promise<StudentRecord[]> {
  try {
    const { data, error } = await supabase
      .from('enrollment_students')
      .select(`
        student_id,
        students (
          id,
          whole_name,
          run,
          curso,
          first_name,
          apellido_paterno,
          apellido_materno,
          date_of_birth,
          cursos:curso (
            id,
            nom_curso,
            nivel,
            letra_curso
          )
        )
      `)
      .eq('enrollment_id', enrollmentId);
    if (error) throw error;
    const rows = (data || []) as Array<{ student_id: string; students: any | null }>;
    const mapped: StudentRecord[] = rows
      .map(r => r.students)
      .filter(Boolean)
      .map((s: any): StudentRecord => {
        const apellidosStr = [s.apellido_paterno, s.apellido_materno].filter(Boolean).join(' ').trim();
  const lastName: string | undefined = apellidosStr ? apellidosStr : undefined;
        const full = s.whole_name || [s.first_name, lastName ?? ''].filter(Boolean).join(' ').trim();
        const c = s.cursos || null;
        const cursoLabel = c?.nom_curso
          || (c ? `${c.nivel ?? ''}${c.letra_curso ? ' ' + c.letra_curso : ''}`.trim() : null)
          || s.curso
          || null;
        const obj: StudentRecord = {
          id: s.id as string,
          whole_name: (full || undefined) as string | undefined,
          run: (s.run || undefined) as string | undefined,
          curso: (s.curso || undefined) as string | undefined,
          curso_nombre: (cursoLabel || undefined) as string | undefined,
          first_name: (s.first_name || undefined) as string | undefined,
          grade: (c?.nivel || undefined) as string | undefined,
          nivel: (c?.nivel || undefined) as string | undefined,
          date_of_birth: (s.date_of_birth || undefined) as string | undefined
        };
        if (lastName) obj.last_name = lastName;
        return obj;
      });
    return mapped;
  } catch (e) {
    console.error('listEnrollmentStudents error', e);
    toast.error('No se pudieron cargar los alumnos de la matrícula');
    return [] as StudentRecord[];
  }
}

// Add a student to an enrollment (idempotent)
export async function addStudentToEnrollment(enrollmentId: string, studentId: string): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('enrollment_students')
      .insert({ enrollment_id: enrollmentId, student_id: studentId });
    if (error) {
      // Ignore unique violation gracefully (already added)
      const code = `${(error as any).code || ''}`;
      const msg = (error as any).message || '';
      const details = (error as any).details || '';
      const isDuplicate = code === '23505' || code === '409' || /duplicate/i.test(msg) || /duplicate/i.test(details);
      if (!isDuplicate) {
        console.error('addStudentToEnrollment error', error);
        toast.error('No se pudo agregar el alumno');
        return false;
      }
    }
    return true;
  } catch (e) {
    console.error('addStudentToEnrollment exception', e);
    toast.error('Error inesperado al agregar alumno');
    return false;
  }
}

// Remove a student from an enrollment
export async function removeStudentFromEnrollment(enrollmentId: string, studentId: string): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('enrollment_students')
      .delete()
      .eq('enrollment_id', enrollmentId)
      .eq('student_id', studentId);
    if (error) {
      console.error('removeStudentFromEnrollment error', error);
      toast.error('No se pudo quitar el alumno');
      return false;
    }
    return true;
  } catch (e) {
    console.error('removeStudentFromEnrollment exception', e);
    toast.error('Error inesperado al quitar alumno');
    return false;
  }
}

// Update enrollment.meta merging existing JSON with a patch
export async function updateEnrollmentMeta(enrollmentId: string, patch: Record<string, any>): Promise<boolean> {
  try {
    const { data: existing, error: selErr } = await supabase
      .from('enrollments')
      .select('meta')
      .eq('id', enrollmentId)
      .limit(1)
      .single();
    if (selErr) throw selErr;
    const currentMeta = (existing?.meta as any) || {};
    const merged = { ...currentMeta, ...patch };
    const { error: updErr } = await supabase
      .from('enrollments')
      .update({ meta: merged })
      .eq('id', enrollmentId);
    if (updErr) throw updErr;
    return true;
  } catch (e) {
    console.error('updateEnrollmentMeta error', e);
    toast.error('No se pudo actualizar los datos económicos');
    return false;
  }
}

// Fetch latest active PAGARE template
export async function getActivePagareTemplate(): Promise<DocumentTemplate | null> {
  try {
    const { data, error } = await supabase
      .from('document_templates')
      .select('*')
      .eq('type', 'PAGARE')
      .eq('active', true)
      .order('version', { ascending: false })
      .limit(1)
      .single();
    if (error) throw error;
    return data as unknown as DocumentTemplate;
  } catch (e) {
    console.error('getActivePagareTemplate error', e);
    toast.error('No se pudo cargar la plantilla del Pagaré');
    return null;
  }
}

// List students linked to a guardian (via student_guardian)
export async function fetchGuardianStudents(guardianId: string): Promise<Array<{
  id: string;
  whole_name?: string | null;
  first_name?: string | null;
  last_name?: string | null;
  run?: string | null;
  curso_id?: string | null;
  curso_label?: string | null;
  date_of_birth?: string | null;
  genero?: string | null;
  nombre_social?: string | null;
  nacionalidad?: string | null;
  direccion?: string | null;
  comuna?: string | null;
  institucion_procedencia?: string | null;
  convive_con?: string | null;
}> > {
  try {
    const { data, error } = await supabase
      .from('student_guardian')
      .select(`
        student_id,
        students (
          id,
          whole_name,
          first_name,
          apellido_paterno,
          apellido_materno,
          run,
          curso,
          date_of_birth,
          genero,
          nombre_social,
          nacionalidad,
          direccion,
          comuna,
          institucion_procedencia,
          convive_con,
          cursos:curso (
            id,
            nom_curso,
            nivel,
            letra_curso
          )
        )
      `)
      .eq('guardian_id', guardianId);
    if (error) throw error;
    const rows = (data || []) as Array<{ student_id: string; students: any | null }>;
    return rows
      .map(r => r.students)
      .filter(Boolean)
      .map((s: any) => {
        const c = s.cursos || null;
        const label = c?.nom_curso
          || (c ? `${c.nivel ?? ''}${c.letra_curso ? ' ' + c.letra_curso : ''}`.trim() : null)
          || s.curso
          || null;
        const apellidos = [s.apellido_paterno, s.apellido_materno].filter(Boolean).join(' ').trim() || null;
        return {
          id: s.id,
          whole_name: s.whole_name || null,
          first_name: s.first_name || null,
          last_name: apellidos,
          run: s.run || null,
          curso_id: c?.id || s.curso || null,
          curso_label: label,
          date_of_birth: s.date_of_birth || null,
          genero: s.genero || null,
          nombre_social: s.nombre_social || null,
          nacionalidad: s.nacionalidad || null,
          direccion: s.direccion || null,
          comuna: s.comuna || null,
          institucion_procedencia: s.institucion_procedencia || null,
          convive_con: s.convive_con || null
        };
      });
  } catch (e) {
    console.error('fetchGuardianStudents error', e);
    toast.error('No se pudieron cargar los alumnos vinculados');
    return [];
  }
}

// 6. Payload builder
export interface PagarePayload {
  // Fecha actual
  fecha_actual: string;
  
  // Guardian data
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_phone: string;
  guardian_nacionalidad: string;
  guardian_profesion: string;
  guardian_estado_civil: string;
  
  // Year
  year: number;
  
  // Students table
  students_table: string; // HTML fragment
  // Students list (plain text-like block used by some templates)
  students_list?: string;
  
  // Economic data
  monto_matricula?: number | string;
  colegiatura_anual?: number | string;
  colegiatura_anual_texto?: string;
  cantidad_cuotas?: number | string;
  monto_cuota?: number | string;
  monto_cuota_texto?: string;
  dia_vencimiento?: number | string;
  
  // Payment method (from survey)
  forma_pago_cheques?: string;
  forma_pago_transferencia?: string;
  forma_pago_efectivo?: string;
  forma_pago_tarjeta?: string;
  
  [k: string]: any;
}

export function buildPagarePayload(opts: {
  guardian: GuardianRecord;
  year: number;
  students: StudentRecord[];
  economic?: { 
    monto_matricula?: number;
    colegiatura_anual?: number; 
    cantidad_cuotas?: number; 
    monto_cuota?: number; 
    dia_vencimiento?: number;
  };
  paymentMethod?: {
    cheques?: boolean;
    transferencia?: boolean;
    efectivo?: boolean;
    tarjeta?: boolean;
  };
  cheques?: Array<{
    numero_cuota?: number;
    numero_serie?: string;
    banco?: string;
    fecha_emision?: string;
    monto?: number;
    notas?: string;
  }>;
  chequeData?: {
    numero_serie?: string;
    banco?: string;
    fecha_emision?: string;
    monto?: number;
    notas?: string;
  } | null;
}): PagarePayload {
  const { guardian, year, students, economic, paymentMethod, cheques, chequeData } = opts;
  
  // Format current date in Spanish
  const now = new Date();
  const day = now.getDate();
  const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 
                  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  const month = months[now.getMonth()];
  const yearFull = now.getFullYear();
  const fecha_actual = `${day} de ${month} del ${yearFull}`;
  
  // Build students table HTML
  const tableRows = students.map((s, idx) => {
    // Prioritize curso_nombre (from JOIN), fallback to grade, nivel, or curso UUID
    const cursoDisplay = s.curso_nombre || s.grade || s.nivel || s.curso || 'Sin curso asignado';
    return `<tr><td>${idx + 1}</td><td>${escapeHtml(s.whole_name || s.first_name || '')}</td><td>${escapeHtml(s.run || '')}</td><td>${escapeHtml(cursoDisplay)}</td></tr>`;
  }).join('');
  
  const studentsTable = `<table border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse;">
    <thead>
      <tr style="background-color: #f0f0f0;">
        <th>Número</th>
        <th>Nombre</th>
        <th>RUT</th>
        <th>Curso año ${year}</th>
      </tr>
    </thead>
    <tbody>${tableRows}</tbody>
  </table>`;
  // Also provide a compact students list block (used by some annex templates)
  const studentsListBlock = buildStudentsList(students, year);
  
  // Format numbers with thousand separators
  const formatCurrency = (value?: number | string) => {
    if (!value) return '_______________';
    const num = typeof value === 'string' ? parseFloat(value) : value;
    return num.toLocaleString('es-CL');
  };
  
  // If we have multiple cheques, render a table HTML
  const hasChequesArray = Array.isArray(cheques) && cheques.length > 0;
  const chequesTableHtml = hasChequesArray
    ? (() => {
        const rows = (cheques || []).map((c, i) => {
          const montoFmt = c?.monto ? formatCurrency(c.monto) : '—';
          return `<tr>
            <td>${c?.numero_cuota ?? (i + 1)}</td>
            <td>${escapeHtml(c?.numero_serie || '')}</td>
            <td>${escapeHtml(c?.banco || '')}</td>
            <td>${escapeHtml(c?.fecha_emision || '')}</td>
            <td style="text-align:right;">${montoFmt}</td>
            <td>${escapeHtml(c?.notas || '')}</td>
          </tr>`;
        }).join('');
        return `
          <div style="margin-top: 15px;">
            <strong>Cheques por Cuota</strong>
            <table border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse; margin-top: 5px;">
              <thead>
                <tr style="background-color:#f0f0f0;">
                  <th>Cuota</th>
                  <th>N° Serie</th>
                  <th>Banco</th>
                  <th>Fecha Emisión</th>
                  <th>Monto</th>
                  <th>Notas</th>
                </tr>
              </thead>
              <tbody>${rows}</tbody>
            </table>
          </div>`;
      })()
    : '';

  const firstCheque = hasChequesArray ? (cheques && cheques[0]) : null;

  // Pre-calculate numeric helpers
  const colegAnualNum = economic?.colegiatura_anual !== undefined
    ? (typeof economic.colegiatura_anual === 'string' ? parseFloat(economic.colegiatura_anual) : economic.colegiatura_anual)
    : undefined;

  // Calculate monto_cuota numeric for text rendering
  const montoCuotaCalcNumber = (() => {
    if (economic?.colegiatura_anual && economic?.cantidad_cuotas) {
      const total = typeof economic.colegiatura_anual === 'string' 
        ? parseFloat(economic.colegiatura_anual) 
        : economic.colegiatura_anual;
      const cuotas = typeof economic.cantidad_cuotas === 'string'
        ? parseInt(economic.cantidad_cuotas as any)
        : economic.cantidad_cuotas;
      if (!isNaN(total) && !isNaN(cuotas) && cuotas > 0) {
        return Math.round(total / cuotas);
      }
    }
    const manual = economic?.monto_cuota;
    return typeof manual === 'string' ? parseFloat(manual) : (manual || 0);
  })();

  const payload = {
    fecha_actual,
    guardian_full_name: [guardian.first_name, guardian.last_name]
      .filter((s): s is string => Boolean(s))
      .map(s => s.trim())
      .join(' ') || '_______________',
    guardian_run: guardian.run || '_______________',
    guardian_address: guardian.address || '_______________',
    guardian_email: guardian.email || '_______________',
    guardian_phone: guardian.phone || '_______________',
    guardian_nacionalidad: guardian.nacionalidad || 'Chilena',
    guardian_profesion: guardian.profesion || '_______________',
    guardian_estado_civil: guardian.estado_civil || '_______________',
    year,
    students_table: studentsTable,
    students_list: studentsListBlock,
    monto_matricula: formatCurrency(economic?.monto_matricula),
    colegiatura_anual: formatCurrency(economic?.colegiatura_anual),
    colegiatura_anual_texto: (colegAnualNum !== undefined && isFinite(colegAnualNum)) ? `${numberToWordsEs(Math.round(colegAnualNum))} pesos` : undefined,
    cantidad_cuotas: economic?.cantidad_cuotas?.toString() || '_______________',
    monto_cuota: (() => {
      // Calculate monto_cuota automatically: colegiatura_anual / cantidad_cuotas
      if (economic?.colegiatura_anual && economic?.cantidad_cuotas) {
        const total = typeof economic.colegiatura_anual === 'string' 
          ? parseFloat(economic.colegiatura_anual) 
          : economic.colegiatura_anual;
        const cuotas = typeof economic.cantidad_cuotas === 'string'
          ? parseInt(economic.cantidad_cuotas)
          : economic.cantidad_cuotas;
        
        if (!isNaN(total) && !isNaN(cuotas) && cuotas > 0) {
          const montoPorCuota = Math.round(total / cuotas);
          return formatCurrency(montoPorCuota);
        }
      }
      // Fallback to manual monto_cuota if provided
      return formatCurrency(economic?.monto_cuota) || '_______________';
    })(),
    monto_cuota_texto: isFinite(montoCuotaCalcNumber) ? `${numberToWordsEs(Math.round(montoCuotaCalcNumber))} pesos` : undefined,
    dia_vencimiento: economic?.dia_vencimiento?.toString() || '_______________',
    forma_pago_cheques: paymentMethod?.cheques ? '☑' : '☐',
    forma_pago_transferencia: paymentMethod?.transferencia ? '☑' : '☐',
    forma_pago_efectivo: paymentMethod?.efectivo ? '☐' : '☐',
    forma_pago_tarjeta: paymentMethod?.tarjeta ? '☑' : '☐',
    // Formatted payment methods list (one per line)
    formas_pago_lista: [
      `Cheques: ${paymentMethod?.cheques ? '☑' : '☐'}`,
      `Transferencia Electrónica: ${paymentMethod?.transferencia ? '☑' : '☐'}`,
      `Pago en efectivo: ${paymentMethod?.efectivo ? '☑' : '☐'}`,
      `Tarjeta de Crédito: ${paymentMethod?.tarjeta ? '☑' : '☐'}`
    ].join('\n'),
    // Cheques data (multi or single)
    // For backward compatibility, keep single fields filled from first cheque when array provided
  cheque_numero_serie: hasChequesArray ? (firstCheque?.numero_serie || 'N/A') : (chequeData?.numero_serie || 'N/A'),
  cheque_banco: hasChequesArray ? (firstCheque?.banco || 'N/A') : (chequeData?.banco || 'N/A'),
  cheque_fecha_emision: hasChequesArray ? (firstCheque?.fecha_emision || 'N/A') : (chequeData?.fecha_emision || 'N/A'),
  cheque_monto: hasChequesArray ? (firstCheque?.monto ? formatCurrency(firstCheque.monto) : 'N/A') : (chequeData?.monto ? formatCurrency(chequeData.monto) : 'N/A'),
  cheque_notas: hasChequesArray ? (firstCheque?.notas || '') : (chequeData?.notas || ''),
    // Preferred rich block used by the template
    cheque_info: hasChequesArray ? chequesTableHtml : (chequeData ? `
      <div style="margin-top: 15px; padding: 10px; border: 1px solid #ddd; background-color: #f9f9f9;">
        <strong>Información del Cheque:</strong><br/>
        Número de Serie: ${escapeHtml(chequeData.numero_serie || 'N/A')}<br/>
        Banco: ${escapeHtml(chequeData.banco || 'N/A')}<br/>
        Fecha Emisión: ${chequeData.fecha_emision || 'N/A'}<br/>
        Monto: ${chequeData.monto ? formatCurrency(chequeData.monto) : 'N/A'}
        ${chequeData.notas ? `<br/>Notas: ${escapeHtml(chequeData.notas)}` : ''}
      </div>
    ` : ''),
    // Also expose explicit table key for future templates
    cheques_table: hasChequesArray ? chequesTableHtml : ''
  };

  // Provide optional comuna/city for templates using {{guardian_comuna?}} and {{guardian_city?}}
  const _addr = (guardian.address || '').trim();
  const _com = (guardian.comuna || '').trim();
  (payload as any)['guardian_comuna?'] = _com ? (_addr ? `, ${_com}` : `${_com}`) : '';
  const _city = ((guardian as any).ciudad || (guardian as any).city || '').toString().trim();
  (payload as any)['guardian_city?'] = _city ? ((_addr || _com) ? `, ${_city}` : `${_city}`) : '';
  // Alias phone as guardian_fono when needed by templates (e.g., pagarerepac)
  (payload as any).guardian_fono = guardian.phone || '_______________';
  
  console.log('🔧 buildPagarePayload - Guardian data:', {
    first_name: guardian.first_name,
    last_name: guardian.last_name,
    run: guardian.run,
    address: guardian.address,
    nacionalidad: guardian.nacionalidad,
    profesion: guardian.profesion,
    estado_civil: guardian.estado_civil
  });
  console.log('📅 Fecha actual:', fecha_actual);
  console.log('👥 Students count:', students.length);
  console.log('💰 Economic data:', economic);
  console.log('💳 Payment method:', paymentMethod);
  console.log('✅ Final payload:', payload);
  
  return payload;
}

// ---------- Prestación: helpers and payload ----------
export interface PrestacionPayload {
  fecha_actual: string;
  year: number;
  // Guardian
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_comuna?: string;
  guardian_fono?: string;
  guardian_profesion?: string;
  guardian_estado_civil?: string;
  // Students
  students_table: string;
  students_list: string;
  // Economic
  monto_matricula?: string | number;
  colegiatura_anual?: string | number;
  colegiatura_anual_texto?: string;
  cantidad_cuotas?: string | number;
  monto_cuota?: string | number;
  monto_cuota_texto?: string;
  dia_vencimiento?: string | number;
  // Payment
  forma_pago_cheques?: string;
  forma_pago_transferencia?: string;
  forma_pago_efectivo?: string;
  forma_pago_tarjeta?: string;
  forma_pago_pagare?: string;
  formas_pago_lista: string;
  formas_pago_resumen?: string;
  // Cheques block
  cheques_table?: string;
  // Annex/Pagaré optional
  folio_number?: string;
  [k: string]: any;
}

// minimal Spanish number-to-words (CLP) converter (0..999,999,999)
function numberToWordsEs(n: number): string {
  if (!isFinite(n) || n < 0) return '';
  if (n === 0) return 'cero';
  const unidades = ['','uno','dos','tres','cuatro','cinco','seis','siete','ocho','nueve'];
  const especiales = ['diez','once','doce','trece','catorce','quince','dieciséis','diecisiete','dieciocho','diecinueve'];
  const decenas = ['','','veinte','treinta','cuarenta','cincuenta','sesenta','setenta','ochenta','noventa'];
  const centenas = ['','ciento','doscientos','trescientos','cuatrocientos','quinientos','seiscientos','setecientos','ochocientos','novecientos'];

  const toWordsUnder100 = (x: number): string => {
    if (x < 10) return unidades[x];
    if (x < 20) return especiales[x - 10];
    if (x < 30) return x === 20 ? 'veinte' : 'veinti' + unidades[x - 20];
    const d = Math.floor(x / 10), u = x % 10;
    return decenas[d] + (u ? ' y ' + unidades[u] : '');
  };
  const toWordsUnder1000 = (x: number): string => {
    if (x === 100) return 'cien';
    const c = Math.floor(x / 100), r = x % 100;
    const cpart = c ? centenas[c] : '';
    const rpart = r ? toWordsUnder100(r) : '';
    return [cpart, rpart].filter(Boolean).join(' ').trim();
  };
  const millions = Math.floor(n / 1_000_000);
  const thousands = Math.floor((n % 1_000_000) / 1000);
  const rest = n % 1000;
  const parts: string[] = [];
  if (millions) parts.push(millions === 1 ? 'un millón' : toWordsUnder1000(millions) + ' millones');
  if (thousands) parts.push(thousands === 1 ? 'mil' : toWordsUnder1000(thousands) + ' mil');
  if (rest) parts.push(toWordsUnder1000(rest));
  return parts.join(' ').replace(/\s+/g, ' ').trim();
}

function buildStudentsList(students: StudentRecord[], year: number): string {
  const rows = students.map((s, idx) => {
    const cursoDisplay = s.curso_nombre || s.grade || s.nivel || s.curso || 'Sin curso asignado';
    const name = s.whole_name || s.first_name || '';
    const rut = s.run || '';
    return `${idx + 1}. ${name} — RUT: ${rut} — Curso ${year}: ${cursoDisplay}`;
  }).join('\n');
  return `<pre style="white-space: pre-wrap; font-family: Helvetica, Arial, sans-serif; font-size: 11px; line-height: 1.35;">${rows}</pre>`;
}

export function buildPrestacionPayload(opts: {
  guardian: GuardianRecord;
  year: number;
  students: StudentRecord[];
  economic?: {
    monto_matricula?: number;
    colegiatura_anual?: number;
    cantidad_cuotas?: number;
    monto_cuota?: number;
    dia_vencimiento?: number;
  };
  paymentMethod?: PaymentMethodFlags;
  cheques?: Array<{ numero_cuota?: number; numero_serie?: string; banco?: string; fecha_emision?: string; monto?: number; notas?: string; }>;
  descuento?: {
    porcentaje?: number;
    motivo?: string;
    condiciones?: string;
  } | null;
}): PrestacionPayload {
  const { guardian, year, students, economic, paymentMethod, cheques } = opts;

  const now = new Date();
  const day = now.getDate();
  const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
  const month = months[now.getMonth()];
  const yearFull = now.getFullYear();
  const fecha_actual = `${day} de ${month} del ${yearFull}`;

  const studentsTable = (() => {
    const rows = students.map((s, idx) => {
      const cursoDisplay = s.curso_nombre || s.grade || s.nivel || s.curso || 'Sin curso asignado';
      return `<tr><td>${idx + 1}</td><td>${escapeHtml(s.whole_name || s.first_name || '')}</td><td>${escapeHtml(s.run || '')}</td><td>${escapeHtml(cursoDisplay)}</td></tr>`;
    }).join('');
    return `<table class="table" border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse;">
      <thead>
        <tr style="background-color:#f5f7fa;">
          <th>N°</th><th>Nombre</th><th>RUT</th><th>Curso año ${year}</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>`;
  })();

  const studentsList = buildStudentsList(students, year);

  const formatCurrency = (value?: number | string) => {
    if (value === undefined || value === null || value === '') return '_______________';
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (!isFinite(num)) return '_______________';
    return num.toLocaleString('es-CL');
  };

  const hasChequesArray = Array.isArray(cheques) && cheques.length > 0;
  const chequesTableHtml = hasChequesArray ? (() => {
    const rows = (cheques || []).map((c, i) => {
      const montoFmt = c?.monto ? formatCurrency(c.monto) : '—';
      return `<tr>
        <td>${c?.numero_cuota ?? (i + 1)}</td>
        <td>${escapeHtml(c?.numero_serie || '')}</td>
        <td>${escapeHtml(c?.banco || '')}</td>
        <td>${escapeHtml(c?.fecha_emision || '')}</td>
        <td style="text-align:right;">${montoFmt}</td>
        <td>${escapeHtml(c?.notas || '')}</td>
      </tr>`;
    }).join('');
    return `<div style="margin-top: 10px;">
      <strong>Detalle de Cheques</strong>
      <table border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse; margin-top: 5px;">
        <thead>
          <tr style="background-color:#f5f7fa;"><th>Cuota</th><th>N° Serie</th><th>Banco</th><th>Fecha Emisión</th><th>Monto</th><th>Notas</th></tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>`;
  })() : '';

  const paymentSummaryParts: string[] = [];
  const registerSummaryPart = (condition: boolean | undefined, text: string) => {
    if (condition) paymentSummaryParts.push(text);
  };
  registerSummaryPart(paymentMethod?.cheques, `cheques nominativos a nombre de Corporación Educacional Winterhill, con vencimientos dentro de los primeros diez días de cada mes entre marzo y diciembre ${year}`);
  registerSummaryPart(paymentMethod?.transferencia, 'transferencia electrónica comprometida');
  registerSummaryPart(paymentMethod?.efectivo, 'pago en efectivo');
  registerSummaryPart(paymentMethod?.tarjeta, 'tarjeta de crédito');
  registerSummaryPart(paymentMethod?.pagare, 'pagaré notarial');

  const joinWithConjunction = (items: string[]): string => {
    if (!items.length) return '';
    if (items.length === 1) return items[0];
    const head = items.slice(0, -1).join(', ');
    const tail = items[items.length - 1];
    return head ? `${head} y ${tail}` : tail;
  };

  const paymentSummary = joinWithConjunction(paymentSummaryParts);

  // Si hay datos económicos por alumno en opts (monto_neto_anual_por_alumno), se suma para contratos multi-estudiante.
  const perStudentNetTotals: number[] = (opts as any)?.perStudentEconomic?.map((e: any) => Number(e?.monto_neto_anual) || 0) || [];
  const sumPerStudentNet = perStudentNetTotals.reduce((acc, v) => acc + (Number.isFinite(v) ? v : 0), 0);

  const colegAnualBase = economic?.colegiatura_anual || 0;
  const colegAnual = sumPerStudentNet > 0 ? sumPerStudentNet : colegAnualBase;
  const cuotasNum = Number(economic?.cantidad_cuotas) || 0;
  const montoCuotaCalc = (() => {
    if (economic?.colegiatura_anual && economic?.cantidad_cuotas) {
      const total = Number(economic.colegiatura_anual) || 0;
      const cuotas = Number(economic.cantidad_cuotas) || 0;
      if (total > 0 && cuotas > 0) return Math.round(total / cuotas);
    }
    return economic?.monto_cuota || 0;
  })();

  // Descuento por planilla calculations (if provided)
  const porcentajeDesc = Number(opts.descuento?.porcentaje) || 0;
  const descuentoMotivo = (opts.descuento?.motivo || '').trim();
  const descuentoCondiciones = (opts.descuento?.condiciones || '').trim();
  const montoTotalDescuento = (colegAnual > 0 && porcentajeDesc > 0)
    ? Math.round(colegAnual * (porcentajeDesc / 100))
    : 0;
  const montoNetoAnual = (colegAnual > 0)
    ? Math.max(0, colegAnual - montoTotalDescuento)
    : 0;
  const montoCuotaNetaCalc = (montoNetoAnual > 0 && cuotasNum > 0)
    ? Math.round(montoNetoAnual / cuotasNum)
    : 0;

  const payload: PrestacionPayload = {
    fecha_actual,
    year,
    guardian_full_name: [guardian.first_name, guardian.last_name].filter(Boolean).map(s => (s as string).trim()).join(' ') || '_______________',
    guardian_run: guardian.run || '_______________',
    // Address/comuna handled dynamically to avoid showing guiones when address is missing
    guardian_address: (guardian.address || '').trim(),
    guardian_email: guardian.email || '_______________',
    guardian_comuna: guardian.comuna || undefined,
    guardian_profesion: guardian.profesion || undefined,
    guardian_estado_civil: guardian.estado_civil || undefined,
    students_table: studentsTable,
    students_list: studentsList,
    monto_matricula: formatCurrency(economic?.monto_matricula),
  colegiatura_anual: formatCurrency(colegAnual),
  colegiatura_anual_texto: `${numberToWordsEs(colegAnual)} pesos`,
    cantidad_cuotas: economic?.cantidad_cuotas?.toString() || '_______________',
  monto_cuota: formatCurrency(montoCuotaCalc),
  monto_cuota_texto: `${numberToWordsEs(montoCuotaCalc)} pesos`,
    dia_vencimiento: economic?.dia_vencimiento?.toString() || '_______________',
    forma_pago_cheques: paymentMethod?.cheques ? '☑' : '☐',
    forma_pago_transferencia: paymentMethod?.transferencia ? '☑' : '☐',
    forma_pago_efectivo: paymentMethod?.efectivo ? '☑' : '☐',
    forma_pago_tarjeta: paymentMethod?.tarjeta ? '☑' : '☐',
    forma_pago_pagare: paymentMethod?.pagare ? '☑' : '☐',
    formas_pago_lista: [
      `Cheques: ${paymentMethod?.cheques ? '☑' : '☐'}`,
      `Transferencia Electrónica: ${paymentMethod?.transferencia ? '☑' : '☐'}`,
      `Pago en efectivo: ${paymentMethod?.efectivo ? '☑' : '☐'}`,
      `Tarjeta de Crédito: ${paymentMethod?.tarjeta ? '☑' : '☐'}`,
      `Pagaré: ${paymentMethod?.pagare ? '☑' : '☐'}`
    ].join('\n'),
    formas_pago_resumen: paymentSummary || 'los mecanismos definidos en este contrato',
    cheques_table: chequesTableHtml,
  };

  // Provide optional comuna for templates using {{guardian_comuna?}}
  // If address exists, prepend with comma; if address is empty, render comuna without comma.
  const _addr = (guardian.address || '').trim();
  const _com = (guardian.comuna || '').trim();
  (payload as any)['guardian_comuna?'] = _com ? (_addr ? `, ${_com}` : `${_com}`) : '';

  // Optional city for templates using {{guardian_city?}}. If present, prefix with comma when address/comuna exists
  const _city = ((guardian as any).ciudad || (guardian as any).city || '').toString().trim();
  (payload as any)['guardian_city?'] = _city ? ((_addr || _com) ? `, ${_city}` : `${_city}`) : '';

  // Alias for phone expected by some templates (e.g., pagarerepac.html)
  (payload as any).guardian_fono = guardian.phone || '_______________';

  // Inject descuento placeholders for the Descuento por Planilla annex
  (payload as any).descuento_porcentaje = porcentajeDesc ? String(porcentajeDesc) : '0';
  (payload as any).descuento_motivo = descuentoMotivo || '—';
  (payload as any).condicion_especial_beca = descuentoCondiciones || '—';
  (payload as any).monto_total_descuento = porcentajeDesc > 0 ? formatCurrency(montoTotalDescuento) : '0';
  (payload as any).monto_neto_anual = (montoNetoAnual > 0) ? formatCurrency(montoNetoAnual) : (colegAnual ? formatCurrency(colegAnual) : '_______________');
  (payload as any).monto_cuota_neta = (montoCuotaNetaCalc > 0) ? formatCurrency(montoCuotaNetaCalc) : '_______________';

  return payload;
}

function extractHtmlSections(html: string): { doctype: string; htmlTag: string; bodyTag: string; head: string; body: string } {
  const doctypeMatch = html.match(/<!doctype\s+html>/i);
  const htmlTagMatch = html.match(/<html[^>]*>/i);
  const headMatch = html.match(/<head[^>]*>([\s\S]*?)<\/head>/i);
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  const bodyTagMatch = html.match(/<body[^>]*>/i);
  return {
    doctype: doctypeMatch ? doctypeMatch[0] : '<!doctype html>',
    htmlTag: htmlTagMatch ? htmlTagMatch[0] : '<html>',
    bodyTag: bodyTagMatch ? bodyTagMatch[0] : '<body>',
    head: headMatch ? headMatch[1] : '',
    body: bodyMatch ? bodyMatch[1] : html,
  };
}

function stripFixedPrintElements(html: string): string {
  return html
    .replace(/<div[^>]*class="[^"]*\bprint-header\b[^"]*"[^>]*>[\s\S]*?<\/div>/gi, '')
    .replace(/<div[^>]*class="[^"]*\bprint-footer\b[^"]*"[^>]*>[\s\S]*?<\/div>/gi, '');
}

export function renderPrestacionWithAnnex(payload: PrestacionPayload, options: { annex?: 'descuento' | 'pagare' | null } = {}): string {
  const mainHtml = renderTemplate(templates.prestacion, payload);
  const annexType = options.annex;
  if (!annexType) {
    return mainHtml;
  }

  const annexTemplate = annexType === 'descuento' ? templates.descuento : templates.pagare;
  const annexHtml = renderTemplate(annexTemplate, payload);

  const baseParts = extractHtmlSections(mainHtml);
  const annexParts = extractHtmlSections(annexHtml);

  const mergedHead = [baseParts.head.trim(), annexParts.head.trim()]
    .filter(Boolean)
    .join('\n');

  const cleanedAnnexBody = stripFixedPrintElements(annexParts.body).trim();
  const bodySegments = [baseParts.body.trim()];
  if (cleanedAnnexBody) {
    bodySegments.push('<div class="page-break"></div>');
    bodySegments.push(cleanedAnnexBody);
  }
  const mergedBody = bodySegments.join('\n');

  const doctype = baseParts.doctype || '<!doctype html>';
  const htmlTag = baseParts.htmlTag || '<html>';
  const bodyTag = baseParts.bodyTag || '<body>';

  return `${doctype}\n${htmlTag}\n<head>\n${mergedHead}\n</head>\n${bodyTag}\n${mergedBody}\n</body>\n</html>`;
}

export interface EnrollmentPaymentPlan {
  n_cuotas: number;
  monto_total: number;
  monto_por_cuota: number;
  primer_vencimiento: string;
  dia_vencimiento: number;
  payment_method: string | null;
  cuotas: Array<{ numero: number; amount: number; due_date: string }>;
}

interface BuildPaymentPlanOptions {
  enrollmentYear: number;
  economic?: {
    monto_matricula?: number | string;
    colegiatura_anual?: number | string;
    cantidad_cuotas?: number | string;
    monto_cuota?: number | string;
    dia_vencimiento?: number | string;
    primer_vencimiento?: string | null;
  };
  paymentMethodFlags?: PaymentMethodFlags;
  firstDueMonth?: number; // 0-indexed month; defaults to March
  firstDueDate?: string | null; // overrides everything if provided
}

export function buildEnrollmentPaymentPlan(options: BuildPaymentPlanOptions): EnrollmentPaymentPlan | null {
  const { enrollmentYear, economic, paymentMethodFlags } = options;
  if (!enrollmentYear) return null;
  const econ = economic || {};
  const cuotasCount = toPositiveInt(econ.cantidad_cuotas);
  if (!cuotasCount) return null;
  const dayOfMonth = clampDayOfMonth(econ.dia_vencimiento);
  if (!dayOfMonth) return null;

  const montoTotal = Math.max(0, toNumberOrZero(econ.colegiatura_anual));
  let montoCuota = toNumberOrZero(econ.monto_cuota);
  if (!montoCuota && montoTotal && cuotasCount) {
    montoCuota = Math.round(montoTotal / cuotasCount);
  }

  const explicitDate = options.firstDueDate || econ.primer_vencimiento || null;
  const normalizedExplicitDate = normalizeIsoDate(explicitDate);
  const baseMonth = typeof options.firstDueMonth === 'number' ? options.firstDueMonth : 2; // March by default
  const baseDate = normalizedExplicitDate
    ? isoToUTCDate(normalizedExplicitDate)
    : new Date(Date.UTC(enrollmentYear, baseMonth, dayOfMonth));
  if (!baseDate) return null;

  const cuotas: Array<{ numero: number; amount: number; due_date: string }> = [];
  for (let i = 0; i < cuotasCount; i += 1) {
    const due = addMonthsUTC(baseDate, i);
    cuotas.push({
      numero: i + 1,
      amount: montoCuota,
      due_date: formatIsoDate(due)
    });
  }

  return {
    n_cuotas: cuotasCount,
    monto_total: montoTotal,
    monto_por_cuota: montoCuota,
    primer_vencimiento: formatIsoDate(baseDate),
    dia_vencimiento: dayOfMonth,
    payment_method: derivePrimaryPaymentMethod(paymentMethodFlags),
    cuotas
  };
}

function derivePrimaryPaymentMethod(flags?: PaymentMethodFlags): string | null {
  if (!flags) return null;
  const ordered: Array<{ key: keyof PaymentMethodFlags; label: string }> = [
    { key: 'pagare', label: 'PAGARE' },
    { key: 'transferencia', label: 'TRANSFERENCIA' },
    { key: 'cheques', label: 'CHEQUE' },
    { key: 'tarjeta', label: 'TARJETA' },
    { key: 'efectivo', label: 'EFECTIVO' },
  ];
  const enabled = ordered.filter(item => flags[item.key]);
  if (enabled.length === 0) {
    const anyTrue = Object.values(flags).some(Boolean);
    return anyTrue ? 'MIXTO' : null;
  }
  return enabled[0].label;
}

function clampDayOfMonth(value: unknown): number {
  const num = Number(value);
  if (!Number.isFinite(num)) return 0;
  const day = Math.floor(num);
  if (day <= 0) return 0;
  return Math.max(1, Math.min(28, day));
}

function toPositiveInt(value: unknown): number {
  const num = Number(value);
  if (!Number.isFinite(num) || num <= 0) return 0;
  return Math.floor(num);
}

function toNumberOrZero(value: unknown): number {
  const num = Number(value);
  return Number.isFinite(num) ? num : 0;
}

function formatIsoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function normalizeIsoDate(value?: string | null): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return null;
  return trimmed;
}

function isoToUTCDate(value: string): Date | null {
  const [y, m, d] = value.split('-').map(part => Number(part));
  if (!y || !m || !d) return null;
  const date = new Date(Date.UTC(y, m - 1, d));
  return Number.isNaN(date.getTime()) ? null : date;
}

function addMonthsUTC(date: Date, months: number): Date {
  const clone = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  clone.setUTCMonth(clone.getUTCMonth() + months);
  return clone;
}

// Decision engine: compute needed documents and generate/update them idempotently
// Types considered:
//  - PRESTACION (base, may embed descuento/pagare annex)
//  - PRIORITARIO (separate annex if prioritario flag true)
//  - PAGARE_DEUDA (separate if debt exists)
// Future: PAGARE_REPACTACION handled elsewhere
export interface AutoDocContext {
  enrollment: EnrollmentRecord;
  guardian: GuardianRecord;
  students: StudentRecord[];
  meta: any; // enrollment.meta
  debtTotal?: number; // total outstanding debt (for PAGARE_DEUDA)
  deudaCuotas?: number; // cuotas for debt pagaré
  deudaDiaVencimiento?: number; // day of month for debt pagaré
}

export async function ensureEnrollmentDocuments(ctx: AutoDocContext): Promise<void> {
  const { enrollment, guardian, students, meta } = ctx;
  if (!enrollment?.id || !guardian) return;

  // Extract flags
  const prioritario: boolean = !!meta?.prioritario;
  const descuentoPlanilla: boolean = !!meta?.forma_pago_descuento_planilla;
  const pagaréSeleccionado: boolean = !!meta?.forma_pago_pagare;
  const chequesSeleccionados: boolean = !!meta?.forma_pago_cheques;
  const porcentaje_descuento: number | undefined = typeof meta?.porcentaje_descuento === 'number' ? meta.porcentaje_descuento : undefined;

  // Debt presence (only generate PAGARE_DEUDA if meaningful total > 0)
  const debtTotal = Math.max(0, Math.round(Number(ctx.debtTotal) || 0));

  // Compute plan (centralized rules & precedence)
  const plan = computeEnrollmentDocumentPlan({
    prioritario,
    descuentoPlanilla,
    paymentMethod: { cheques: chequesSeleccionados, pagare: pagaréSeleccionado },
    debtTotal,
  });

  // Build economic data for prestacion payload
  const economic = {
    monto_matricula: Number(meta?.monto_matricula) || undefined,
    colegiatura_anual: Number(meta?.colegiatura_anual) || undefined,
    cantidad_cuotas: Number(meta?.cantidad_cuotas) || undefined,
    monto_cuota: Number(meta?.monto_cuota) || undefined,
    dia_vencimiento: Number(meta?.dia_vencimiento) || undefined,
  };

  // Payment method flags for payload
  const paymentMethod = {
    cheques: chequesSeleccionados,
    transferencia: !!meta?.forma_pago_transferencia,
    efectivo: !!meta?.forma_pago_efectivo,
    tarjeta: !!meta?.forma_pago_tarjeta,
    pagare: pagaréSeleccionado,
  };

  // Cheques array (if stored as structured data in meta)
  const chequesArr = Array.isArray(meta?.cheques_detalle) ? meta.cheques_detalle : undefined;

  // Descuento info
  const descuento = (descuentoPlanilla && !prioritario) ? {
    porcentaje: porcentaje_descuento || 0,
    motivo: meta?.descuento_motivo || '',
    condiciones: meta?.descuento_condiciones || ''
  } : null;

  // Build base payload
  const prestacionPayload = buildPrestacionPayload({
    guardian,
    year: enrollment.year,
    students,
    economic: prioritario ? undefined : economic, // if prioritario we can still pass economic but optionally omit
    paymentMethod: prioritario ? undefined : paymentMethod,
    cheques: (!prioritario && chequesSeleccionados && Array.isArray(chequesArr)) ? chequesArr : undefined,
    descuento,
  });

  // Determine annex inside prestacion (we only embed 'descuento' or 'pagare').
  // Cheques are already reflected via payload table; no separate annex page.
  let annex: 'descuento' | 'pagare' | null = null;
  if (plan.prestacionAnnex === 'descuento') annex = 'descuento';
  else if (plan.prestacionAnnex === 'pagare') annex = 'pagare';
  const prestacionHtml = renderPrestacionWithAnnex(prestacionPayload, { annex });

  // Hash content for idempotence
  const prestacionHash = await sha256(prestacionHtml);

  // Upsert PRESTACION document
  await upsertEnrollmentDocument({
    enrollmentId: enrollment.id,
    type: 'PRESTACION',
    finalContent: prestacionHtml,
    payload: prestacionPayload,
    contentHash: prestacionHash
  });

  // PRIORITARIO annex as separate document (only if prioritario)
  if (plan.types.includes('PRIORITARIO')) {
    const prioritarioHtml = renderTemplate(templates.prioritario, prestacionPayload);
    const prioritarioHash = await sha256(prioritarioHtml);
    await upsertEnrollmentDocument({
      enrollmentId: enrollment.id,
      type: 'PRIORITARIO',
      finalContent: prioritarioHtml,
      payload: prestacionPayload,
      contentHash: prioritarioHash
    });
  }

  // Debt pagaré (PAGARE_DEUDA) separate
  if (plan.types.includes('PAGARE_DEUDA')) {
    const deudaPayload = buildPagareDeudaPayload({
      guardian,
      year: enrollment.year,
      students,
      debt: {
        total: debtTotal,
        cuotas: Math.max(1, Number(ctx.deudaCuotas) || (Number(meta?.cantidad_cuotas) || 1)),
        dia_vencimiento: Number(ctx.deudaDiaVencimiento) || Number(meta?.dia_vencimiento) || 5
      }
    });
    const deudaHtml = renderPagareDeuda(deudaPayload);
    const deudaHash = await sha256(deudaHtml);
    await upsertEnrollmentDocument({
      enrollmentId: enrollment.id,
      type: 'PAGARE_DEUDA',
      finalContent: deudaHtml,
      payload: deudaPayload,
      contentHash: deudaHash
    });
  }
}

// Helper: insert or update non-signed document of a given type
async function upsertEnrollmentDocument(params: {
  enrollmentId: string;
  type: string;
  finalContent: string;
  payload: any;
  contentHash: string;
}): Promise<void> {
  const { enrollmentId, type, finalContent, payload, contentHash } = params;
  try {
    const { data, error } = await supabase
      .from('enrollment_documents')
      .select('id, status, content_hash')
      .eq('enrollment_id', enrollmentId)
      .eq('type', type)
      .limit(1)
      .maybeSingle();
    if (error) {
      console.warn('[auto-doc] select error', error);
    }
    const existing = data || null;
    if (existing) {
      if (existing.status === 'signed') {
        // Do not modify signed docs
        return;
      }
      if (existing.content_hash === contentHash) {
        // Unchanged
        return;
      }
      // Update
      const { error: updErr } = await supabase
        .from('enrollment_documents')
        .update({ final_content: finalContent, generated_payload: payload, content_hash: contentHash, updated_at: new Date().toISOString() })
        .eq('id', existing.id);
      if (updErr) console.error('[auto-doc] update error', updErr);
      return;
    }
    // Insert
    const insertObj: any = {
      enrollment_id: enrollmentId,
      type,
      template_version: 1,
      status: 'generated',
      generated_payload: payload,
      final_content: finalContent,
      content_hash: contentHash
    };
    const { error: insErr } = await supabase
      .from('enrollment_documents')
      .insert(insertObj);
    if (insErr) console.error('[auto-doc] insert error', insErr);
  } catch (e) {
    console.error('[auto-doc] upsert exception', e);
  }
}

// Create Prestación document record
export async function createPrestacionDocument(params: {
  enrollmentId: string;
  payload: PrestacionPayload;
  finalContent: string;
  contentHash?: string;
}): Promise<EnrollmentDocumentRecord | null> {
  const { enrollmentId, payload, finalContent, contentHash } = params;
  try {
    toast.loading('Generando contrato...', { id: 'prestacion-generation' });
    const insertObj: any = {
      enrollment_id: enrollmentId,
      type: 'PRESTACION',
      template_version: 1,
      status: 'generated',
      generated_payload: payload,
      content_hash: contentHash || null,
      pdf_url: null,
      storage_path: null,
      pdf_hash: null,
      final_content: finalContent
    };
    const { data, error } = await supabase
      .from('enrollment_documents')
      .insert(insertObj)
      .select()
      .single();
    if (error) {
      console.error('createPrestacionDocument error', error);
      // Retry without final_content if fails on column
      if ((error as any).message?.includes('final_content')) {
        delete insertObj.final_content;
        const { data: retryData, error: retryError } = await supabase
          .from('enrollment_documents')
          .insert(insertObj)
          .select()
          .single();
        if (retryError) {
          console.error('createPrestacionDocument retry error', retryError);
          toast.error('No se pudo crear el contrato en la base de datos', { id: 'prestacion-generation' });
          return null;
        }
        toast.success('Contrato generado correctamente', { id: 'prestacion-generation' });
        return retryData as EnrollmentDocumentRecord;
      }
      // Second fallback: try minimal insert (avoid optional columns)
      try {
        const minimal: any = {
          enrollment_id: enrollmentId,
          type: 'PRESTACION',
          status: 'generated',
          generated_payload: payload
        };
        const { data: minData, error: minErr } = await supabase
          .from('enrollment_documents')
          .insert(minimal)
          .select()
          .single();
        if (minErr) {
          console.error('createPrestacionDocument minimal insert error', minErr);
          toast.error('No se pudo crear el contrato en la base de datos', { id: 'prestacion-generation' });
          return null;
        }
        toast.success('Contrato generado correctamente', { id: 'prestacion-generation' });
        return minData as EnrollmentDocumentRecord;
      } catch (e2) {
        console.error('createPrestacionDocument fallback exception', e2);
        toast.error('No se pudo crear el contrato en la base de datos', { id: 'prestacion-generation' });
        return null;
      }
    }
    toast.success('Contrato generado correctamente', { id: 'prestacion-generation' });
    return data as EnrollmentDocumentRecord;
  } catch (e) {
    console.error('createPrestacionDocument exception', e);
    toast.error('Error al generar el contrato', { id: 'prestacion-generation' });
    return null;
  }
}

// Support type for saving cheques
export interface ChequeSaveInput {
  numero_serie: string;
  banco: string;
  fecha_emision: string; // YYYY-MM-DD
  monto: number;
  notas?: string;
}

/**
 * Save (replace) cheque for an enrollment. If there are existing cheques for the enrollment,
 * they are deleted and a single new row is inserted. Optionally attaches document_id and folio_number
 * so we can trace the cheque to the generated Pagaré.
 */
export async function saveChequeForEnrollment(params: {
  enrollmentId: string;
  cheque: ChequeSaveInput;
  documentId?: string | null;
  folioNumber?: string | null;
  createdBy?: string | null; // user id
}): Promise<boolean> {
  const { enrollmentId, cheque, documentId, folioNumber, createdBy } = params;
  try {
    // Remove previous cheques for this enrollment (simple strategy for now)
    const { error: delErr } = await supabase
      .from('cheques')
      .delete()
      .eq('enrollment_id', enrollmentId);
    if (delErr) {
      console.warn('[cheques] delete previous error (non-fatal):', delErr);
    }

    const insertRow: Record<string, any> = {
      enrollment_id: enrollmentId,
      numero_serie: cheque.numero_serie,
      banco: cheque.banco,
      fecha_emision: cheque.fecha_emision,
      monto: cheque.monto,
      notas: cheque.notas || null,
    };
    if (documentId) insertRow.document_id = documentId;
    if (folioNumber) insertRow.folio_number = folioNumber;
    if (createdBy) insertRow.created_by = createdBy;

    const { error: insErr } = await supabase
      .from('cheques')
      .insert(insertRow);
    if (insErr) {
      console.error('[cheques] insert error', insErr);
      toast.error('No se pudo guardar el cheque');
      return false;
    }
    return true;
  } catch (e) {
    console.error('[cheques] unexpected save error', e);
    toast.error('Error inesperado guardando cheque');
    return false;
  }
}

/**
 * Save (replace) multiple cheques for an enrollment. Deletes previous cheques for the enrollment
 * and inserts the provided array, assigning numero_cuota if missing. Optionally links to document/folio.
 */
export async function saveChequesForEnrollment(params: {
  enrollmentId: string;
  cheques: Array<ChequeSaveInput & { numero_cuota?: number }>;
  documentId?: string | null;
  folioNumber?: string | null;
  createdBy?: string | null;
}): Promise<boolean> {
  const { enrollmentId, cheques, documentId, folioNumber, createdBy } = params;
  if (!Array.isArray(cheques) || cheques.length === 0) return true; // nothing to insert
  try {
    // Remove previous cheques for this enrollment
    const { error: delErr } = await supabase
      .from('cheques')
      .delete()
      .eq('enrollment_id', enrollmentId);
    if (delErr) {
      console.warn('[cheques] delete previous error (non-fatal):', delErr);
    }

    const rows = cheques.map((c, idx) => {
      const r: Record<string, any> = {
        enrollment_id: enrollmentId,
        numero_cuota: c.numero_cuota ?? (idx + 1),
        numero_serie: c.numero_serie,
        banco: c.banco,
        fecha_emision: c.fecha_emision,
        monto: c.monto,
        notas: c.notas || null
      };
      if (documentId) r.document_id = documentId;
      if (folioNumber) r.folio_number = folioNumber;
      if (createdBy) r.created_by = createdBy;
      return r;
    });

    const { error: insErr } = await supabase
      .from('cheques')
      .insert(rows);
    if (insErr) {
      console.error('[cheques] bulk insert error', insErr);
      toast.error('No se pudieron guardar los cheques');
      return false;
    }
    return true;
  } catch (e) {
    console.error('[cheques] unexpected bulk save error', e);
    toast.error('Error inesperado guardando cheques');
    return false;
  }
}

// 7. Render template with placeholders {{key}}
export function renderTemplate(raw: string, payload: Record<string, any>): string {
  // Support keys with optional question mark suffix (e.g., guardian_comuna?)
  return raw.replace(/{{\s*([a-zA-Z0-9_?]+)\s*}}/g, (_m, key) => {
    const v = payload[key];
    if (v === undefined || v === null) return `{{${key}}}`; // leave marker if missing
    return typeof v === 'string' ? v : String(v);
  });
}

// 7b. Debt helpers and payload builder
export async function getGuardianOutstandingDebt(guardianId: string): Promise<{ total: number; items: any[] } | null> {
  try {
    const { data, error } = await supabase.rpc('get_guardian_outstanding_debt', { guardian_id: guardianId });
    if (error) {
      console.warn('[debt] RPC get_guardian_outstanding_debt error, fallback to 0', error);
      return { total: 0, items: [] };
    }
    if (!data) return { total: 0, items: [] };
    if (typeof (data as any).total === 'number') return data as any;
    const maybeArray = Array.isArray(data) ? data[0] : data;
    const total = Number((maybeArray && (maybeArray.total ?? maybeArray.sum)) || 0) || 0;
    const items = (maybeArray && (maybeArray.items || [])) || [];
    return { total, items };
  } catch (e) {
    console.error('[debt] unexpected error', e);
    return { total: 0, items: [] };
  }
}

// Detailed debt fetch: attempts RPC then falls back to fee table queries.
// Cached flag to avoid repeated 404 attempts; persisted to localStorage to survive reloads
let _missingDebtRpc = false;
try {
  if (typeof window !== 'undefined' && window?.localStorage) {
    _missingDebtRpc = window.localStorage.getItem('wh_missing_debt_rpc') === '1';
  }
} catch {}
export async function fetchGuardianDebtDetailed(guardianId: string): Promise<{ total: number; items: Array<{
  id: string; student_id: string; guardian_id: string | null; amount: number; due_date: string; status: string; year_academico: number | null; numero_cuota: number | null; }>; source: 'rpc' | 'fallback'; }> {
  try {
    // Try RPC first
  // If RPC returns structured data, use it directly; otherwise fallback
    if (!_missingDebtRpc) {
      try {
        const { data, error } = await supabase.rpc('get_guardian_outstanding_debt', { guardian_id: guardianId });
        if (error) {
          const msg = (error as any).message?.toLowerCase() || '';
          if (msg.includes('not found') || msg.includes('404')) {
            _missingDebtRpc = true; // cache absence
            try { if (typeof window !== 'undefined' && window?.localStorage) window.localStorage.setItem('wh_missing_debt_rpc', '1'); } catch {}
          }
        }
        if (!error && data) {
          const total = Number((data as any).total ?? (Array.isArray(data) ? (data[0] as any)?.total : 0) ?? 0) || 0;
          const itemsRaw = (data as any).items || (Array.isArray(data) ? (data[0] as any)?.items : []) || [];
          if (Array.isArray(itemsRaw)) {
            const items = itemsRaw.map((r: any) => ({
              id: r.id || crypto.randomUUID(),
              student_id: r.student_id || r.students_id || '',
              guardian_id: r.guardian_id || null,
              amount: Number(r.amount || r.monto || 0) || 0,
              due_date: r.due_date || r.fecha_vencimiento || '',
              status: r.status || r.estado || 'pending',
              year_academico: r.year_academico || null,
              numero_cuota: r.numero_cuota || null,
            })).filter(it => it.amount > 0);
            return { total, items, source: 'rpc' };
          }
        }
      } catch (e) {
        // Network / RPC exception, mark missing if 404-like
        const msg = (e as any)?.message?.toLowerCase() || '';
        if (msg.includes('404') || msg.includes('not found')) {
          _missingDebtRpc = true;
          try { if (typeof window !== 'undefined' && window?.localStorage) window.localStorage.setItem('wh_missing_debt_rpc', '1'); } catch {}
        }
        // continue to fallback
      }
    }

    // Fallback: query fee table directly
    // 1) Direct fees with guardian_id
    const { data: directFees, error: directErr } = await supabase
      .from('fee')
      .select('id, student_id, guardian_id, amount, due_date, status, year_academico, numero_cuota')
      .eq('guardian_id', guardianId)
      .in('status', ['pending','overdue']);
    if (directErr) console.warn('[debt] direct fees error', directErr);
    const directMap: Record<string, any> = {};
    (directFees || []).forEach(f => { directMap[f.id] = f; });

    // 2) Get student_ids for guardian
    const { data: sg, error: sgErr } = await supabase
      .from('student_guardian')
      .select('student_id')
      .eq('guardian_id', guardianId);
    if (sgErr) console.warn('[debt] student_guardian error', sgErr);
    const studentIds = (sg || []).map(r => r.student_id).filter(Boolean);

    let byStudents: any[] = [];
    if (studentIds.length) {
      const { data: studentFees, error: sfErr } = await supabase
        .from('fee')
        .select('id, student_id, guardian_id, amount, due_date, status, year_academico, numero_cuota')
        .in('student_id', studentIds)
        .in('status', ['pending','overdue']);
      if (sfErr) console.warn('[debt] fees by students error', sfErr);
      byStudents = (studentFees || []).filter(f => !directMap[f.id]); // avoid duplicates
    }

    const all = [...Object.values(directMap), ...byStudents];
    const items = all.map(f => ({
      id: f.id,
      student_id: f.student_id,
      guardian_id: f.guardian_id || null,
      amount: Number(f.amount) || 0,
      due_date: f.due_date,
      status: f.status || 'pending',
      year_academico: f.year_academico ?? null,
      numero_cuota: f.numero_cuota ?? null,
    })).filter(it => it.amount > 0);
    const total = items.reduce((sum, r) => sum + r.amount, 0);
    return { total, items, source: 'fallback' };
  } catch (e) {
    console.error('[debt] fetchGuardianDebtDetailed unexpected', e);
    return { total: 0, items: [], source: 'fallback' };
  }
}

// Check if enrollment has a signed regularization document (debt or repactación)
export async function hasSignedRegularization(enrollmentId: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .from('enrollment_documents')
      .select('id, type, status')
      .eq('enrollment_id', enrollmentId)
      .in('type', ['PAGARE_DEUDA','PAGARE_REPACTACION'])
      .eq('status', 'signed');
    if (error) {
      console.warn('[regularization] query error', error);
      return false;
    }
    return Array.isArray(data) && data.length > 0;
  } catch (e) {
    console.error('[regularization] unexpected error', e);
    return false;
  }
}

export interface PagareDeudaPayload {
  fecha_actual: string;
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_fono?: string;
  year?: number;
  students_list?: string;
  guardian_comuna?: string;
  [k: string]: any;
}

export function buildPagareDeudaPayload(opts: {
  guardian: GuardianRecord;
  year?: number;
  students?: StudentRecord[];
  debt: { total: number; cuotas: number; dia_vencimiento: number };
}): PagareDeudaPayload {
  const { guardian, year, students = [], debt } = opts;

  const now = new Date();
  const day = now.getDate();
  const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
  const month = months[now.getMonth()];
  const yearFull = now.getFullYear();
  const fecha_actual = `${day} de ${month} del ${yearFull}`;

  const formatCurrency = (value?: number | string) => {
    if (value === undefined || value === null || value === '') return '_______________';
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (!isFinite(num)) return '_______________';
    return num.toLocaleString('es-CL');
  };

  const studentsList = students.length ? buildStudentsList(students, year || yearFull) : '<pre style="white-space: pre-wrap; font-family: Helvetica, Arial, sans-serif; font-size: 11px; line-height: 1.35;">—</pre>';

  const cuotas = Math.max(1, Math.floor(Number(debt.cuotas) || 1));
  const total = Math.max(0, Math.round(Number(debt.total) || 0));
  const montoCuota = cuotas > 0 ? Math.round(total / cuotas) : total;

  const payload: PagareDeudaPayload = {
    fecha_actual,
    guardian_full_name: [guardian.first_name, guardian.last_name].filter(Boolean).map(s => (s as string).trim()).join(' ') || '_______________',
    guardian_run: guardian.run || '_______________',
    guardian_address: (guardian.address || '').trim(),
    guardian_email: guardian.email || '_______________',
    guardian_fono: guardian.phone || '_______________',
    guardian_comuna: guardian.comuna || undefined,
    year,
    students_list: studentsList,
    debt_total: formatCurrency(total),
    debt_total_texto: `${numberToWordsEs(total)} pesos`,
    debt_cuotas: String(cuotas),
    debt_monto_cuota: formatCurrency(montoCuota),
    debt_monto_cuota_texto: `${numberToWordsEs(montoCuota)} pesos`,
    dia_vencimiento: String(Math.max(1, Math.min(28, Number(debt.dia_vencimiento) || 5)))
  } as any;

  const _addr = (guardian.address || '').trim();
  const _com = (guardian.comuna || '').trim();
  (payload as any)['guardian_comuna?'] = _com ? (_addr ? `, ${_com}` : `${_com}`) : '';
  const _city = ((guardian as any).ciudad || (guardian as any).city || '').toString().trim();
  (payload as any)['guardian_city?'] = _city ? ((_addr || _com) ? `, ${_city}` : `${_city}`) : '';

  return payload;
}

export function renderPagareDeuda(payload: Record<string, any>): string {
  return renderTemplate(templates.pagare_deuda, payload);
}

// 7c. Repactación helpers and payload builder (for PAGARE_REPACTACION)
export interface RepactacionPayload {
  fecha_actual: string;
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_fono?: string;
  year?: number;
  students_list?: string;
  // Economic (repactación schedule)
  colegiatura_anual: string; // total capital adeudado (formatted)
  colegiatura_anual_texto: string; // total in words
  cantidad_cuotas: string;
  monto_cuota: string; // formatted amount per installment
  monto_cuota_texto: string; // amount in words
  dia_vencimiento: string;
  [k: string]: any;
}

export function buildRepactacionPayload(opts: {
  guardian: GuardianRecord;
  year?: number;
  students?: StudentRecord[];
  schedule: { total: number; cuotas: number; dia_vencimiento: number };
}): RepactacionPayload {
  const { guardian, year, students = [], schedule } = opts;

  const now = new Date();
  const day = now.getDate();
  const months = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
  const month = months[now.getMonth()];
  const yearFull = now.getFullYear();
  const fecha_actual = `${day} de ${month} del ${yearFull}`;

  const formatCurrency = (value?: number | string) => {
    if (value === undefined || value === null || value === '') return '_______________';
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (!isFinite(num)) return '_______________';
    return num.toLocaleString('es-CL');
  };

  const studentsList = students.length ? buildStudentsList(students, year || yearFull) : '<pre style="white-space: pre-wrap; font-family: Helvetica, Arial, sans-serif; font-size: 11px; line-height: 1.35;">—</pre>';

  const cuotas = Math.max(1, Math.floor(Number(schedule.cuotas) || 1));
  const total = Math.max(0, Math.round(Number(schedule.total) || 0));
  const montoCuota = cuotas > 0 ? Math.round(total / cuotas) : total;

  const payload: RepactacionPayload = {
    fecha_actual,
    guardian_full_name: [guardian.first_name, guardian.last_name].filter(Boolean).map(s => (s as string).trim()).join(' ') || '_______________',
    guardian_run: guardian.run || '_______________',
    guardian_address: (guardian.address || '').trim(),
    guardian_email: guardian.email || '_______________',
    guardian_fono: guardian.phone || '_______________',
    year,
    students_list: studentsList,
    colegiatura_anual: formatCurrency(total),
    colegiatura_anual_texto: `${numberToWordsEs(total)} pesos`,
    cantidad_cuotas: String(cuotas),
    monto_cuota: formatCurrency(montoCuota),
    monto_cuota_texto: `${numberToWordsEs(montoCuota)} pesos`,
    dia_vencimiento: String(Math.max(1, Math.min(28, Number(schedule.dia_vencimiento) || 5)))
  } as any;

  const _addr = (guardian.address || '').trim();
  const _com = (guardian.comuna || '').trim();
  (payload as any)['guardian_comuna?'] = _com ? (_addr ? `, ${_com}` : `${_com}`) : '';
  const _city = ((guardian as any).ciudad || (guardian as any).city || '').toString().trim();
  (payload as any)['guardian_city?'] = _city ? ((_addr || _com) ? `, ${_city}` : `${_city}`) : '';

  return payload;
}

export function renderRepactacionPagare(payload: Record<string, any>): string {
  return renderTemplate(templates.pagarerepac, payload);
}

export async function createRepactacionPagareDocument(params: {
  enrollmentId: string;
  payload: Record<string, any>;
  finalContent: string;
  contentHash?: string;
}): Promise<EnrollmentDocumentRecord | null> {
  const { enrollmentId, payload, finalContent, contentHash } = params;
  try {
    toast.loading('Generando pagaré de repactación...', { id: 'repac-doc-generation' });
    const insertObj: any = {
      enrollment_id: enrollmentId,
      type: 'PAGARE_REPACTACION',
      template_version: 1,
      status: 'generated',
      generated_payload: payload,
      content_hash: contentHash || null,
      pdf_url: null,
      storage_path: null,
      pdf_hash: null,
      final_content: finalContent,
    };

    const { data, error } = await supabase
      .from('enrollment_documents')
      .insert(insertObj)
      .select()
      .single();
    if (error) {
      console.error('createRepactacionPagareDocument error', error);
      if ((error as any).message?.includes('final_content')) {
        delete insertObj.final_content;
        const { data: retryData, error: retryError } = await supabase
          .from('enrollment_documents')
          .insert(insertObj)
          .select()
          .single();
        if (retryError) {
          console.error('createRepactacionPagareDocument retry error', retryError);
          toast.error('No se pudo crear el pagaré de repactación', { id: 'repac-doc-generation' });
          return null;
        }
        toast.success('Pagaré de repactación generado', { id: 'repac-doc-generation' });
        return retryData as EnrollmentDocumentRecord;
      }
      toast.error('No se pudo crear el pagaré de repactación', { id: 'repac-doc-generation' });
      return null;
    }
    toast.success('Pagaré de repactación generado', { id: 'repac-doc-generation' });
    return data as EnrollmentDocumentRecord;
  } catch (e) {
    console.error('createRepactacionPagareDocument exception', e);
    toast.error('Error al generar el pagaré de repactación', { id: 'repac-doc-generation' });
    return null;
  }
}

// 8. Create enrollment document (PAGARE) - HTML only, PDF generated on-demand
export async function createPagareDocument(params: {
  enrollmentId: string;
  template: DocumentTemplate;
  payload: PagarePayload;
  finalContent: string;
  contentHash?: string; // computed client-side (e.g., SHA-256)
}): Promise<EnrollmentDocumentRecord | null> {
  const { 
    enrollmentId, 
    template, 
    payload, 
    finalContent, 
    contentHash
  } = params;

  try {
    toast.loading('Generando documento...', { id: 'document-generation' });

    // Insert document record (HTML content only, PDF generated client-side on download)
    const insertObj: any = {
      enrollment_id: enrollmentId,
      type: 'PAGARE',
      template_version: template.version,
      status: 'generated',
      generated_payload: payload,
      content_hash: contentHash || null,
      pdf_url: null, // PDF not stored on server, generated client-side on-demand
      storage_path: null,
      pdf_hash: null
    };

    // Try to add final_content if the column exists
    try {
      insertObj.final_content = finalContent;
    } catch (e) {
      console.warn('final_content column may not exist, continuing without it');
    }

    const { data, error } = await supabase
      .from('enrollment_documents')
      .insert(insertObj)
      .select()
      .single();

    if (error) {
      console.error('createPagareDocument error', error);
      
      // If error is about final_content column, retry without it
      if (error.message?.includes('final_content')) {
        console.log('Retrying insert without final_content column...');
        delete insertObj.final_content;
        
        const { data: retryData, error: retryError } = await supabase
          .from('enrollment_documents')
          .insert(insertObj)
          .select()
          .single();
          
        if (retryError) {
          console.error('Retry failed:', retryError);
          toast.error('No se pudo crear el documento en la base de datos', { id: 'document-generation' });
          return null;
        }
        
        toast.success('Documento generado correctamente', { id: 'document-generation' });
        return retryData;
      }
      
      toast.error('No se pudo crear el documento en la base de datos', { id: 'document-generation' });
      return null;
    }

    toast.success('Documento generado correctamente', { id: 'document-generation' });
    return data;

  } catch (err) {
    console.error('createPagareDocument exception:', err);
    toast.error('Error al generar el documento', { id: 'document-generation' });
    return null;
  }
}

// 8b. Create enrollment document (PAGARE_DEUDA) - HTML only
export async function createDebtPagareDocument(params: {
  enrollmentId: string;
  payload: Record<string, any>;
  finalContent: string;
  contentHash?: string;
}): Promise<EnrollmentDocumentRecord | null> {
  const { enrollmentId, payload, finalContent, contentHash } = params;
  try {
    toast.loading('Generando pagaré de deuda...', { id: 'debt-doc-generation' });
    const insertObj: any = {
      enrollment_id: enrollmentId,
      type: 'PAGARE_DEUDA',
      template_version: 1,
      status: 'generated',
      generated_payload: payload,
      content_hash: contentHash || null,
      pdf_url: null,
      storage_path: null,
      pdf_hash: null,
      final_content: finalContent,
    };

    const { data, error } = await supabase
      .from('enrollment_documents')
      .insert(insertObj)
      .select()
      .single();
    if (error) {
      console.error('createDebtPagareDocument error', error);
      if ((error as any).message?.includes('final_content')) {
        delete insertObj.final_content;
        const { data: retryData, error: retryError } = await supabase
          .from('enrollment_documents')
          .insert(insertObj)
          .select()
          .single();
        if (retryError) {
          console.error('createDebtPagareDocument retry error', retryError);
          toast.error('No se pudo crear el pagaré de deuda', { id: 'debt-doc-generation' });
          return null;
        }
        toast.success('Pagaré de deuda generado', { id: 'debt-doc-generation' });
        return retryData as EnrollmentDocumentRecord;
      }
      toast.error('No se pudo crear el pagaré de deuda', { id: 'debt-doc-generation' });
      return null;
    }
    toast.success('Pagaré de deuda generado', { id: 'debt-doc-generation' });
    return data as EnrollmentDocumentRecord;
  } catch (e) {
    console.error('createDebtPagareDocument exception', e);
    toast.error('Error al generar el pagaré de deuda', { id: 'debt-doc-generation' });
    return null;
  }
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

// =====================================================
// INTAKE → STUDENT AUTO-CREATION HELPERS
// =====================================================

export type CourseLite = {
  id: string;
  nom_curso: string | null;
  nivel: string | null;
  letra_curso: string | null;
};

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

let _courseCatalog: CourseLite[] | null = null;
let _courseCatalogPromise: Promise<CourseLite[]> | null = null;

function normalizeCourseLabel(value: string): string {
  const base = typeof value.normalize === 'function' ? value.normalize('NFD') : value;
  return base
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u00b0\u00ba]/g, '')
    .replace(/[^a-zA-Z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toUpperCase();
}

async function getCourseCatalog(): Promise<CourseLite[]> {
  if (_courseCatalog) return _courseCatalog;
  if (_courseCatalogPromise) return _courseCatalogPromise;
  _courseCatalogPromise = (async () => {
    try {
      const { data, error } = await supabase
        .from('cursos')
        .select('id, nom_curso, nivel, letra_curso')
        .order('nom_curso', { ascending: true });
      if (error) throw error;
      _courseCatalog = data || [];
      return _courseCatalog;
    } catch (e) {
      console.error('getCourseCatalog error', e);
      _courseCatalog = [];
      return _courseCatalog;
    } finally {
      _courseCatalogPromise = null;
    }
  })();
  return _courseCatalogPromise;
}

export async function fetchCourseCatalogLite(options?: { force?: boolean }): Promise<CourseLite[]> {
  if (options?.force) {
    _courseCatalog = null;
  }
  return getCourseCatalog();
}

function findCourseByNormalizedLabel(catalog: CourseLite[], normalized: string): CourseLite | null {
  if (!normalized) return null;
  for (const course of catalog) {
    const courseLabel = course?.nom_curso ? normalizeCourseLabel(course.nom_curso) : '';
    if (!courseLabel) continue;
    if (courseLabel === normalized) return course;
  }
  for (const course of catalog) {
    const courseLabel = course?.nom_curso ? normalizeCourseLabel(course.nom_curso) : '';
    if (!courseLabel) continue;
    if (courseLabel.includes(normalized) || normalized.includes(courseLabel)) {
      return course;
    }
  }
  return null;
}

async function resolveCourseFromInput(raw: string | null | undefined): Promise<{ courseId: string | null; course: CourseLite | null }> {
  if (!raw) return { courseId: null, course: null };
  const value = raw.trim();
  if (!value) return { courseId: null, course: null };
  const catalog = await getCourseCatalog();
  const direct = catalog.find(course => course.id === value);
  if (direct) return { courseId: direct.id, course: direct };
  if (UUID_REGEX.test(value)) {
    const { data, error } = await supabase
      .from('cursos')
      .select('id, nom_curso, nivel, letra_curso')
      .eq('id', value)
      .maybeSingle();
    if (!error && data) {
      return { courseId: data.id, course: data as CourseLite };
    }
  }
  const normalized = normalizeCourseLabel(value);
  if (!normalized) return { courseId: null, course: null };
  const match = findCourseByNormalizedLabel(catalog, normalized);
  return match ? { courseId: match.id, course: match } : { courseId: null, course: null };
}

async function ensureGuardianStudentLink(
  studentId: string,
  guardianId: string,
  guardianRole?: string | null
): Promise<boolean> {
  try {
    const payload = {
      student_id: studentId,
      guardian_id: guardianId,
      is_primary: true,
      guardian_role: guardianRole || null
    };
    const { error } = await supabase
      .from('student_guardian')
      .upsert(payload, { onConflict: 'student_id,guardian_id' });
    if (error) throw error;
    return true;
  } catch (e) {
    console.error('ensureGuardianStudentLink error', e);
    return false;
  }
}

export interface AutoCreateStudentFromIntakeOptions {
  guardianId: string;
  intake: Partial<GuardianIntakeRecord> | null | undefined;
  guardianOwnerId?: string | null;
  guardianRelationship?: string | null;
  staffUserId?: string | null;
}

export interface AutoCreateStudentFromIntakeResult {
  created: boolean;
  linked: boolean;
  studentId: string | null;
  reason?:
    | 'missing_guardian'
    | 'missing_intake'
    | 'missing_fields'
    | 'invalid_run'
    | 'course_not_found'
    | 'missing_owner'
    | 'link_failed'
    | 'error';
  courseId?: string | null;
  details?: string;
}

export async function ensureStudentFromIntake(
  options: AutoCreateStudentFromIntakeOptions
): Promise<AutoCreateStudentFromIntakeResult> {
  const base: AutoCreateStudentFromIntakeResult = {
    created: false,
    linked: false,
    studentId: null
  };

  try {
    if (!options?.guardianId) {
      return { ...base, reason: 'missing_guardian' };
    }
    const intake = options?.intake;
    if (!intake) {
      return { ...base, reason: 'missing_intake' };
    }

    const firstNames = (intake.student_first_names || '').trim();
    const lastNameP = (intake.student_last_name_paterno || '').trim();
    const lastNameM = (intake.student_last_name_materno || '').trim();
    const runRaw = (intake.student_run || '').trim();
    const birthDate = (intake.student_birth_date || '').trim();
    const courseRaw = (intake.student_course || '').trim();
    const courseIdFromIntake = (() => {
      const rawValue = (intake as any).student_course_id;
      if (rawValue === null || rawValue === undefined) return '';
      return String(rawValue).trim();
    })();

    if (!firstNames || !lastNameP || !runRaw || !birthDate || (!courseRaw && !courseIdFromIntake)) {
      return { ...base, reason: 'missing_fields' };
    }

    const normalizedRun = normalizeRun(runRaw);
    if (!isRutFormatValid(normalizedRun)) {
      return { ...base, reason: 'invalid_run' };
    }

    const runInfo = validateRun(normalizedRun);
    const runBody = runInfo.body ?? normalizedRun.slice(0, -1);
    const dvInput = runInfo.dv ?? normalizedRun.slice(-1);
    const formattedRun = formatRunDisplay(normalizedRun);
    const plainRun = `${runBody}-${dvInput}`;
    const compactRun = `${runBody}${dvInput}`;
    const runNumber = Number(runBody);
    const runFilters: string[] = [`run.eq.${formattedRun}`, `run.eq.${plainRun}`, `run.eq.${compactRun}`];
    if (Number.isFinite(runNumber)) {
      runFilters.push(`run_numero.eq.${runNumber}`);
    }

    const { data: existing, error: existingError } = await supabase
      .from('students')
      .select('id')
      .or(runFilters.join(','))
      .maybeSingle();
    if (existingError && existingError.code !== 'PGRST116') {
      console.error('ensureStudentFromIntake lookup error', existingError);
    }
    if (existing?.id) {
      const linked = await ensureGuardianStudentLink(
        existing.id,
        options.guardianId,
        options.guardianRelationship || (intake.guardian_relationship ?? null)
      );
      return {
        ...base,
        studentId: existing.id,
        linked,
        reason: linked ? undefined : 'link_failed'
      };
    }

    let courseResolution = { courseId: null as string | null, course: null as CourseLite | null };
    if (courseIdFromIntake) {
      courseResolution = await resolveCourseFromInput(courseIdFromIntake);
    }
    if (!courseResolution.courseId) {
      courseResolution = await resolveCourseFromInput(courseRaw);
    }
    if (!courseResolution.courseId) {
      return { ...base, reason: 'course_not_found' };
    }

    const ownerId = options.guardianOwnerId || options.staffUserId || null;
    if (!ownerId) {
      return { ...base, reason: 'missing_owner' };
    }

    const wholeName = [firstNames, [lastNameP, lastNameM].filter(Boolean).join(' ')].filter(Boolean).join(' ').trim();
    const enrollmentDate = (intake.student_enrollment_date || '').trim();
    const nowDate = new Date().toISOString().slice(0, 10);
    const livesWith = Array.isArray(intake.student_lives_with)
      ? intake.student_lives_with.filter(Boolean).join(', ')
      : '';

    const payload = {
      first_name: firstNames,
      apellido_paterno: lastNameP,
      apellido_materno: lastNameM || null,
      whole_name: wholeName || null,
      run: formattedRun,
      run_numero: Number.isFinite(runNumber) ? runNumber : null,
      run_verificador: dvInput || null,
      date_of_birth: birthDate,
      owner_id: ownerId,
      curso: courseResolution.courseId,
      nivel: courseResolution.course?.nivel || null,
      nombre_social: intake.student_social_name || null,
      genero: intake.student_gender || null,
      nacionalidad: intake.student_nationality || null,
      fecha_matricula: enrollmentDate || nowDate,
      fecha_incorporacion: enrollmentDate || null,
      fecha_retiro: (intake.student_withdrawal_date || '').trim() || null,
      motivo_retiro: (intake.student_withdrawal_reason || '').trim() || null,
      repite_curso_actual:
        typeof intake.student_repeat_current === 'boolean'
          ? intake.student_repeat_current ? 'SI' : 'NO'
          : null,
      institucion_procedencia: intake.student_previous_institution || null,
      direccion: intake.student_address || null,
      comuna: intake.student_commune || null,
      con_quien_vive: livesWith || null,
      estado_std: 'MATRICULADO'
    } as Record<string, any>;

    const { data: created, error: createError } = await supabase
      .from('students')
      .insert(payload)
      .select('id')
      .single();
    if (createError) {
      console.error('ensureStudentFromIntake insert error', createError);
      if ((createError as any)?.code === '23505') {
        // Unique violation fallback: fetch and link
        const { data: dupe } = await supabase
          .from('students')
          .select('id')
          .or(runFilters.join(','))
          .maybeSingle();
        if (dupe?.id) {
          const linked = await ensureGuardianStudentLink(
            dupe.id,
            options.guardianId,
            options.guardianRelationship || (intake.guardian_relationship ?? null)
          );
          return {
            ...base,
            studentId: dupe.id,
            linked,
            reason: linked ? undefined : 'link_failed'
          };
        }
      }
      return { ...base, reason: 'error', details: createError.message };
    }

    const studentId = created?.id || null;
    const linked = studentId
      ? await ensureGuardianStudentLink(
          studentId,
          options.guardianId,
          options.guardianRelationship || (intake.guardian_relationship ?? null)
        )
      : false;
    return {
      created: Boolean(studentId),
      linked,
      studentId,
      courseId: courseResolution.courseId,
      reason: linked ? undefined : 'link_failed'
    };
  } catch (e: any) {
    console.error('ensureStudentFromIntake unexpected error', e);
    return { ...base, reason: 'error', details: e?.message || String(e) };
  }
}

// =====================================================
// STORAGE FUNCTIONS FOR PDF DOCUMENTS
// =====================================================

/**
 * Upload PDF blob to Supabase Storage
 * @param pdfBlob - The PDF file as a Blob
 * @param enrollmentId - The enrollment ID
 * @param documentType - Document type (e.g., 'PAGARE')
 * @returns Storage path if successful, null otherwise
 */
export async function uploadDocumentPDF(
  pdfBlob: Blob,
  enrollmentId: string,
  documentType: string = 'PAGARE'
): Promise<string | null> {
  try {
    // Generate unique filename with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `${enrollmentId}_${documentType}_${timestamp}.pdf`;
    const path = `${enrollmentId}/${filename}`;

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from('enrollment-documents')
      .upload(path, pdfBlob, {
        contentType: 'application/pdf',
        upsert: false // Don't overwrite existing files
      });

    if (error) {
      console.error('Upload PDF error:', error);
      toast.error('No se pudo subir el PDF al almacenamiento');
      return null;
    }

    console.log('PDF uploaded successfully:', data.path);
    return data.path;
  } catch (err) {
    console.error('Upload PDF exception:', err);
    toast.error('Error al subir el PDF');
    return null;
  }
}

/**
 * Get signed URL for a document in Storage
 * @param storagePath - Path to the file in Storage
 * @param expiresIn - Expiration time in seconds (default: 3600 = 1 hour)
 * @returns Signed URL if successful, null otherwise
 */
export async function getDocumentPDFUrl(
  storagePath: string,
  expiresIn: number = 3600
): Promise<string | null> {
  try {
    console.log('🔍 Getting signed URL for path:', storagePath, 'expires in:', expiresIn);
    
    const { data, error } = await supabase.storage
      .from('enrollment-documents')
      .createSignedUrl(storagePath, expiresIn);

    if (error) {
      console.error('Get signed URL error:', error);
      console.error('Error details:', JSON.stringify(error, null, 2));
      toast.error('No se pudo obtener la URL del documento');
      return null;
    }

    console.log('✅ Signed URL created successfully:', data.signedUrl);
    return data.signedUrl;
  } catch (err) {
    console.error('Get signed URL exception:', err);
    toast.error('Error al obtener URL del documento');
    return null;
  }
}

/**
 * Delete PDF from Storage (admin only)
 * @param storagePath - Path to the file in Storage
 * @returns true if successful, false otherwise
 */
export async function deleteDocumentPDF(storagePath: string): Promise<boolean> {
  try {
    const { error } = await supabase.storage
      .from('enrollment-documents')
      .remove([storagePath]);

    if (error) {
      console.error('Delete PDF error:', error);
      toast.error('No se pudo eliminar el PDF');
      return false;
    }

    toast.success('PDF eliminado del almacenamiento');
    return true;
  } catch (err) {
    console.error('Delete PDF exception:', err);
    toast.error('Error al eliminar PDF');
    return false;
  }
}

// =====================================================
// FINALIZE ENROLLMENT (RPC)
// =====================================================

/**
 * Ejecuta un dry-run de la finalización de matrícula para obtener un resumen sin aplicar cambios.
 * Llama al RPC finalize_enrollment con p_options.dry_run=true
 */
export async function finalizeEnrollmentPreview(
  enrollmentId: string,
  options: Record<string, any> = {}
): Promise<any> {
  try {
    const payload = { ...options, dry_run: true };
    const { data, error } = await supabase.rpc('finalize_enrollment', {
      p_enrollment_id: enrollmentId,
      p_options: payload
    });
    if (error) throw error;
    return data;
  } catch (e: any) {
    console.error('finalizeEnrollmentPreview error', e);
    const message = e?.message || 'No se pudo preparar la confirmación de matrícula';
    toast.error(message);
    throw e;
  }
}

/**
 * Confirma la matrícula (aplica cambios). Llama al RPC finalize_enrollment con dry_run=false
 */
export async function finalizeEnrollmentConfirm(
  enrollmentId: string,
  options: Record<string, any> = {}
): Promise<any> {
  try {
    const payload = { ...options, dry_run: false };
    const { data, error } = await supabase.rpc('finalize_enrollment', {
      p_enrollment_id: enrollmentId,
      p_options: payload
    });
    if (error) throw error;
    return data;
  } catch (e: any) {
    console.error('finalizeEnrollmentConfirm error', e);
    const message = e?.message || 'No se pudo confirmar la matrícula';
    toast.error(message);
    throw e;
  }
}

