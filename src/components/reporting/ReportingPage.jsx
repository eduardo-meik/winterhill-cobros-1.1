import React, { useState, useRef, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { format, parseISO } from 'date-fns';
import { utils, writeFile } from 'xlsx';
import toast from 'react-hot-toast';
import { supabase } from '../../services/supabase';
import { PDFReport } from './PDFReport';
import { TabsContainer, TabButton } from "../ui/Tabs";
import { GuardianReportTable } from "./tables/GuardianReportTable";
import { StudentReportTable } from "./tables/StudentReportTable";
import { ReportFilters } from './ReportFilters';
import { PaymentsOverview } from './graphs/PaymentsOverview';
import { PaymentStatusChart } from './graphs/PaymentStatusChart';
import { PaymentMethodsChart } from './graphs/PaymentMethodsChart';
import { PaymentsTable } from './tables/PaymentsTable'; // Import from the correct location

export function ReportingPage() {
  const [filters, setFilters] = useState({
    status: 'all',
    guardians: [],
    courses: [],
    students: [],
    startDate: '',
    endDate: '',
    month: 'all',
    year: 'all'
  });
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const [guardians, setGuardians] = useState([]);
  const [courses, setCourses] = useState([]);
  const [students, setStudents] = useState([]);
  const [exporting, setExporting] = useState(false);
  const [activeTab, setActiveTab] = useState('payments');

  // Refs for charts to capture for PDF export
  const paymentsOverviewRef = useRef(null);
  const paymentStatusRef = useRef(null);
  const paymentMethodsRef = useRef(null);

  useEffect(() => {
    fetchReferenceData();
    // Initial data fetch with default filters
    fetchData(filters);
  }, []);

  const fetchData = async (filters) => {
    try {
      setLoading(true);
      
      console.log("Fetching data with filters:", JSON.stringify(filters, null, 2));
      
      // Start building the query
      let query = supabase.from('fee').select(`
        *,
        student:students (
          id,
          first_name,
          apellido_paterno,
          apellido_materno,
          whole_name,
          run,
          curso,
          cursos:curso (
            id,
            nom_curso,
            nivel
          )
        )
      `);
      
      // Apply direct filters
      if (filters.status && filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }
      
      // Date filters
      if (filters.startDate) {
        query = query.gte('due_date', filters.startDate);
      }
      
      if (filters.endDate) {
        query = query.lte('due_date', filters.endDate);
      }
      
      // Direct student filter
      if (filters.students && filters.students.length > 0) {
        query = query.in('student_id', filters.students);
      }
      
      // Execute the base query with all possible database filters
      const { data: feesData, error: feesError } = await query;
      
      if (feesError) throw feesError;
      
      console.log(`Initial query returned ${feesData?.length} records`);
      
      // Apply post-query filters
      let filteredData = [...feesData];
      
      // Apply month filter if specified
      if (filters.month && filters.month !== 'all') {
        filteredData = filteredData.filter(fee => {
          if (!fee.due_date) return false;
          const dueDate = new Date(fee.due_date);
          const month = (dueDate.getMonth() + 1).toString(); // JavaScript months are 0-indexed
          return month === filters.month;
        });
      }
      
      // Apply year filter if specified
      if (filters.year && filters.year !== 'all') {
        filteredData = filteredData.filter(fee => {
          if (!fee.due_date) return false;
          const dueDate = new Date(fee.due_date);
          const year = dueDate.getFullYear().toString();
          return year === filters.year;
        });
      }

      // Apply guardian filter - we need to filter by students related to selected guardians
      if (filters.guardians && filters.guardians.length > 0) {
        try {
          console.log("Filtering by guardians:", filters.guardians);
          
          // First approach: Get all students belonging to selected guardians from the junction table
          // Use multiple approaches for reliability and fallback options
          
          // Method 1: Direct query to student_guardian table
          let { data: guardianStudents, error: guardianStudentsError } = await supabase
            .from('student_guardian')
            .select('student_id')
            .in('guardian_id', filters.guardians);
          
          // Method 2: If method 1 fails, try using a direct manual JOIN query
          if (guardianStudentsError || !guardianStudents || guardianStudents.length === 0) {
            console.warn("Primary student_guardian query failed or returned no results, trying alternative method");
            
            // This query manually joins the tables to get student IDs for the selected guardians
            const { data: joinQueryResult, error: joinQueryError } = await supabase
              .from('student_guardian')
              .select(`
                student_id,
                students!inner(id)
              `)
              .in('guardian_id', filters.guardians);
              
            if (!joinQueryError && joinQueryResult && joinQueryResult.length > 0) {
              guardianStudents = joinQueryResult;
              guardianStudentsError = null;
              console.log("Alternative join query successful:", joinQueryResult.length);
            } else {
              console.error("Alternative join query also failed:", joinQueryError);
            }
          }
          
          // Method 3: If we have an RPC function available, try that as well
          if (guardianStudentsError || !guardianStudents || guardianStudents.length === 0) {
            console.warn("Trying RPC method for guardian-student relationship");
            
            try {
              const { data: rpcResult, error: rpcError } = await supabase.rpc(
                'get_students_by_guardian_ids', 
                { guardian_ids: filters.guardians }
              );
              
              if (!rpcError && rpcResult && rpcResult.length > 0) {
                guardianStudents = rpcResult;
                guardianStudentsError = null;
                console.log("RPC method successful:", rpcResult.length);
              } else {
                console.error("RPC method failed:", rpcError);
              }
            } catch (rpcTryError) {
              console.error("RPC may not exist:", rpcTryError);
            }
          }
          
          if (guardianStudents && guardianStudents.length > 0) {
            // Extract the student IDs from the result
            const studentIds = guardianStudents.map(gs => gs.student_id);
            console.log(`Found ${studentIds.length} students related to selected guardians:`, studentIds);
            
            if (studentIds.length === 0) {
              console.warn("No student IDs found despite having guardian_students records");
              filteredData = [];
              return;
            }
            
            // IMPORTANT: We'll get the fee records directly from the database with these student IDs
            // This ensures we're getting fresh data directly matched on the student_id field
            const { data: studentFees, error: feesError } = await supabase
              .from('fee')
              .select(`
                *,
                student:students (
                  id,
                  first_name,
                  apellido_paterno,
                  apellido_materno,
                  whole_name,
                  run,
                  curso,
                  cursos:curso (
                    id,
                    nom_curso,
                    nivel
                  )
                )
              `)
              .in('student_id', studentIds);
              
            if (feesError) {
              console.error("Error fetching fees for guardian's students:", feesError);
              throw feesError;
            }
            
            if (!studentFees || studentFees.length === 0) {
              console.log("No fee records found for the selected guardians' students");
              filteredData = [];
            } else {
              console.log(`Found ${studentFees.length} fee records for students of selected guardians`);
              filteredData = studentFees;
              
              // Re-apply status filter if needed
              if (filters.status && filters.status !== 'all') {
                filteredData = filteredData.filter(fee => fee.status === filters.status);
              }
              
              // Re-apply date filters if needed
              if (filters.month && filters.month !== 'all') {
                filteredData = filteredData.filter(fee => {
                  if (!fee.due_date) return false;
                  const dueDate = new Date(fee.due_date);
                  const month = (dueDate.getMonth() + 1).toString();
                  return month === filters.month;
                });
              }
              
              if (filters.year && filters.year !== 'all') {
                filteredData = filteredData.filter(fee => {
                  if (!fee.due_date) return false;
                  const dueDate = new Date(fee.due_date);
                  const year = dueDate.getFullYear().toString();
                  return year === filters.year;
                });
              }
            }
          } else {
            // No students found for these guardians - empty result
            console.log('No students found for selected guardians');
            filteredData = [];
          }
        } catch (error) {
          console.error("Error in guardian filtering:", error);
          toast.error('Error al filtrar por apoderados');
          // Keep the current data instead of clearing it completely
        }
      }
      
      // Apply course filter - need to concatenate with previous filters
      if (filters.courses && filters.courses.length > 0) {
        // Need to check if the student's curso matches any of the selected courses
        filteredData = filteredData.filter(fee => {
          if (!fee.student || !fee.student.curso) return false;
          return filters.courses.includes(fee.student.curso);
        });
        
        console.log(`After course filtering: ${filteredData.length} records`);
      }
      
      // Search filter has been removed

      console.log(`After filtering: ${filteredData.length} records`);
      setData(filteredData);
      
    } catch (error) {
      console.error('Error fetching fees:', error);
      
      // Provide more specific error messages based on the error type
      if (error.message && error.message.includes('network')) {
        toast.error('Error de conexión. Verifique su conexión a internet.');
      } else if (error.code === 'PGRST116') {
        toast.error('Error en los filtros aplicados. Por favor revise e intente nuevamente.');
      } else {
        toast.error('Error al cargar los aranceles');
      }
      
      // Return empty data on error
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchReferenceData = async () => {
    try {
      console.log("Fetching reference data...");
      
      // Fetch guardians separately for better error handling
      const guardiansResponse = await supabase
        .from('guardians')
        .select('id, first_name, last_name, run')
        .order('last_name', { ascending: true });
      
      if (guardiansResponse.error) {
        console.error("Error loading guardians:", guardiansResponse.error);
        throw guardiansResponse.error;
      }
      
      // Log the number of guardians found
      console.log(`Found ${guardiansResponse.data?.length || 0} guardians`);
      
      // Fetch courses and students in parallel
      const [coursesResponse, studentsResponse] = await Promise.all([
        supabase.from('cursos').select('id, nom_curso, nivel'),
        supabase.from('students').select('id, first_name, apellido_paterno, whole_name, run')
      ]);

      if (coursesResponse.error) throw coursesResponse.error;
      if (studentsResponse.error) throw studentsResponse.error;

      // Process guardian data
      const processedGuardians = guardiansResponse.data.map(g => ({
        id: g.id,
        name: `${g.last_name || ''}, ${g.first_name || ''}`.trim(),
        run: g.run
      }));
      
      setGuardians(processedGuardians);
      console.log("Processed guardians:", processedGuardians.length);
      
      // Courses
      setCourses(coursesResponse.data);
      console.log("Courses:", coursesResponse.data.length);
      
      // Students
      const processedStudents = studentsResponse.data.map(s => ({
        id: s.id,
        name: s.whole_name || `${s.first_name || ''} ${s.apellido_paterno || ''}`.trim(),
        run: s.run
      }));
      
      setStudents(processedStudents);
      console.log("Processed students:", processedStudents.length);
      
    } catch (error) {
      console.error('Error fetching reference data:', error);
      toast.error('Error al cargar los datos de referencia');
    }
  };

  const calculateSummaryData = (data) => {
    if (!data || data.length === 0) {
      return {
        totalPaid: 0,
        totalPending: 0,
        totalOverdue: 0,
        paymentCount: 0,
        delinquencyRate: "0.0"
      };
    }
    
    const totalPaid = data
      .filter(item => item.status === 'paid')
      .reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
      
    const totalPending = data
      .filter(item => item.status === 'pending')
      .reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
      
    const totalOverdue = data
      .filter(item => item.status === 'overdue')
      .reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
      
    const overdueFees = data.filter(item => item.status === 'overdue').length;
    const delinquencyRate = data.length > 0 
      ? ((overdueFees / data.length) * 100).toFixed(1)
      : "0.0";
      
    return {
      totalPaid,
      totalPending,
      totalOverdue,
      paymentCount: data.length,
      delinquencyRate
    };
  };

  const handleExport = async (type) => {
    try {
      setExporting(true);
      
      // Filter out data with missing required fields
      const validData = data.filter(item => 
        item && item.student && 
        (item.student.first_name || item.student.whole_name)
      );
      
      if (validData.length === 0) {
        toast.error('No hay datos válidos para exportar');
        setExporting(false);
        return;
      }
      
      // Create descriptive titles based on applied filters
      let reportTitle = 'Informe de Aranceles';
      if (filters.guardians && filters.guardians.length > 0) {
        const guardianNames = filters.guardians
          .map(id => guardians.find(g => g.id === id)?.name || 'Apoderado')
          .join(', ');
        reportTitle += ` - Apoderados: ${guardianNames}`;
      }
      
      if (filters.courses && filters.courses.length > 0) {
        const courseNames = filters.courses
          .map(id => courses.find(c => c.id === id)?.nom_curso || 'Curso')
          .join(', ');
        reportTitle += ` - Cursos: ${courseNames}`;
      }
      
      if (filters.status !== 'all') {
        const statusText = filters.status === 'paid' ? 'Pagado' : 
                           filters.status === 'pending' ? 'Pendiente' : 'Vencido';
        reportTitle += ` - Estado: ${statusText}`;
      }
      
      // Generate formatted data with curso properly referenced
      const formattedData = validData.map(item => ({
        'Estudiante': item.student?.whole_name || `${item.student?.first_name || ''} ${item.student?.apellido_paterno || ''}`,
        'Curso': item.student?.cursos?.nom_curso || 'Sin asignar',
        'RUN': item.student?.run || 'N/A',
        'Cuota N°': item.numero_cuota || 'N/A',
        'Monto': parseInt(item.amount || 0).toLocaleString('es-CL'),
        'Estado': item.status === 'paid' ? 'Pagado' : item.status === 'pending' ? 'Pendiente' : 'Vencido',
        'Fecha Vencimiento': item.due_date ? format(new Date(item.due_date), 'dd/MM/yyyy') : 'N/A',
        'Fecha Pago': item.payment_date ? format(new Date(item.payment_date), 'dd/MM/yyyy') : 'N/A',
        'Método Pago': item.payment_method || 'N/A'
      }));

      // Generate human-readable filter descriptions
      const readableFilters = {
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
      
      const summaryData = calculateSummaryData(validData);
      
      if (type === 'excel') {
        try {
          // Show loading toast
          toast.loading('Generando Excel, por favor espere...');
          
          // Excel export with summary information and formatted filters
          const wb = utils.book_new();
          
          // Add info sheet with filter information
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
          
          // Create and style the filter info sheet
          const filterWs = utils.aoa_to_sheet(filterInfo);
          
          // Add styles to the header cells
          filterWs['!merges'] = [{
            s: { r: 0, c: 0 },
            e: { r: 0, c: 1 }
          }];
          
          filterWs['!cols'] = [{ wch: 25 }, { wch: 50 }];
          
          utils.book_append_sheet(wb, filterWs, 'Información');
          
          // Add data sheet with all cuotas - ensure data formatting is consistent
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
          
          // Create and add the data sheet
          const ws = utils.json_to_sheet(formattedForExcel);
          utils.book_append_sheet(wb, ws, 'Aranceles');
          
          // Set column widths
          ws['!cols'] = [
            { wch: 30 }, // Estudiante
            { wch: 15 }, // Curso
            { wch: 12 }, // RUN
            { wch: 10 }, // Cuota N°
            { wch: 12 }, // Monto
            { wch: 10 }, // Estado
            { wch: 16 }, // Fecha Vencimiento
            { wch: 16 }, // Fecha Pago
            { wch: 15 }  // Método Pago
          ];
          
          const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
          writeFile(wb, `informe_aranceles_${timestamp}.xlsx`);
          
          // Dismiss loading and show success
          toast.dismiss();
          toast.success('Datos exportados exitosamente a Excel');
        } catch (excelError) {
          toast.dismiss();
          console.error('Error exporting to Excel:', excelError);
          toast.error('Error al exportar a Excel');
        }
      } else if (type === 'pdf') {
        // PDF export with updated title and data
        try {
          toast.loading('Generando PDF, por favor espere...');
          
          // Ensure charts are rendered before capturing
          await new Promise(resolve => setTimeout(resolve, 500));
          
          const report = new PDFReport(reportTitle, readableFilters);
          report.addHeader();
          report.addSummary(summaryData);
          report.addPaymentsTable(validData);
          
          // Add charts if available - with proper error handling for each chart
          if (paymentsOverviewRef.current) {
            try {
              await report.addChart(paymentsOverviewRef.current, 'Resumen de Pagos');
            } catch (chartError) {
              console.error('Error adding payments overview chart:', chartError);
            }
          }
          
          if (paymentStatusRef.current) {
            try {
              await report.addChart(paymentStatusRef.current, 'Estado de Pagos');
            } catch (chartError) {
              console.error('Error adding payment status chart:', chartError);
            }
          }
          
          if (paymentMethodsRef.current) {
            try {
              await report.addChart(paymentMethodsRef.current, 'Métodos de Pago');
            } catch (chartError) {
              console.error('Error adding payment methods chart:', chartError);
            }
          }
          
          report.addFooter();
          
          const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
          report.save(`informe_aranceles_${timestamp}.pdf`);
          toast.dismiss();
          toast.success('PDF generado exitosamente');
        } catch (pdfError) {
          toast.dismiss();
          console.error('Error generating PDF:', pdfError);
          toast.error('Error al generar el PDF');
        }
      }
    } catch (error) {
      console.error('Error exporting data:', error);
      toast.error('Error al exportar los datos');
    } finally {
      setExporting(false);
    }
  };

  const handleApplyFilters = async (newFilters) => {
    // Log the current and new filters for debugging
    console.log("Current filters:", filters);
    console.log("New filters to apply:", newFilters);
    
    // Special handling for guardian filters - make sure we have a deep copy
    const safeNewFilters = {
      ...newFilters,
      guardians: Array.isArray(newFilters.guardians) ? [...newFilters.guardians] : [],
      courses: Array.isArray(newFilters.courses) ? [...newFilters.courses] : [],
      students: Array.isArray(newFilters.students) ? [...newFilters.students] : []
    };
    
    // Update the filters state
    setFilters(safeNewFilters);
    
    // Check if any filters have changed
    const hasChanges = Object.keys(safeNewFilters).some(key => {
      if (Array.isArray(safeNewFilters[key]) && Array.isArray(filters[key])) {
        // Special handling for array comparisons (guardians, courses, students)
        if (safeNewFilters[key].length !== filters[key].length) return true;
        
        // For arrays, we need to check each element
        const newSet = new Set(safeNewFilters[key]);
        const currentSet = new Set(filters[key]);
        
        // Check if any element exists in one set but not the other
        for (const item of newSet) {
          if (!currentSet.has(item)) return true;
        }
        
        for (const item of currentSet) {
          if (!newSet.has(item)) return true;
        }
        
        return false;
      }
      
      // Simple comparison for primitive values
      return safeNewFilters[key] !== filters[key];
    });
    
    console.log("Has filter changes:", hasChanges);
    
    // Always fetch data, but with different toast messages
    if (hasChanges) {
      toast.promise(
        fetchData(safeNewFilters),
        {
          loading: 'Aplicando filtros...',
          success: `Filtros aplicados exitosamente`,
          error: 'Error al aplicar filtros'
        }
      );
    } else {
      console.log("No filter changes detected, fetching with current filters");
      await fetchData(safeNewFilters);
    }
  };

  const handleResetFilters = async () => {
    // Create a fresh default filters object
    const defaultFilters = {
      status: 'all',
      guardians: [],
      courses: [],
      students: [],
      startDate: '',
      endDate: '',
      month: 'all',
      year: 'all'
    };
    
    console.log("Resetting filters to defaults:", defaultFilters);
    
    // First update the filters state to ensure components are properly reset
    setFilters(defaultFilters);
    setLoading(true);
    
    try {
      // Do a complete fresh data fetch with no filters
      const { data: feesData, error: feesError } = await supabase
        .from('fee')
        .select(`
          *,
          student:students (
            id,
            first_name,
            apellido_paterno,
            apellido_materno,
            whole_name,
            run,
            curso,
            cursos:curso (
              id,
              nom_curso,
              nivel
            )
          )
        `)
        .limit(500);
        
      if (feesError) {
        throw feesError;
      }
      
      // Set the fresh data
      setData(feesData || []);
      console.log(`Reset successful. Loaded ${feesData?.length || 0} fee records with no filters`);
      toast.success('Filtros restablecidos exitosamente');
    } catch (error) {
      console.error('Error resetting filters:', error);
      toast.error('Error al restablecer los filtros');
      // Still set empty data since reset is expected to clear the view
      setData([]);
    } finally {
      setLoading(false);
      
      // Double check that filters were actually reset
      console.log("Final filters state after reset:", filters);
    }
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Informes</h1>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Button
                onClick={() => handleExport('pdf')}
                disabled={exporting || data.length === 0 || loading}
                variant="secondary"
                className="flex items-center gap-2"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                  <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48ZM32,64H224V96H32Zm0,128V112H224v80Z"/>
                </svg>
                {exporting ? 'Generando...' : 'Exportar PDF'}
              </Button>
              <Button
                variant="secondary"
                onClick={() => handleExport('excel')}
                disabled={exporting || data.length === 0 || loading}
              >
                Exportar Excel
              </Button>
            </div>
          </div>
        </div>

        <div className="px-4 pb-4">
          <ReportFilters
            filters={filters}
            onFiltersChange={setFilters}
            guardians={guardians}
            courses={courses}
            students={students}
            onApplyFilters={handleApplyFilters}
            onResetFilters={handleResetFilters}
            loading={loading}
          />
        </div>

        <div className="px-4">
          <TabsContainer>
            <TabButton
              isActive={activeTab === 'payments'}
              onClick={() => setActiveTab('payments')}
            >
              Aranceles
            </TabButton>
            <TabButton
              isActive={activeTab === 'students'}
              onClick={() => setActiveTab('students')}
            >
              Estudiantes
            </TabButton>
            <TabButton
              isActive={activeTab === 'guardians'}
              onClick={() => setActiveTab('guardians')}
            >
              Apoderados
            </TabButton>
          </TabsContainer>
        </div>

        {activeTab === 'payments' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 p-4">
            {/* Revenue Overview */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Resumen de Pagos</h2>
              </CardHeader>
              <CardContent>
                <PaymentsOverview ref={paymentsOverviewRef} data={data} loading={loading} />
              </CardContent>
            </Card>

            {/* Payment Status Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Estado de Pagos</h2>
              </CardHeader>
              <CardContent>
                <PaymentStatusChart ref={paymentStatusRef} data={data} loading={loading} />
              </CardContent>
            </Card>

            {/* Payment Methods Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Métodos de Pago</h2>
              </CardHeader>
              <CardContent>
                <PaymentMethodsChart 
                  ref={paymentMethodsRef} 
                  data={data.filter(payment => 
                    // Only show data that matches our filters
                    (!filters.guardians.length || 
                      payment.student_guardian?.some(sg => filters.guardians.includes(sg.guardian_id))) &&
                    (!filters.students.length || 
                      filters.students.includes(payment.student?.id)) &&
                    (!filters.courses.length ||
                      filters.courses.includes(payment.student?.curso))
                  )} 
                  loading={loading} 
                />
              </CardContent>
            </Card>

            {/* Payments Table */}
            <Card className="lg:col-span-2">
              <CardHeader className="flex flex-wrap justify-between items-center">
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Detalle de Pagos</h2>
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  {data.length} {data.length === 1 ? 'registro' : 'registros'} encontrados
                </div>
              </CardHeader>
              <CardContent>
                <PaymentsTable 
                  data={data.filter(payment => 
                    // Filter payments based on all active filters
                    (filters.status === 'all' || payment.status === filters.status) &&
                    (!filters.guardians.length || 
                      payment.student_guardian?.some(sg => filters.guardians.includes(sg.guardian_id))) &&
                    (!filters.students.length || 
                      filters.students.includes(payment.student?.id)) &&
                    (!filters.courses.length ||
                      filters.courses.includes(payment.student?.curso))
                  )} 
                  loading={loading} 
                />
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === 'students' && (
          <div className="p-4">
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Estudiantes</h2>
              </CardHeader>
              <CardContent>
                <StudentReportTable 
                  data={
                    // If specific students are selected, prioritize them
                    filters.students.length > 0
                      ? students
                          .filter(s => filters.students.includes(s.id))
                          .map(student => {
                            // Enrich with the full student data from fees
                            const feeWithStudent = data.find(fee => fee.student?.id === student.id);
                            return feeWithStudent?.student || student;
                          })
                      : // Otherwise, get students from filtered data
                        Array.from(new Set(data.map(item => item.student?.id)))
                          .map(id => {
                            const item = data.find(i => i.student?.id === id);
                            return item?.student;
                          })
                          .filter(Boolean)
                  } 
                  loading={loading}
                  filteredByGuardians={filters.guardians.length > 0}
                  guardiansSelected={filters.guardians.length > 0 ? 
                    guardians.filter(g => filters.guardians.includes(g.id)).map(g => g.name).join(", ") : 
                    null
                  }
                />
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === 'guardians' && (
          <div className="p-4">
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Apoderados</h2>
              </CardHeader>
              <CardContent>
                <GuardianReportTable 
                  data={
                    // If specific guardians are selected, show only those
                    filters.guardians.length > 0 
                      ? guardians.filter(g => filters.guardians.includes(g.id)) 
                      : // Otherwise, if students are filtered, show their guardians
                        filters.students.length > 0
                          ? guardians.filter(g => {
                              // First get the student IDs from the filtered data
                              const studentIds = Array.from(
                                new Set(
                                  data
                                    .filter(fee => fee.student)
                                    .map(fee => fee.student.id)
                                )
                              );
                              
                              // Then check if this guardian is linked to any of those students
                              // using the student_guardian relationship
                              return studentIds.some(studentId => {
                                const studentGuardian = data.find(fee => 
                                  fee.student?.id === studentId && 
                                  fee.student_guardian?.some(sg => sg.guardian_id === g.id)
                                );
                                return !!studentGuardian;
                              });
                            })
                          // If no filters, show all guardians with students in the data
                          : guardians.filter(g => {
                              return data.some(fee => 
                                fee.student_guardian?.some(sg => sg.guardian_id === g.id)
                              );
                            })
                  } 
                  loading={loading} 
                  filteredByStudents={filters.students.length > 0}
                  studentsSelected={filters.students.length > 0 ? 
                    students.filter(s => filters.students.includes(s.id)).map(s => s.name).join(", ") : 
                    null
                  }
                />
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </main>
  );
}