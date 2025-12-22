import * as ExcelJS from 'exceljs';
import { supabase } from './supabase';
import { format } from 'date-fns';

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
      sheet.addRow({
        numero: startNumber + idx,
        nivel: item.nivel || '',
        curso: item.curso || '',
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
  
  const { data: records, error } = await supabase
    .from('enrollment_students')
    .select(`
      student:student_id (
        id,
        first_name,
        apellido_paterno,
        apellido_materno,
        run
      ),
      enrollment:enrollment_id!inner (
        id,
        year,
        status,
        meta,
        guardian:guardian_id (
          id,
          first_name,
          last_name,
          run
        )
      )
    `)
    .in('enrollment.status', ['completed', 'ACTIVO'])
    .eq('enrollment.year', new Date().getFullYear());

  if (error) throw error;

  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('FICON');

  sheet.columns = [
    { header: 'RUT_ALUMNO', key: 'rut_body', width: 10 },
    { header: 'DV_ALUMNO', key: 'rut_dv', width: 5 },
    { header: 'AP_PATERNO', key: 'ap_pat', width: 15 },
    { header: 'AP_MATERNO', key: 'ap_mat', width: 15 },
    { header: 'NOMBRES', key: 'nombres', width: 20 },
    { header: 'RUT_APODERADO', key: 'g_rut_body', width: 10 },
    { header: 'DV_APODERADO', key: 'g_rut_dv', width: 5 },
    { header: 'NOMBRE_APODERADO', key: 'g_name', width: 30 },
    { header: 'ARANCEL_ANUAL', key: 'arancel', width: 15 },
    { header: 'MATRICULA', key: 'matricula', width: 15 },
    { header: 'N_CUOTAS', key: 'cuotas', width: 10 },
    { header: 'MONTO_CUOTA', key: 'monto_cuota', width: 15 },
  ];

  (records || []).forEach(record => {
    const st = record.student || {};
    const enr = record.enrollment || {};
    const g = enr.guardian || {};
    const meta = enr.meta || {};

    const stRut = formatRutFicon(st.run);
    const gRut = formatRutFicon(g.run);
    
    sheet.addRow({
      rut_body: stRut.body,
      rut_dv: stRut.dv,
      ap_pat: st.apellido_paterno || '',
      ap_mat: st.apellido_materno || '',
      nombres: st.first_name,
      g_rut_body: gRut.body,
      g_rut_dv: gRut.dv,
      g_name: `${g.first_name || ''} ${g.last_name || ''}`.trim(),
      arancel: meta.colegiatura_anual || 0,
      matricula: meta.monto_matricula || 0,
      cuotas: meta.cantidad_cuotas || 0,
      monto_cuota: meta.monto_cuota || 0
    });
  });

  const buffer = await workbook.xlsx.writeBuffer();
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
};
