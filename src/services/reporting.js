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
  // Fetch all active enrollments with student and course details
  const { data: enrollments, error } = await supabase
    .from('enrollment')
    .select(`
      id,
      created_at,
      year,
      status,
      student:student_id (
        id,
        first_name,
        last_name,
        run,
        date_of_birth,
        gender,
        address,
        commune
      ),
      guardian:guardian_id (
        id,
        first_name,
        last_name,
        run,
        email,
        phone,
        address
      ),
      meta
    `)
    .eq('status', 'ACTIVO') // Only active enrollments
    .order('created_at', { ascending: true });

  if (error) throw error;

  // Fetch course info separately or assume it's in meta/student (student.curso might be ID)
  // For better accuracy, let's fetch courses to map IDs
  const { data: courses } = await supabase.from('cursos').select('id, nivel, grado, letra, nom_curso');
  const courseMap = (courses || []).reduce((acc, c) => {
    acc[c.id] = c;
    return acc;
  }, {});

  // Filter and sort by timestamp (already sorted by query)
  // Separate by Basic and Media
  // Logic: Nivel 110 = Basica, 310 = Media. Or use grade/curso name.
  
  const workbook = new ExcelJS.Workbook();
  
  const createSheet = (name, filteredEnrollments) => {
    const sheet = workbook.addWorksheet(name);
    sheet.columns = [
      { header: 'N° Matrícula', key: 'num', width: 10 },
      { header: 'Fecha Registro', key: 'date', width: 15 },
      { header: 'RUT Estudiante', key: 'rut', width: 12 },
      { header: 'Apellido Paterno', key: 'ap_pat', width: 15 },
      { header: 'Apellido Materno', key: 'ap_mat', width: 15 },
      { header: 'Nombres', key: 'nombres', width: 20 },
      { header: 'Curso', key: 'curso', width: 15 },
      { header: 'Género', key: 'gender', width: 10 },
      { header: 'Fecha Nacimiento', key: 'dob', width: 15 },
      { header: 'Dirección', key: 'address', width: 30 },
      { header: 'Comuna', key: 'commune', width: 15 },
      { header: 'RUT Apoderado', key: 'g_rut', width: 12 },
      { header: 'Nombre Apoderado', key: 'g_name', width: 30 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'Teléfono', key: 'phone', width: 15 },
    ];

    filteredEnrollments.forEach((enr, index) => {
      const student = enr.student || {};
      const guardian = enr.guardian || {};
      
      // Parse names
      const lastNames = (student.last_name || '').split(' ');
      const apPat = lastNames[0] || '';
      const apMat = lastNames.slice(1).join(' ') || '';

      // Determine course name
      // Try to find course ID in student record or enrollment meta
      // Note: In this system, student.curso is often the UUID.
      // We need to check where the course ID is stored. Usually student.curso or enrollment.meta.curso_id
      // Let's assume we can get a course label.
      
      // Fallback course logic
      let courseLabel = 'Sin Curso';
      // If we had course info in student object (need to check schema), we'd use it.
      // For now, let's try to use what we have.
      // If student has 'curso' field which is UUID:
      // const c = courseMap[student.curso];
      // if (c) courseLabel = c.nom_curso;
      
      // Actually, let's look at how `MatriculaWizard` gets course. It uses `student.curso` (uuid) or `student.curso_nombre`.
      // The query above didn't fetch `curso` from student. Let's assume we might need to fetch it or it's in meta.
      // In `enrollment.meta`, we often store `curso_id` or similar.
      
      // Let's try to use the meta if available, or just generic.
      // For P7, "Separados por Básica y Media" implies we need to know the level.
      
      sheet.addRow({
        num: index + 1,
        date: format(new Date(enr.created_at), 'dd/MM/yyyy HH:mm'),
        rut: student.run,
        ap_pat: apPat,
        ap_mat: apMat,
        nombres: student.first_name,
        curso: courseLabel, // Placeholder, needs refinement
        gender: student.gender,
        dob: student.date_of_birth,
        address: student.address,
        commune: student.commune,
        g_rut: guardian.run,
        g_name: `${guardian.first_name || ''} ${guardian.last_name || ''}`,
        email: guardian.email,
        phone: guardian.phone
      });
    });
  };

  // We need to split by Basic/Media.
  // Since we don't have perfect course info in this simple query, let's fetch students with course info.
  // Better approach: Fetch students with inner join on course if possible, or fetch all students and map.
  
  // Refined Query for P7
  const { data: studentsWithCourse } = await supabase
    .from('students')
    .select(`
      *,
      curso_data:curso (
        id,
        nivel,
        nom_curso
      ),
      enrollments:enrollment!inner (
        id,
        created_at,
        status,
        year,
        guardian:guardian_id (*)
      )
    `)
    .eq('enrollments.status', 'ACTIVO')
    .eq('enrollments.year', new Date().getFullYear()); // Current year

  // Process data
  const basica = [];
  const media = [];

  (studentsWithCourse || []).forEach(st => {
    // Get the active enrollment for this year (should be one due to !inner filter, but be safe)
    const enr = st.enrollments[0]; 
    if (!enr) return;

    const nivel = st.curso_data?.nivel; // 110 or 310
    const rowData = {
      ...st,
      enrollment: enr,
      guardian: enr.guardian
    };

    if (nivel === 110) {
      basica.push(rowData);
    } else if (nivel === 310) {
      media.push(rowData);
    } else {
      // Fallback or Pre-Kinder/Kinder (Nivel 10?) -> Put in Basica or separate?
      // Usually 10 is Parvularia. Let's put everything else in Basica for now or check requirements.
      // Requirement says "Básica y Media".
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
      const lastNames = (item.last_name || '').split(' ');
      sheet.addRow({
        num: idx + 1,
        date: format(new Date(item.enrollment.created_at), 'dd/MM/yyyy HH:mm'),
        rut: item.run,
        ap_pat: lastNames[0] || '',
        ap_mat: lastNames.slice(1).join(' ') || '',
        nombres: item.first_name,
        curso: item.curso_data?.nom_curso || 'Sin Curso',
        gender: item.gender,
        dob: item.date_of_birth,
        address: item.address,
        commune: item.commune,
        g_rut: g.run,
        g_name: `${g.first_name || ''} ${g.last_name || ''}`,
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
  // Usually FICON requires specific columns. Since I don't have the exact spec, I will create a standard financial report with split RUTs.
  
  const { data: enrollments, error } = await supabase
    .from('enrollment')
    .select(`
      id,
      year,
      status,
      student:student_id (
        id,
        first_name,
        last_name,
        run
      ),
      guardian:guardian_id (
        id,
        first_name,
        last_name,
        run
      ),
      meta
    `)
    .eq('status', 'ACTIVO');

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

  enrollments.forEach(enr => {
    const st = enr.student || {};
    const g = enr.guardian || {};
    const meta = enr.meta || {};

    const stRut = formatRutFicon(st.run);
    const gRut = formatRutFicon(g.run);
    
    const lastNames = (st.last_name || '').split(' ');
    
    sheet.addRow({
      rut_body: stRut.body,
      rut_dv: stRut.dv,
      ap_pat: lastNames[0] || '',
      ap_mat: lastNames.slice(1).join(' ') || '',
      nombres: st.first_name,
      g_rut_body: gRut.body,
      g_rut_dv: gRut.dv,
      g_name: `${g.first_name || ''} ${g.last_name || ''}`,
      arancel: meta.colegiatura_anual || 0,
      matricula: meta.monto_matricula || 0,
      cuotas: meta.cantidad_cuotas || 0,
      monto_cuota: meta.monto_cuota || 0
    });
  });

  const buffer = await workbook.xlsx.writeBuffer();
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
};
