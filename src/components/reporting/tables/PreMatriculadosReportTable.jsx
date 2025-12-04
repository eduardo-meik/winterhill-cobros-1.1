import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../../ui/Card';
import { Button } from '../../ui/Button';
import { supabase } from '../../../services/supabase';
import * as ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

export function PreMatriculadosReportTable() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      // Fetch enrollments with status PRE_MATRICULADO
      const { data: enrollments, error } = await supabase
        .from('enrollments')
        .select(`
          id,
          created_at,
          updated_at,
          year,
          status,
          guardian:guardians (
            id,
            first_name,
            last_name,
            run,
            email,
            phone
          ),
          enrollment_students (
            student:students (
              id,
              whole_name,
              run,
              curso:curso (
                nom_curso
              )
            )
          )
        `)
        .eq('status', 'PRE_MATRICULADO')
        .order('updated_at', { ascending: false });

      if (error) throw error;

      // Flatten the data structure
      const flattenedData = [];
      
      enrollments.forEach(enrollment => {
        const guardian = enrollment.guardian;
        const students = enrollment.enrollment_students || [];
        
        if (students.length === 0) {
          // Case where enrollment exists but no students linked (should be rare for PRE_MATRICULADO)
          flattenedData.push({
            enrollmentId: enrollment.id,
            date: enrollment.updated_at || enrollment.created_at,
            year: enrollment.year,
            guardianName: guardian ? `${guardian.first_name || ''} ${guardian.last_name || ''}`.trim() : 'Sin Apoderado',
            guardianRun: guardian?.run || '',
            guardianEmail: guardian?.email || '',
            guardianPhone: guardian?.phone || '',
            studentName: 'Sin Estudiante',
            studentRun: '',
            course: ''
          });
        } else {
          students.forEach(item => {
            const student = item.student;
            flattenedData.push({
              enrollmentId: enrollment.id,
              date: enrollment.updated_at || enrollment.created_at,
              year: enrollment.year,
              guardianName: guardian ? `${guardian.first_name || ''} ${guardian.last_name || ''}`.trim() : 'Sin Apoderado',
              guardianRun: guardian?.run || '',
              guardianEmail: guardian?.email || '',
              guardianPhone: guardian?.phone || '',
              studentName: student?.whole_name || 'Desconocido',
              studentRun: student?.run || '',
              course: student?.curso?.nom_curso || ''
            });
          });
        }
      });

      setData(flattenedData);
    } catch (error) {
      console.error('Error fetching pre-matriculados:', error);
      toast.error('Error al cargar reporte de pre-matriculados');
    } finally {
      setLoading(false);
    }
  };

  const handleExportExcel = async () => {
    if (data.length === 0) return;
    
    setExporting(true);
    try {
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet('Pre-Matriculados');

      worksheet.columns = [
        { header: 'Fecha', key: 'date', width: 15 },
        { header: 'Año', key: 'year', width: 10 },
        { header: 'Apoderado', key: 'guardianName', width: 30 },
        { header: 'RUN Apoderado', key: 'guardianRun', width: 15 },
        { header: 'Email', key: 'guardianEmail', width: 25 },
        { header: 'Teléfono', key: 'guardianPhone', width: 15 },
        { header: 'Estudiante', key: 'studentName', width: 30 },
        { header: 'RUN Estudiante', key: 'studentRun', width: 15 },
        { header: 'Curso', key: 'course', width: 15 },
      ];

      data.forEach(item => {
        worksheet.addRow({
          date: format(new Date(item.date), 'dd/MM/yyyy'),
          year: item.year,
          guardianName: item.guardianName,
          guardianRun: item.guardianRun,
          guardianEmail: item.guardianEmail,
          guardianPhone: item.guardianPhone,
          studentName: item.studentName,
          studentRun: item.studentRun,
          course: item.course
        });
      });

      const buffer = await workbook.xlsx.writeBuffer();
      const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
      saveAs(blob, `Reporte_PreMatriculados_${format(new Date(), 'yyyyMMdd')}.xlsx`);
      
      toast.success('Reporte exportado exitosamente');
    } catch (error) {
      console.error('Error exporting excel:', error);
      toast.error('Error al exportar Excel');
    } finally {
      setExporting(false);
    }
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <h2 className="text-gray-900 dark:text-white text-lg font-semibold">
          Alumnos Pre-Matriculados
          <span className="ml-2 text-sm font-normal text-gray-500">
            ({data.length} registros)
          </span>
        </h2>
        <Button 
          variant="secondary" 
          onClick={handleExportExcel}
          disabled={loading || exporting || data.length === 0}
        >
          {exporting ? 'Exportando...' : 'Exportar Excel'}
        </Button>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="py-8 text-center text-gray-500">Cargando datos...</div>
        ) : data.length === 0 ? (
          <div className="py-8 text-center text-gray-500">No hay alumnos en estado Pre-Matrícula.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left">
              <thead className="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                <tr>
                  <th className="px-4 py-3">Fecha</th>
                  <th className="px-4 py-3">Apoderado</th>
                  <th className="px-4 py-3">Estudiante</th>
                  <th className="px-4 py-3">Curso</th>
                  <th className="px-4 py-3">Contacto</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row, index) => (
                  <tr key={`${row.enrollmentId}-${index}`} className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                    <td className="px-4 py-3">
                      {format(new Date(row.date), 'dd/MM/yyyy')}
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900 dark:text-white">{row.guardianName}</div>
                      <div className="text-xs text-gray-500">{row.guardianRun}</div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900 dark:text-white">{row.studentName}</div>
                      <div className="text-xs text-gray-500">{row.studentRun}</div>
                    </td>
                    <td className="px-4 py-3">
                      {row.course}
                    </td>
                    <td className="px-4 py-3">
                      <div className="text-xs">{row.guardianEmail}</div>
                      <div className="text-xs text-gray-500">{row.guardianPhone}</div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
