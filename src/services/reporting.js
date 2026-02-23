import * as ExcelJS from 'exceljs';
import { supabase } from './supabase';
import { format } from 'date-fns';
import { normalizeRun } from '../utils/rut';

// Helper to format RUT (remove dots, keep dash if needed or remove it too depending on requirement)
// FICON requires RUT without dots. DV in separate column.
const formatRutFicon = (rut) => {
  if (!rut) return { body: '', dv: '' };
  const clean = rut.replace(/\./g, '').replace(/-/g, '').toUpperCase();
  if (clean.length < 2) return { body: clean, dv: '' };
  const body = clean.slice(0, -1);
  const dv = clean.slice(-1);
  return { body, dv };
};

export const generateLibroMatriculaReport = async () => {
  // Use the RPC function with all 34 columns
  const { data: records, error } = await supabase.rpc('generate_libro_matricula_report', {
    p_year: null,
    p_estado: null,
    p_enrollment_status: null
  });

  if (error) {
    console.error('Error calling RPC:', error);
    throw error;
  }

  if (!records || records.length === 0) {
    throw new Error('No se encontraron datos para generar el reporte');
  }

  // Map folio por RUN y año de matrícula desde enrollments.meta.folio
  const { data: enrollmentData, error: enrollmentError } = await supabase
    .from('enrollment_students')
    .select(`
      student:student_id ( id, run ),
      enrollment:enrollment_id ( id, year, meta )
    `);

  if (enrollmentError) {
    console.error('Error fetching enrollment folios:', enrollmentError);
  }

  const folioMap = new Map();
  (enrollmentData || []).forEach(item => {
    const studentRun = normalizeRun(item.student?.run);
    const enrollmentYear = item.enrollment?.year;
    const folio = item.enrollment?.meta?.folio;
    if (studentRun && enrollmentYear && folio) {
      folioMap.set(`${studentRun}__${enrollmentYear}`, folio);
    }
  });

  const workbook = new ExcelJS.Workbook();

  // Separate by nivel (Básica vs Media)
  const basica = records.filter(row => 
    row.nivel?.toLowerCase().includes('básica') || 
    row.nivel?.toLowerCase().includes('basica') ||
    row.nivel?.toLowerCase().includes('enseñanza básica')
  );
  
  const media = records.filter(row => 
    row.nivel?.toLowerCase().includes('media') ||
    row.nivel?.toLowerCase().includes('enseñanza media')
  );

  // Define columns matching CSV structure (34 columns)
  const columns = [
    { header: 'Numero de Inscripcion', key: 'numero', width: 18 },
    { header: 'Nivel', key: 'nivel', width: 18 },
    { header: 'Curso', key: 'curso', width: 18 },
    { header: 'Folio Matricula', key: 'folio_matricula', width: 18 },
    { header: 'Nombres', key: 'nombres', width: 20 },
    { header: 'Apellido Paterno', key: 'apellido_paterno', width: 18 },
    { header: 'Apellido Materno', key: 'apellido_materno', width: 18 },
    { header: 'Run estudiante', key: 'run_estudiante', width: 15 },
    { header: 'Fecha Nac Estudiante', key: 'fecha_nac_estudiante', width: 18 },
    { header: 'Nacionalidad', key: 'nacionalidad', width: 15 },
    { header: 'Género Estudiante', key: 'genero_estudiante', width: 16 },
    { header: '  ¿Con quién vive el estudiante?', key: 'con_quien_vive', width: 35 },
    { header: 'Dirección Estudiante', key: 'direccion_estudiante', width: 35 },
    { header: 'Comuna', key: 'comuna', width: 18 },
    { header: '  ¿El estudiante repite el curso actual?  ', key: 'repite_curso', width: 40 },
    { header: '  ¿Cuál es la institución de procedencia del estudiante?  ', key: 'institucion_procedencia', width: 50 },
    { header: '¿Cuál es el nombre del apoderado? ', key: 'nombre_apoderado', width: 35 },
    { header: '  ¿Cuál es el apellido paterno del apoderado?  ', key: 'apellido_paterno_apoderado', width: 45 },
    { header: '  ¿Cuál es el apellido materno del apoderado?  ', key: 'apellido_materno_apoderado', width: 45 },
    { header: '¿Cuál es su relación con el estudiante?', key: 'relacion_apoderado', width: 38 },
    { header: 'Fecha nacimiento apoderado', key: 'fecha_nac_apoderado', width: 25 },
    { header: '  ¿Cuál es el RUT del apoderado?  ', key: 'run_apoderado', width: 35 },
    { header: '  ¿Cuál es el nivel educacional del apoderado?  ', key: 'nivel_educacional_apoderado', width: 45 },
    { header: '  ¿Cuál es la dirección de residencia del apoderado?  ', key: 'direccion_apoderado', width: 50 },
    { header: '  ¿Cuál es la comuna de residencia del apoderado? ', key: 'comuna_apoderado', width: 45 },
    { header: '  ¿Cuál es el email de contacto del apoderado?  ', key: 'email_apoderado', width: 45 },
    { header: '¿Cuál es su teléfono?', key: 'telefono_apoderado', width: 20 },
    { header: 'Apoderado Secundario', key: 'apoderado_secundario', width: 35 },
    { header: 'Rut apoderado secundario', key: 'run_apoderado_secundario', width: 25 },
    { header: 'Fecha Nacimiento', key: 'fecha_nac_apoderado_secundario', width: 18 },
    { header: 'Añada el teléfono del contacto distinto al apoderado si fuese el caso', key: 'telefono_apoderado_secundario', width: 60 },
    { header: 'mail apoderado secundario', key: 'email_apoderado_secundario', width: 30 },
    { header: 'fecha de retiro del estudiante ', key: 'fecha_retiro', width: 30 },
    { header: '  motivo del retiro del estudiante ', key: 'motivo_retiro', width: 35 },
    { header: 'CONDICION', key: 'condicion', width: 20 }
  ];

  // Helper to add rows with correlative numbering per level
  const addRowsToSheet = (sheet, list, startNumber = 1) => {
    list.forEach((item, idx) => {
      const folioKey = `${normalizeRun(item.run_estudiante)}__${item.year_matricula || ''}`;
      const folioMatricula = folioMap.get(folioKey) || '';

      sheet.addRow({
        numero: startNumber + idx,
        nivel: item.nivel || '',
        curso: item.curso || '',
        folio_matricula: folioMatricula,
        nombres: item.nombres || '',
        apellido_paterno: item.apellido_paterno || '',
        apellido_materno: item.apellido_materno || '',
        run_estudiante: item.run_estudiante || '',
        fecha_nac_estudiante: item.fecha_nac_estudiante || '',
        nacionalidad: item.nacionalidad || '',
        genero_estudiante: item.genero_estudiante || '',
        con_quien_vive: item.con_quien_vive || '',
        direccion_estudiante: item.direccion_estudiante || '',
        comuna: item.comuna_estudiante || '',
        repite_curso: item.repite_curso || '',
        institucion_procedencia: item.institucion_procedencia || '',
        nombre_apoderado: item.nombre_apoderado || '',
        apellido_paterno_apoderado: item.apellido_paterno_apoderado || '',
        apellido_materno_apoderado: item.apellido_materno_apoderado || '',
        relacion_apoderado: item.relacion_apoderado || '',
        fecha_nac_apoderado: item.fecha_nac_apoderado || '',
        run_apoderado: item.run_apoderado || '',
        nivel_educacional_apoderado: item.nivel_educacional_apoderado || '',
        direccion_apoderado: item.direccion_apoderado || '',
        comuna_apoderado: item.comuna_apoderado || '',
        email_apoderado: item.email_apoderado || '',
        telefono_apoderado: item.telefono_apoderado || '',
        apoderado_secundario: item.nombre_apoderado_secundario || '',
        run_apoderado_secundario: item.run_apoderado_secundario || '',
        fecha_nac_apoderado_secundario: item.fecha_nac_apoderado_secundario || '',
        telefono_apoderado_secundario: item.telefono_apoderado_secundario || '',
        email_apoderado_secundario: item.email_apoderado_secundario || '',
        fecha_retiro: item.fecha_retiro || '',
        motivo_retiro: item.motivo_retiro || '',
        condicion: item.condicion || ''
      });
    });
  };

  // Create Básica sheet
  if (basica.length > 0) {
    const sheetBasica = workbook.addWorksheet('Enseñanza Básica');
    sheetBasica.columns = columns;
    addRowsToSheet(sheetBasica, basica, 1);
  }

  // Create Media sheet
  if (media.length > 0) {
    const sheetMedia = workbook.addWorksheet('Enseñanza Media');
    sheetMedia.columns = columns;
    addRowsToSheet(sheetMedia, media, 1);
  }

  const buffer = await workbook.xlsx.writeBuffer();
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
};

export const generateFiconReport = async () => {
  // P8: FICON Format
  // RUT sin puntos, DV separado.
  // Uses the same RPC as Libro Matrícula to ensure data consistency
  
  const { data: records, error } = await supabase.rpc('generate_libro_matricula_report', {
    p_year: null,
    p_estado: null,
    p_enrollment_status: null
  });

  if (error) {
    console.error('Error calling RPC for FICON:', error);
    throw error;
  }

  if (!records || records.length === 0) {
    throw new Error('No se encontraron datos para generar el reporte FICON');
  }

  console.log(`📊 FICON: Processing ${records.length} student records`);

  // Get financial data from enrollments through enrollment_students relationship
  // IMPORTANT: Don't filter by year or status here - get ALL enrollments and let the RPC filter
  const { data: enrollmentData, error: enrollmentError } = await supabase
    .from('enrollment_students')
    .select(`
      student_id,
      enrollment:enrollment_id (
        id,
        year,
        meta,
        status
      )
    `);

  if (enrollmentError) {
    console.error('Error fetching enrollment data:', enrollmentError);
  } else {
    console.log(`📊 FICON: Found ${(enrollmentData || []).length} enrollment records`);
  }

  // Also get student RUNs to map correctly
  const { data: students, error: studentsError } = await supabase
    .from('students')
    .select('id, run');

  if (studentsError) {
    console.error('Error fetching students:', studentsError);
  } else {
    console.log(`📊 FICON: Found ${(students || []).length} students`);
  }

  // Create student_id -> RUN mapping (normalized)
  const studentRunMap = new Map();
  const runToIdMap = new Map(); // Reverse mapping for lookup
  (students || []).forEach(st => {
    if (st.id && st.run) {
      const normalizedRun = normalizeRun(st.run);
      studentRunMap.set(st.id, normalizedRun);
      runToIdMap.set(normalizedRun, st.id);
    }
  });

  // Create a map of NORMALIZED student RUN -> financial data
  // This ensures each student gets their own enrollment's financial information
  const financialDataMap = new Map(); // key: normalized RUN or RUN__year
  let mappedCount = 0;
  
  (enrollmentData || []).forEach(item => {
    if (item.student_id && item.enrollment) {
      const meta = item.enrollment.meta || {};
      const studentRun = studentRunMap.get(item.student_id);
      const enrollmentYear = item.enrollment.year;
      
      if (studentRun) {
        // Build medio_pago string from payment method flags
        const mediosPago = [];
        if (meta.forma_pago_cheques) mediosPago.push('Cheques');
        if (meta.forma_pago_transferencia) mediosPago.push('Transferencia');
        if (meta.forma_pago_efectivo) mediosPago.push('Efectivo');
        if (meta.forma_pago_tarjeta) mediosPago.push('Tarjeta');
        if (meta.forma_pago_pagare) mediosPago.push('Pagaré');
        if (meta.forma_pago_descuento_planilla) mediosPago.push('Descuento Planilla');
        if (meta.prioritario) mediosPago.push('Prioritario');
        
        const medioPagoStr = mediosPago.length > 0 ? mediosPago.join(', ') : 'No especificado';
        
        const financialData = {
          arancel: meta.colegiatura_anual || 0,
          matricula: meta.monto_matricula || 0,
          cuotas: meta.cantidad_cuotas || 0,
          monto_cuota: meta.monto_cuota || 0,
          medio_pago: medioPagoStr,
          folio: meta.folio || ''
        };
        const keyWithYear = `${studentRun}__${enrollmentYear || ''}`;
        financialDataMap.set(keyWithYear, financialData);
        financialDataMap.set(studentRun, financialData); // fallback
        mappedCount++;
        
        // Debug: log first few mappings
        if (mappedCount <= 3) {
          console.log(`💰 FICON Mapping ${mappedCount}:`, {
            run: studentRun,
            arancel: financialData.arancel,
            medio_pago: financialData.medio_pago,
            enrollment_year: enrollmentYear,
            enrollment_status: item.enrollment.status
          });
        }
      }
    }
  });
  
  console.log(`💰 FICON: Mapped ${mappedCount} students with financial data`);

  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('FICON');

  sheet.columns = [
    { header: 'RUT_ALUMNO', key: 'rut_body', width: 10 },
    { header: 'DV_ALUMNO', key: 'rut_dv', width: 5 },
    { header: 'AP_PATERNO', key: 'ap_pat', width: 15 },
    { header: 'AP_MATERNO', key: 'ap_mat', width: 15 },
    { header: 'NOMBRES', key: 'nombres', width: 20 },
    { header: 'FOLIO_MATRICULA', key: 'folio_matricula', width: 18 },
    { header: 'RUT_APODERADO', key: 'g_rut_body', width: 10 },
    { header: 'DV_APODERADO', key: 'g_rut_dv', width: 5 },
    { header: 'NOMBRE_APODERADO', key: 'g_name', width: 30 },
    { header: 'MEDIO_PAGO', key: 'medio_pago', width: 20 },
    { header: 'ARANCEL_ANUAL', key: 'arancel', width: 15 },
    { header: 'MATRICULA', key: 'matricula', width: 15 },
    { header: 'N_CUOTAS', key: 'cuotas', width: 10 },
    { header: 'MONTO_CUOTA', key: 'monto_cuota', width: 15 },
  ];

  let matchedCount = 0;
  let unmatchedCount = 0;

  records.forEach((record, index) => {
    const stRut = formatRutFicon(record.run_estudiante);
    const gRut = formatRutFicon(record.run_apoderado);
    
    // Normalize the student RUN from the record for lookup
    const normalizedStudentRun = normalizeRun(record.run_estudiante);
    
    // Get financial data using NORMALIZED student's RUN as key
    const recordYear = record.year_matricula || record.year || '';
    const financialData = financialDataMap.get(`${normalizedStudentRun}__${recordYear}`) || financialDataMap.get(normalizedStudentRun);
    
    if (financialData) {
      matchedCount++;
      // Debug first few matches
      if (matchedCount <= 3) {
        console.log(`✅ Match ${matchedCount}:`, {
          student_run: record.run_estudiante,
          normalized: normalizedStudentRun,
          arancel: financialData.arancel,
          medio_pago: financialData.medio_pago
        });
      }
    } else {
      unmatchedCount++;
      // Debug first few unmatched
      if (unmatchedCount <= 3) {
        console.log(`❌ No Match ${unmatchedCount}:`, {
          student_run: record.run_estudiante,
          normalized: normalizedStudentRun,
          student_name: record.nombres
        });
      }
    }
    
    const dataToUse = financialData || {
      arancel: 0,
      matricula: 0,
      cuotas: 0,
      monto_cuota: 0,
      medio_pago: 'No especificado',
      folio: ''
    };
    
    sheet.addRow({
      rut_body: stRut.body,
      rut_dv: stRut.dv,
      ap_pat: record.apellido_paterno || '',
      ap_mat: record.apellido_materno || '',
      nombres: record.nombres || '',
      g_rut_body: gRut.body,
      g_rut_dv: gRut.dv,
      g_name: `${record.nombre_apoderado || ''} ${record.apellido_paterno_apoderado || ''} ${record.apellido_materno_apoderado || ''}`.trim(),
      medio_pago: dataToUse.medio_pago,
      arancel: dataToUse.arancel,
      matricula: dataToUse.matricula,
      cuotas: dataToUse.cuotas,
      monto_cuota: dataToUse.monto_cuota,
      folio_matricula: dataToUse.folio || ''
    });
  });
  
  console.log(`📊 FICON Summary: ${matchedCount} matched, ${unmatchedCount} unmatched out of ${records.length} total`);

  const buffer = await workbook.xlsx.writeBuffer();
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
};

// Reporte de matrículas con medio de pago Cheques
export const generateChequesReport = async () => {
  // Trae cheques y la matrícula asociada con guardian y estudiantes
  const { data: cheques, error } = await supabase
    .from('cheques')
    .select(`
      id, numero_serie, banco, fecha_emision, monto, estado, notas, created_at, updated_at,
      enrollment:enrollment_id (
        id,
        year,
        status,
        meta,
        guardian:guardian_id (
          id, run, first_name, last_name, email, phone
        ),
        enrollment_students (
        student:student_id (
            id, run, first_name, apellido_paterno, apellido_materno,
            curso:curso (
              id, nom_curso, nivel
            )
          )
        )
      )
    `);

  if (error) {
    console.error('Error fetching cheques:', error);
    throw error;
  }

  if (!cheques || cheques.length === 0) {
    throw new Error('No se encontraron cheques para generar el reporte');
  }

  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Cheques');

  sheet.columns = [
    { header: 'AÑO', key: 'year', width: 8 },
    { header: 'ESTADO_MATRICULA', key: 'enrollment_status', width: 18 },
    { header: 'CURSO', key: 'curso', width: 18 },
    { header: 'FOLIO_MATRICULA', key: 'folio_matricula', width: 24 },
    { header: 'FOLIO_PAGARE_O_DOC', key: 'folio_pagare', width: 24 },
    { header: 'RUN_ALUMNO', key: 'student_run_body', width: 12 },
    { header: 'DV_ALUMNO', key: 'student_run_dv', width: 6 },
    { header: 'ALUMNO', key: 'student_name', width: 28 },
    { header: 'RUN_APODERADO', key: 'guardian_run_body', width: 12 },
    { header: 'DV_APODERADO', key: 'guardian_run_dv', width: 6 },
    { header: 'APODERADO', key: 'guardian_name', width: 30 },
    { header: 'EMAIL_APODERADO', key: 'guardian_email', width: 26 },
    { header: 'PHONE_APODERADO', key: 'guardian_phone', width: 18 },
    { header: 'MEDIO_PAGO', key: 'medio_pago', width: 12 },
    { header: 'NUMERO_CHEQUE', key: 'numero_serie', width: 16 },
    { header: 'BANCO', key: 'banco', width: 18 },
    { header: 'FECHA_EMISION', key: 'fecha_emision', width: 14 },
    { header: 'MONTO', key: 'monto', width: 14 },
    { header: 'ESTADO_CHEQUE', key: 'estado_cheque', width: 14 },
    { header: 'NOTAS', key: 'notas', width: 30 },
    { header: 'CREATED_AT', key: 'created_at', width: 20 },
    { header: 'UPDATED_AT', key: 'updated_at', width: 20 },
    { header: 'ID_CHEQUE', key: 'cheque_id', width: 36 },
    { header: 'ID_MATRICULA', key: 'enrollment_id', width: 36 }
  ];

  cheques.forEach((chq) => {
    const enrollment = chq.enrollment || {};
    const meta = enrollment.meta || {};
    const guardian = enrollment.guardian || {};
    const studentsList = (enrollment.enrollment_students || []).map(es => es.student).filter(Boolean);
    const studentsToUse = studentsList.length > 0 ? studentsList : [null];

    const guardianRut = formatRutFicon(guardian.run);
    const guardianName = `${guardian.first_name || ''} ${guardian.last_name || ''}`.trim();
    studentsToUse.forEach(student => {
      const cursoNombre = meta.curso_nombre || meta.curso || meta.course || student?.curso?.nom_curso || '';
      const studentRut = formatRutFicon(student?.run || '');
      const studentName = student ? `${student.first_name || ''} ${student.apellido_paterno || ''} ${student.apellido_materno || ''}`.trim() : '';

      sheet.addRow({
        year: enrollment.year || '',
        enrollment_status: enrollment.status || '',
        curso: cursoNombre,
        folio_matricula: meta.folio || '',
        folio_pagare: chq.folio_number || '',
        student_run_body: studentRut.body,
        student_run_dv: studentRut.dv,
        student_name: studentName,
        guardian_run_body: guardianRut.body,
        guardian_run_dv: guardianRut.dv,
        guardian_name: guardianName,
        guardian_email: guardian.email || '',
        guardian_phone: guardian.phone || guardian.telefono || '',
        medio_pago: 'Cheques',
        numero_serie: chq.numero_serie || '',
        banco: chq.banco || '',
        fecha_emision: chq.fecha_emision || '',
        monto: chq.monto || 0,
        estado_cheque: chq.estado || '',
        notas: chq.notas || '',
        created_at: chq.created_at || '',
        updated_at: chq.updated_at || '',
        cheque_id: chq.id,
        enrollment_id: enrollment.id || ''
      });
    });
  });

  const buffer = await workbook.xlsx.writeBuffer();
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
};
