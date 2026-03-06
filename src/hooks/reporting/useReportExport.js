import { useState } from 'react';
import { format } from 'date-fns';
import toast from 'react-hot-toast';
import { PDFReport } from '../../components/reporting/PDFReport';
import { generateLibroMatriculaReport, generateFiconReport, generateChequesReport } from '../../services/reporting';

function calculateSummaryData(data) {
  if (!data || data.length === 0) {
    return { totalPaid: 0, totalPending: 0, totalOverdue: 0, paymentCount: 0, delinquencyRate: "0.0" };
  }

  const totalPaid = data.filter(item => item.status === 'paid').reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
  const totalPending = data.filter(item => item.status === 'pending').reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
  const totalOverdue = data.filter(item => item.status === 'overdue').reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
  const overdueFees = data.filter(item => item.status === 'overdue').length;
  const delinquencyRate = data.length > 0 ? ((overdueFees / data.length) * 100).toFixed(1) : "0.0";

  return { totalPaid, totalPending, totalOverdue, paymentCount: data.length, delinquencyRate };
}

function buildReportTitle(filters, guardians, courses) {
  let title = 'Informe de Aranceles';
  if (filters.guardians?.length > 0) {
    const names = filters.guardians.map(id => guardians.find(g => g.id === id)?.name || 'Apoderado').join(', ');
    title += ` - Apoderados: ${names}`;
  }
  if (filters.courses?.length > 0) {
    const names = filters.courses.map(id => courses.find(c => c.id === id)?.nom_curso || 'Curso').join(', ');
    title += ` - Cursos: ${names}`;
  }
  if (filters.status !== 'all') {
    const statusText = filters.status === 'paid' ? 'Pagado' : filters.status === 'pending' ? 'Pendiente' : 'Vencido';
    title += ` - Estado: ${statusText}`;
  }
  return title;
}

function buildReadableFilters(filters, guardians, courses) {
  return {
    'Período': filters.startDate && filters.endDate
      ? `${format(new Date(filters.startDate), 'dd/MM/yyyy')} - ${format(new Date(filters.endDate), 'dd/MM/yyyy')}`
      : 'Todos',
    'Estado': filters.status === 'all' ? 'Todos'
      : filters.status === 'paid' ? 'Pagado'
      : filters.status === 'pending' ? 'Pendiente'
      : 'Vencido',
    'Apoderados': filters.guardians.length > 0
      ? filters.guardians.map(id => guardians.find(g => g.id === id)?.name || id).join(', ')
      : 'Todos',
    'Cursos': filters.courses.length > 0
      ? filters.courses.map(id => courses.find(c => c.id === id)?.nom_curso || id).join(', ')
      : 'Todos',
    'Mes': filters.month !== 'all'
      ? ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
         'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'][parseInt(filters.month) - 1] || filters.month
      : 'Todos',
    'Año': filters.year !== 'all' ? filters.year : 'Todos'
  };
}

function formatDataForExport(validData) {
  return validData.map(item => ({
    'Estudiante': item.student?.whole_name || `${item.student?.first_name || ''} ${item.student?.apellido_paterno || ''}`,
    'Curso': item.student?.curso?.nom_curso || 'Sin asignar',
    'RUN': item.student?.run || 'N/A',
    'Cuota N°': item.numero_cuota || 'N/A',
    'Monto': parseInt(item.amount || 0).toLocaleString('es-CL'),
    'Estado': item.status === 'paid' ? 'Pagado' : item.status === 'pending' ? 'Pendiente' : 'Vencido',
    'Fecha Vencimiento': item.due_date ? format(new Date(item.due_date), 'dd/MM/yyyy') : 'N/A',
    'Fecha Pago': item.payment_date ? format(new Date(item.payment_date), 'dd/MM/yyyy') : 'N/A',
    'Método Pago': item.payment_method || 'N/A'
  }));
}

function triggerDownload(blob, filename) {
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  window.URL.revokeObjectURL(url);
}

export function useReportExport({ data, filters, guardians, courses, getFilteredData, chartRefs }) {
  const [exporting, setExporting] = useState(false);

  const handleExport = async (type) => {
    try {
      setExporting(true);

      if (filters.students?.length > 0 && data.length === 0) {
        toast.error('No se encontraron aranceles para el estudiante seleccionado');
        setExporting(false);
        return;
      }

      const filteredExportData = getFilteredData(data);

      if (import.meta.env.DEV) console.log('Export preparation:', {
        totalRecords: data.length,
        filteredRecords: filteredExportData.length,
      });

      const validData = filteredExportData.filter(item =>
        item && item.student && (item.student.first_name || item.student.whole_name)
      );

      if (validData.length === 0) {
        if (import.meta.env.DEV) console.warn('No valid data for export after filtering');
        toast.error('No hay datos válidos para exportar');
        setExporting(false);
        return;
      }

      const reportTitle = buildReportTitle(filters, guardians, courses);
      const readableFilters = buildReadableFilters(filters, guardians, courses);
      const formattedData = formatDataForExport(validData);
      const summaryData = calculateSummaryData(validData);

      if (type === 'excel') {
        try {
          toast.loading('Generando Excel, por favor espere...', { id: 'export-excel' });

          const ExcelJS = await import('exceljs');
          const wb = new ExcelJS.Workbook();

          // Info sheet
          const filterWs = wb.addWorksheet('Información');
          const filterInfo = [
            [reportTitle],
            ['Generado el:', format(new Date(), 'dd/MM/yyyy HH:mm')],
            [''],
            ['Filtros aplicados:'],
            ['Período:', readableFilters['Período']],
            ['Estado:', readableFilters['Estado']],
            ['Apoderados:', readableFilters['Apoderados']],
            ['Cursos:', readableFilters['Cursos']],
            ['Mes:', readableFilters['Mes']],
            ['Año:', readableFilters['Año']],
            [''],
            ['Resumen:'],
            ['Total Pagado:', `$${summaryData.totalPaid.toLocaleString('es-CL')}`],
            ['Total Pendiente:', `$${summaryData.totalPending.toLocaleString('es-CL')}`],
            ['Total Vencido:', `$${summaryData.totalOverdue.toLocaleString('es-CL')}`],
            ['Cantidad de Pagos:', summaryData.paymentCount.toString()],
            ['Tasa de Morosidad:', `${summaryData.delinquencyRate}%`]
          ];
          filterInfo.forEach(row => filterWs.addRow(row));
          filterWs.getColumn(1).width = 25;
          filterWs.getColumn(2).width = 50;

          // Data sheet
          const formattedForExcel = formattedData.map(item => ({
            'Estudiante': item['Estudiante'] || 'N/A',
            'Curso': item['Curso'] || 'N/A',
            'RUN': item['RUN'] || 'N/A',
            'Cuota N°': item['Cuota N°'] || 'N/A',
            'Monto': item['Monto'] || '0',
            'Estado': item['Estado'] || 'N/A',
            'Fecha Vencimiento': item['Fecha Vencimiento'] || 'N/A',
            'Fecha Pago': item['Fecha Pago'] || 'N/A',
            'Método Pago': item['Método Pago'] || 'N/A'
          }));

          const ws = wb.addWorksheet('Aranceles');
          const headers = Object.keys(formattedForExcel[0] || {});
          ws.addRow(headers);
          formattedForExcel.forEach(row => ws.addRow(Object.values(row)));
          [30, 15, 12, 10, 12, 10, 16, 16, 15].forEach((width, i) => {
            ws.getColumn(i + 1).width = width;
          });

          const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
          const buffer = await wb.xlsx.writeBuffer();
          triggerDownload(
            new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }),
            `informe_aranceles_${timestamp}.xlsx`
          );
          toast.success('Datos exportados exitosamente a Excel', { id: 'export-excel' });
        } catch (excelError) {
          console.error('Error exporting to Excel:', excelError);
          toast.error('Error al exportar a Excel', { id: 'export-excel' });
        }
      } else if (type === 'pdf') {
        try {
          toast.loading('Generando PDF, por favor espere...', { id: 'export-pdf' });
          await new Promise(resolve => setTimeout(resolve, 500));

          const report = new PDFReport(reportTitle, readableFilters);
          report.addHeader();
          report.addSummary(summaryData);
          report.addPaymentsTable(validData);

          for (const { ref, title } of [
            { ref: chartRefs.paymentsOverview, title: 'Resumen de Pagos' },
            { ref: chartRefs.paymentStatus, title: 'Estado de Pagos' },
            { ref: chartRefs.paymentMethods, title: 'Métodos de Pago' },
          ]) {
            if (ref.current) {
              try { await report.addChart(ref.current, title); } catch (e) {
                console.error(`Error adding chart "${title}":`, e);
              }
            }
          }

          report.addFooter();
          const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
          report.save(`informe_aranceles_${timestamp}.pdf`);
          toast.success('PDF generado exitosamente', { id: 'export-pdf' });
        } catch (pdfError) {
          console.error('Error generating PDF:', pdfError);
          toast.error('Error al generar el PDF', { id: 'export-pdf' });
        }
      }
    } catch (error) {
      console.error('Error exporting data:', error);
      toast.error('Error al exportar los datos');
    } finally {
      setExporting(false);
    }
  };

  const handleExportLibroMatricula = async () => {
    try {
      setExporting(true);
      toast.loading('Generando Libro de Matrícula...', { id: 'export-libro' });
      const blob = await generateLibroMatriculaReport();
      triggerDownload(blob, `Libro_Matricula_${format(new Date(), 'yyyyMMdd_HHmm')}.xlsx`);
      toast.success('Libro de Matrícula descargado', { id: 'export-libro' });
    } catch (error) {
      console.error('Error exporting Libro Matricula:', error);
      toast.error('Error al generar reporte', { id: 'export-libro' });
    } finally {
      setExporting(false);
    }
  };

  const handleExportFicon = async () => {
    try {
      setExporting(true);
      toast.loading('Generando Reporte FICON...', { id: 'export-ficon' });
      const blob = await generateFiconReport();
      triggerDownload(blob, `Reporte_FICON_${format(new Date(), 'yyyyMMdd_HHmm')}.xlsx`);
      toast.success('Reporte FICON descargado', { id: 'export-ficon' });
    } catch (error) {
      console.error('Error exporting FICON:', error);
      toast.error('Error al generar reporte FICON', { id: 'export-ficon' });
    } finally {
      setExporting(false);
    }
  };

  const handleExportCheques = async () => {
    try {
      setExporting(true);
      toast.loading('Generando Reporte Cheques...', { id: 'export-cheques' });
      const blob = await generateChequesReport();
      triggerDownload(blob, `Reporte_Cheques_${format(new Date(), 'yyyyMMdd_HHmm')}.xlsx`);
      toast.success('Reporte de Cheques descargado', { id: 'export-cheques' });
    } catch (error) {
      console.error('Error exporting Cheques:', error);
      toast.error('Error al generar reporte de Cheques', { id: 'export-cheques' });
    } finally {
      setExporting(false);
    }
  };

  return {
    exporting,
    handleExport,
    handleExportLibroMatricula,
    handleExportFicon,
    handleExportCheques,
  };
}
