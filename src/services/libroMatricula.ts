import { supabase } from './supabase';
import * as XLSX from 'xlsx';

export interface LibroMatriculaRow {
  numero_correlativo: number;
  year_matricula: number;
  fecha_matricula: string;
  nivel: string;
  curso: string;
  nombres: string;
  apellido_paterno: string;
  apellido_materno: string;
  run_estudiante: string;
  fecha_nac_estudiante: string;
  nacionalidad: string;
  genero_estudiante: string;
  con_quien_vive: string;
  direccion_estudiante: string;
  comuna_estudiante: string;
  repite_curso: string;
  institucion_procedencia: string;
  nombre_apoderado: string;
  apellido_paterno_apoderado: string;
  apellido_materno_apoderado: string;
  relacion_apoderado: string;
  fecha_nac_apoderado: string;
  run_apoderado: string;
  nivel_educacional_apoderado: string;
  direccion_apoderado: string;
  comuna_apoderado: string;
  email_apoderado: string;
  telefono_apoderado: string;
  nombre_apoderado_secundario: string;
  run_apoderado_secundario: string;
  fecha_nac_apoderado_secundario: string;
  telefono_apoderado_secundario: string;
  email_apoderado_secundario: string;
  fecha_retiro: string;
  motivo_retiro: string;
  condicion: string;
}

export async function generateLibroMatriculaReport(
  year?: number,
  estado?: string,
  enrollmentStatus?: string
): Promise<LibroMatriculaRow[]> {
  const { data, error } = await supabase.rpc('generate_libro_matricula_report', {
    p_year: year || null,
    p_estado: estado || null,
    p_enrollment_status: enrollmentStatus || null
  });

  if (error) {
    console.error('Error generando reporte Libro de Matrícula:', error);
    throw error;
  }
  
  return data || [];
}

export function exportToExcel(data: LibroMatriculaRow[], filename: string = 'Libro_Matricula.xlsx') {
  if (!data || data.length === 0) {
    throw new Error('No hay datos para exportar');
  }

  // Separar por nivel educacional
  const basica = data.filter(row => 
    row.nivel?.toLowerCase().includes('básica') || 
    row.nivel?.toLowerCase().includes('basica') ||
    row.nivel?.toLowerCase().includes('enseñanza básica')
  );
  
  const media = data.filter(row => 
    row.nivel?.toLowerCase().includes('media') ||
    row.nivel?.toLowerCase().includes('enseñanza media')
  );

  // Mapear a formato Excel con headers traducidos
  const mapToExcel = (rows: LibroMatriculaRow[]) => rows.map(row => ({
    'Nº': row.numero_correlativo,
    'Año Matrícula': row.year_matricula,
    'Fecha Matrícula': row.fecha_matricula,
    'Nivel': row.nivel,
    'Curso': row.curso,
    'Nombres': row.nombres,
    'Apellido Paterno': row.apellido_paterno,
    'Apellido Materno': row.apellido_materno,
    'Run estudiante': row.run_estudiante,
    'Fecha Nac Estudiante': row.fecha_nac_estudiante,
    'Nacionalidad': row.nacionalidad,
    'Género Estudiante': row.genero_estudiante,
    '¿Con quién vive el estudiante?': row.con_quien_vive,
    'Dirección Estudiante': row.direccion_estudiante,
    'Comuna': row.comuna_estudiante,
    '¿El estudiante repite el curso actual?': row.repite_curso,
    '¿Cuál es la institución de procedencia del estudiante?': row.institucion_procedencia,
    '¿Cuál es el nombre del apoderado?': row.nombre_apoderado,
    '¿Cuál es el apellido paterno del apoderado?': row.apellido_paterno_apoderado,
    '¿Cuál es el apellido materno del apoderado?': row.apellido_materno_apoderado,
    '¿Cuál es su relación con el estudiante?': row.relacion_apoderado,
    'Fecha nacimiento apoderado': row.fecha_nac_apoderado,
    '¿Cuál es el RUT del apoderado?': row.run_apoderado,
    '¿Cuál es el nivel educacional del apoderado?': row.nivel_educacional_apoderado,
    '¿Cuál es la dirección de residencia del apoderado?': row.direccion_apoderado,
    '¿Cuál es la comuna de residencia del apoderado?': row.comuna_apoderado,
    '¿Cuál es el email de contacto del apoderado?': row.email_apoderado,
    '¿Cuál es su teléfono?': row.telefono_apoderado,
    'Apoderado Secundario': row.nombre_apoderado_secundario,
    'Rut apoderado secundario': row.run_apoderado_secundario,
    'Fecha Nacimiento': row.fecha_nac_apoderado_secundario,
    'Añada el teléfono del contacto distinto al apoderado si fuese el caso': row.telefono_apoderado_secundario,
    'mail apoderado secundario': row.email_apoderado_secundario,
    'fecha de retiro del estudiante': row.fecha_retiro,
    'motivo del retiro del estudiante': row.motivo_retiro,
    'CONDICION': row.condicion
  }));

  const excelDataBasica = mapToExcel(basica);
  const excelDataMedia = mapToExcel(media);

  // Crear workbook con 2 hojas
  const wb = XLSX.utils.book_new();
  
  // Hoja 1: Enseñanza Básica
  if (excelDataBasica.length > 0) {
    const wsBasica = XLSX.utils.json_to_sheet(excelDataBasica);
    const maxWidth = 50;
    const wscolsBasica = Object.keys(excelDataBasica[0] || {}).map(key => ({
      wch: Math.min(Math.max(key.length + 2, 10), maxWidth)
    }));
    wsBasica['!cols'] = wscolsBasica;
    XLSX.utils.book_append_sheet(wb, wsBasica, 'Enseñanza Básica');
  }
  
  // Hoja 2: Enseñanza Media
  if (excelDataMedia.length > 0) {
    const wsMedia = XLSX.utils.json_to_sheet(excelDataMedia);
    const maxWidth = 50;
    const wscolsMedia = Object.keys(excelDataMedia[0] || {}).map(key => ({
      wch: Math.min(Math.max(key.length + 2, 10), maxWidth)
    }));
    wsMedia['!cols'] = wscolsMedia;
    XLSX.utils.book_append_sheet(wb, wsMedia, 'Enseñanza Media');
  }
  
  XLSX.writeFile(wb, filename);
}

export async function generateAndExportLibroMatricula(
  year?: number,
  estado: string = 'PRE_MATRICULADO'
): Promise<number> {
  const data = await generateLibroMatriculaReport(year, estado);
  
  if (!data || data.length === 0) {
    throw new Error('No se encontraron datos para el filtro seleccionado');
  }
  
  const filename = `Libro_Matricula_${estado}_${year || new Date().getFullYear()}.xlsx`;
  exportToExcel(data, filename);
  
  return data.length;
}
