import React, { useState, useRef, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { PaymentsOverview } from './graphs/PaymentsOverview';
import { PaymentStatusChart } from './graphs/PaymentStatusChart';
import { PaymentMethodsChart } from './graphs/PaymentMethodsChart';
import { PaymentsTable } from './graphs/PaymentsTable';
import { ReportFilters } from './ReportFilters';
import { Button } from '../ui/Button';
import { format } from 'date-fns';
import { utils, writeFile } from 'xlsx';
import toast from 'react-hot-toast';
import { supabase } from '../../services/supabase';
import { PDFReport } from './PDFReport';
import { TabsContainer, TabButton } from "../ui/Tabs";
import { GuardianReportTable } from "./tables/GuardianReportTable";
import { StudentReportTable } from "./tables/StudentReportTable";

export function ReportingPage() {
  const [filters, setFilters] = useState({
    status: 'all',
    guardians: [],
    courses: [],
    startDate: '',
    endDate: ''
  });
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const [guardians, setGuardians] = useState([]);
  const [courses, setCourses] = useState([]);
  const [exporting, setExporting] = useState(false);
  const [activeTab, setActiveTab] = useState('payments');

  // Refs for charts to capture for PDF export
  const paymentsOverviewRef = useRef(null);
  const paymentStatusRef = useRef(null);
  const paymentMethodsRef = useRef(null);

  useEffect(() => {
    fetchGuardiansAndCourses();
    // Initial data fetch with default filters
    fetchData(filters);
  }, []);

  const fetchData = async (filters) => {
    try {
      setLoading(true);
      
      // First, fetch fees (previously called payments) with student information
      let query = supabase.from('fee').select(`
        *,
        student:students (
          id,
          first_name,
          apellido_paterno,
          whole_name,
          nivel,
          run,
          curso,
          cursos:curso (
            id,
            nom_curso
          )
        )
      `);
      
      // Apply filters
      if (filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }
      
      if (filters.startDate) {
        query = query.gte('due_date', filters.startDate);
      }
      
      if (filters.endDate) {
        query = query.lte('due_date', filters.endDate);
      }
      
      const { data: feesData, error: feesError } = await query;

      if (feesError) throw feesError;
      
      // Filter by guardians and courses client-side (as these require joining across multiple tables)
      let filteredData = feesData;
      
      // Filter by guardians if needed
      if (filters.guardians && filters.guardians.length > 0) {
        // Fetch student-guardian relationships
        const { data: studentGuardianData, error: relationError } = await supabase
          .from('student_guardian')
          .select('*')
          .in('guardian_id', filters.guardians);
          
        if (relationError) throw relationError;
        
        // Get student IDs for these guardians
        const studentIds = studentGuardianData.map(sg => sg.student_id);
        
        // Filter payments to only include these students
        filteredData = filteredData.filter(fee => 
          studentIds.includes(fee.student_id)
        );
      }
      
      // Filter by courses if needed
      if (filters.courses && filters.courses.length > 0) {
        filteredData = filteredData.filter(fee => 
          fee.student && filters.courses.includes(fee.student.curso)
        );
      }

      setData(filteredData);
    } catch (error) {
      console.error('Error fetching fees:', error);
      toast.error('Error al cargar los aranceles');
    } finally {
      setLoading(false);
    }
  };

  const fetchGuardiansAndCourses = async () => {
    try {
      const [guardiansResponse, coursesResponse] = await Promise.all([
        supabase.from('guardians').select('id, first_name, last_name'),
        supabase.from('cursos').select('id, nom_curso')
      ]);

      if (guardiansResponse.error) throw guardiansResponse.error;
      if (coursesResponse.error) throw coursesResponse.error;

      setGuardians(guardiansResponse.data.map(g => ({
        id: g.id,
        name: `${g.last_name}, ${g.first_name}`
      })));
      setCourses(coursesResponse.data);
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Error al cargar los datos de filtros');
    }
  };

  const calculateSummaryData = (data) => {
    if (!data || data.length === 0) {
      return {
        totalPaid: 0,
        totalPending: 0,
        totalOverdue: 0,
        paymentCount: 0, // Changed from count to paymentCount
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
      paymentCount: data.length, // Changed from count to paymentCount
      delinquencyRate
    };
  };

  const handleExport = async (type) => {
    try {
      setExporting(true);
      
      const formattedData = data.map(item => ({
        Estudiante: item.student?.whole_name || `${item.student?.apellido_paterno || ''}, ${item.student?.first_name || ''}`,
        Curso: item.student?.cursos?.nom_curso || 'Sin asignar',
        RUN: item.student?.run || 'N/A',
        Monto: parseInt(item.amount || 0).toLocaleString('es-CL'),
        Estado: item.status === 'paid' ? 'Pagado' : item.status === 'pending' ? 'Pendiente' : 'Vencido',
        'Fecha Vencimiento': item.due_date ? format(new Date(item.due_date), 'dd/MM/yyyy') : 'N/A',
        'Fecha Pago': item.payment_date ? format(new Date(item.payment_date), 'dd/MM/yyyy') : 'N/A',
        'Método Pago': item.payment_method || 'N/A'
      }));

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
          : 'Todos'
      };
      
      const summaryData = calculateSummaryData(data);
      
      if (type === 'excel') {
        const wb = utils.book_new();
        
        const filterInfo = [
          ['Informe de Aranceles'],
          ['Generado el:', format(new Date(), 'dd/MM/yyyy HH:mm')],
          [''],
          ['Filtros aplicados:'],
          ['Período:', readableFilters['Período']],
          ['Estado:', readableFilters['Estado']],
          ['Apoderados:', readableFilters['Apoderados']],
          ['Cursos:', readableFilters['Cursos']],
          [''],
          ['Resumen:'],
          ['Total Pagado:', `$${summaryData.totalPaid.toLocaleString('es-CL')}`],
          ['Total Pendiente:', `$${summaryData.totalPending.toLocaleString('es-CL')}`],
          ['Total Vencido:', `$${summaryData.totalOverdue.toLocaleString('es-CL')}`],
          ['Cantidad de Pagos:', summaryData.paymentCount.toString()],
          ['Tasa de Morosidad:', `${summaryData.delinquencyRate}%`]
        ];
        
        const filterWs = utils.aoa_to_sheet(filterInfo);
        utils.book_append_sheet(wb, filterWs, 'Información');
        
        // Add data sheet
        const ws = utils.json_to_sheet(formattedData);
        utils.book_append_sheet(wb, ws, 'Aranceles');
        
        // Set column widths
        ws['!cols'] = [
          { wch: 30 }, // Estudiante
          { wch: 15 }, // Curso
          { wch: 12 }, // RUN
          { wch: 12 }, // Monto
          { wch: 10 }, // Estado
          { wch: 16 }, // Fecha Vencimiento
          { wch: 16 }, // Fecha Pago
          { wch: 15 }, // Método Pago
        ];
        
        const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
        writeFile(wb, `informe_aranceles_${timestamp}.xlsx`);
        toast.success('Datos exportados exitosamente a Excel');
      } else if (type === 'pdf') {
        const report = new PDFReport('Informe de Aranceles', readableFilters);
        
        report.addHeader();
        report.addSummary(summaryData); // summaryData now contains paymentCount
        report.addPaymentsTable(data);
        
        // Add charts if available
        if (paymentsOverviewRef.current) {
          report.addChart(paymentsOverviewRef.current, 'Resumen de Pagos');
        }
        if (paymentStatusRef.current) {
          report.addChart(paymentStatusRef.current, 'Estado de Pagos');
        }
        if (paymentMethodsRef.current) {
          report.addChart(paymentMethodsRef.current, 'Métodos de Pago');
        }
        
        const timestamp = format(new Date(), 'yyyyMMdd_HHmmss');
        report.save(`informe_aranceles_${timestamp}.pdf`);
        toast.success('PDF generado exitosamente');
      }
    } catch (error) {
      console.error('Error exporting data:', error);
      toast.error('Error al exportar los datos');
    } finally {
      setExporting(false);
    }
  };

  const handleApplyFilters = async (newFilters) => {
    setFilters(newFilters);
    await fetchData(newFilters);
  };

  const handleResetFilters = () => {
    const defaultFilters = {
      status: 'all',
      guardians: [],
      courses: [],
      startDate: '',
      endDate: ''
    };
    setFilters(defaultFilters);
    fetchData(defaultFilters);
  };

  // Create Tabs component to use instead of importing
  if (!TabsContainer) {
    const TabsContainer = ({ children }) => (
      <div className="flex border-b border-gray-200 dark:border-gray-800">
        {children}
      </div>
    );

    const TabButton = ({ children, isActive, onClick }) => (
      <button
        className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
          isActive 
            ? 'border-primary text-primary dark:border-primary dark:text-primary' 
            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
        }`}
        onClick={onClick}
      >
        {children}
      </button>
    );
  }

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
                <PaymentsOverview ref={paymentsOverviewRef} filters={filters} />
              </CardContent>
            </Card>

            {/* Payment Status Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Estado de Pagos</h2>
              </CardHeader>
              <CardContent>
                <PaymentStatusChart ref={paymentStatusRef} filters={filters} />
              </CardContent>
            </Card>

            {/* Payment Methods Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Métodos de Pago</h2>
              </CardHeader>
              <CardContent>
                <PaymentMethodsChart ref={paymentMethodsRef} filters={filters} />
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
                <PaymentsTable data={data} loading={loading} />
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
                <StudentReportTable data={data.map(item => item.student).filter(Boolean)} loading={loading} />
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
                <GuardianReportTable data={guardians} loading={loading} />
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </main>
  );
}