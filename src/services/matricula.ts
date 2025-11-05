import { supabase } from './supabase';
import { templates } from '../contracts/templates';
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
  console.log('🔍 fetchCurrentGuardian called with userId:', userId);
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
  
  // Economic data
  monto_matricula?: number | string;
  colegiatura_anual?: number | string;
  cantidad_cuotas?: number | string;
  monto_cuota?: number | string;
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
    monto_matricula: formatCurrency(economic?.monto_matricula),
    colegiatura_anual: formatCurrency(economic?.colegiatura_anual),
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
  paymentMethod?: {
    cheques?: boolean;
    transferencia?: boolean;
    efectivo?: boolean;
    tarjeta?: boolean;
    pagare?: boolean;
  };
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

  const colegAnual = economic?.colegiatura_anual || 0;
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
    colegiatura_anual_texto: colegAnual ? `${numberToWordsEs(colegAnual)} pesos` : undefined,
    cantidad_cuotas: economic?.cantidad_cuotas?.toString() || '_______________',
    monto_cuota: formatCurrency(montoCuotaCalc),
    monto_cuota_texto: montoCuotaCalc ? `${numberToWordsEs(montoCuotaCalc)} pesos` : undefined,
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
    cheques_table: chequesTableHtml,
  };

  // Provide optional comuna for templates using {{guardian_comuna?}}
  // If address exists, prepend with comma; if address is empty, render comuna without comma.
  const _addr = (guardian.address || '').trim();
  const _com = (guardian.comuna || '').trim();
  (payload as any)['guardian_comuna?'] = _com ? (_addr ? `, ${_com}` : `${_com}`) : '';

  // Inject descuento placeholders for the Descuento por Planilla annex
  (payload as any).descuento_porcentaje = porcentajeDesc ? String(porcentajeDesc) : '0';
  (payload as any).descuento_motivo = descuentoMotivo || '—';
  (payload as any).condicion_especial_beca = descuentoCondiciones || '—';
  (payload as any).monto_total_descuento = porcentajeDesc > 0 ? formatCurrency(montoTotalDescuento) : '0';
  (payload as any).monto_neto_anual = (montoNetoAnual > 0) ? formatCurrency(montoNetoAnual) : (colegAnual ? formatCurrency(colegAnual) : '_______________');
  (payload as any).monto_cuota_neta = (montoCuotaNetaCalc > 0) ? formatCurrency(montoCuotaNetaCalc) : '_______________';

  return payload;
}

export function renderPrestacionWithAnnex(payload: PrestacionPayload, options: { annex?: 'descuento' | 'pagare' | null } = {}): string {
  const main = renderTemplate(templates.prestacion, payload);
  let combined = main;
  if (options.annex === 'descuento') {
    const annex = renderTemplate(templates.descuento, payload);
    combined = `${main}\n<div class="page-break"></div>\n${annex}`;
  } else if (options.annex === 'pagare') {
    const annex = renderTemplate(templates.pagare, payload);
    combined = `${main}\n<div class="page-break"></div>\n${annex}`;
  }
  return combined;
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
