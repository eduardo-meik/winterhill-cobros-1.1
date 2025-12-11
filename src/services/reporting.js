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
  // Fetch all active enrollments via enrollment_students to get 1 row per student
  // We join student (with course) and enrollment (with guardian)
  const { data: records, error } = await supabase
    .from('enrollment_students')
    .select(`
      student:student_id (
        id,
        first_name,
        apellido_paterno,
        apellido_materno,
        run,
        date_of_birth,
        genero,
        direccion,
        comuna,
        curso_data:curso (
          id,
          nivel,
          nom_curso
        )
      ),
      enrollment:enrollment_id!inner (
        id,
        created_at,
        year,
        status,
        meta,
        guardian:guardian_id (
          id,
          first_name,
          last_name,
          run,
          email,
          phone,
          address
        )
      )
    `)
    .in('enrollment.status', ['completed', 'ACTIVO']) // Support both status just in case
    .eq('enrollment.year', new Date().getFullYear())
    .order('enrollment(created_at)', { ascending: true });

  if (error) throw error;

  const workbook = new ExcelJS.Workbook();

  // Process data
  const basica = [];
  const media = [];

  (records || []).forEach(record => {
    const st = record.student;
    const enr = record.enrollment;
    
    if (!st || !enr) return;

    const guardian = enr.guardian || {};
    const nivel = st.curso_data?.nivel; // 110 = Basica, 310 = Media

    const rowData = {
      ...st,
      enrollment: enr,
      guardian: guardian
    };

    if (nivel === 310) {
      media.push(rowData);
    } else {
      // Default to Basica (includes 110 and Pre-K/Kinder if any)
      basica.push(rowData);
    }
  });

  // Sort by enrollment date
  const sortByDate = (a, b) => new Date(a.enrollment.created_at) - new Date(b.enrollment.created_at);
  basica.sort(sortByDate);
  media.sort(sortByDate);

  // Helper to add rows
  const addRowsToSheet = (sheet, list) => {
    list.forEach((item, idx) => {
      const g = item.guardian || {};
      
      sheet.addRow({
        num: idx + 1,
        date: format(new Date(item.enrollment.created_at), 'dd/MM/yyyy HH:mm'),
        rut: item.run,
        ap_pat: item.apellido_paterno || '',
        ap_mat: item.apellido_materno || '',
        nombres: item.first_name,
        curso: item.curso_data?.nom_curso || 'Sin Curso',
        gender: item.genero,
        dob: item.date_of_birth,
        address: item.direccion,
        commune: item.comuna,
        g_rut: g.run,
        g_name: `${g.first_name || ''} ${g.last_name || ''}`.trim(),
        email: g.email,
        phone: g.phone
      });
    });
  };

  const sheetBasica = workbook.addWorksheet('Básica');
  sheetBasica.columns = [
      { header: 'N°', key: 'num', width: 5 },
      { header: 'Fecha Matrícula', key: 'date', width: 18 },
      { header: 'RUT Alumno', key: 'rut', width: 12 },
      { header: 'Ap. Paterno', key: 'ap_pat', width: 15 },
      { header: 'Ap. Materno', key: 'ap_mat', width: 15 },
      { header: 'Nombres', key: 'nombres', width: 20 },
      { header: 'Curso', key: 'curso', width: 15 },
      { header: 'Sexo', key: 'gender', width: 8 },
      { header: 'F. Nacim.', key: 'dob', width: 12 },
      { header: 'Dirección', key: 'address', width: 30 },
      { header: 'Comuna', key: 'commune', width: 15 },
      { header: 'RUT Apoderado', key: 'g_rut', width: 12 },
      { header: 'Nombre Apoderado', key: 'g_name', width: 25 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'Teléfono', key: 'phone', width: 15 },
  ];
  addRowsToSheet(sheetBasica, basica);

  const sheetMedia = workbook.addWorksheet('Media');
  sheetMedia.columns = sheetBasica.columns;
  addRowsToSheet(sheetMedia, media);

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
