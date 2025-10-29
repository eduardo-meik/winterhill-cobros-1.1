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
  type Row = { 
    student_id: string; 
    students: { 
      id: string; 
      whole_name?: string; 
      run?: string;
      first_name?: string;
      apellido_paterno?: string;
      apellido_materno?: string;
      nivel?: string;
      curso?: string;
      cursos?: {
        id: string;
        nom_curso?: string;
        nivel?: number;
        letra_curso?: string;
      } | null;
    } | null 
  };
  
  console.log('📚 listEnrollmentStudents: Fetching students for enrollment:', enrollmentId);
  
  const { data, error } = await supabase
    .from('enrollment_students')
    .select(`
      student_id, 
      students:student_id(
        id, 
        whole_name, 
        run,
        first_name,
        apellido_paterno,
        apellido_materno,
        nivel,
        curso,
        cursos:curso(
          id,
          nom_curso,
          nivel,
          letra_curso
        )
      )
    `)
    .eq('enrollment_id', enrollmentId) as { data: Row[] | null; error: any };
    
  if (error) {
    console.error('listEnrollmentStudents error', error);
    toast.error('Error cargando alumnos de la matrícula');
    return [];
  }
  
  const students = (data || []).map(r => {
    const apellidos = [r.students?.apellido_paterno, r.students?.apellido_materno].filter(Boolean).join(' ').trim();
    const cursoNombre = r.students?.cursos?.nom_curso || r.students?.nivel || r.students?.curso || '';
    
    return {
      id: r.students?.id || r.student_id,
      whole_name: r.students?.whole_name,
      run: r.students?.run,
      first_name: r.students?.first_name,
      last_name: (apellidos || undefined) as string | undefined,
      grade: cursoNombre, // Use curso name instead of nivel
      nivel: r.students?.nivel,
      curso: r.students?.curso,
      curso_nombre: cursoNombre // Add new field
    };
  });
  
  console.log('📚 listEnrollmentStudents: Students fetched:', students);
  
  return students;
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
  console.log('📄 getActivePagareTemplate: FORCING load from file (DB template has wrong format)...');
  
  // TEMPORARY FIX: Skip DB because template has _____ instead of {{placeholders}}
  // TODO: Update DB template with correct {{placeholder}} format
  
  // Load from file ALWAYS
  console.log('📄 Loading template from /contratos/pagare.txt');
  
  try {
    const response = await fetch('/contratos/pagare.txt');
    if (!response.ok) {
      throw new Error(`Failed to fetch template: ${response.status}`);
    }
    const content = await response.text();
    console.log('✅ Template loaded from file, length:', content.length);
    console.log('✅ File content preview (first 200 chars):', content.substring(0, 200));
    
    return {
      id: 'file-fallback',
      type: 'PAGARE',
      version: 1,
      content: content,
      active: true
    } as DocumentTemplate;
  } catch (fileError) {
    console.error('❌ Failed to load template from file:', fileError);
    toast.error('No se pudo cargar plantilla Pagaré desde archivo');
    return null;
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
}): PagarePayload {
  const { guardian, year, students, economic, paymentMethod } = opts;
  
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
    ].join('\n')
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

// 7. Render template with placeholders {{key}}
export function renderTemplate(raw: string, payload: Record<string, any>): string {
  return raw.replace(/{{\s*([a-zA-Z0-9_]+)\s*}}/g, (_m, key) => {
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
