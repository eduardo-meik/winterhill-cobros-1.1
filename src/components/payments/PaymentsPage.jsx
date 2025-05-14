import React from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { PaymentsTable } from './PaymentsTable';
import { PaymentsFilters } from './PaymentsFilters';
import { RegisterPaymentModal } from './RegisterPaymentModal';
import { PaymentDetailsModal } from './PaymentDetailsModal';
import { utils, writeFile } from 'xlsx';
import { useEffect, useState, useMemo } from 'react';
import { supabase } from '@/services/supabase'; // Ruta corregida usando el alias @
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';

export function PaymentsPage() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [isRegisterModalOpen, setIsRegisterModalOpen] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [filters, setFilters] = useState({
    search: '',
    status: 'all',
    curso: 'all',
    month: 'all',
    year: 'all',
    paymentMethod: 'all',
    startDate: '',
    endDate: ''
  });

  const filteredPayments = useMemo(() => {
    return payments.filter(payment => {
      // Status filter (case-insensitive)
      if (filters.status !== 'all' && payment.status?.toLowerCase() !== filters.status.toLowerCase()) return false;
      
      // Curso filter (case-insensitive)
      if (filters.curso !== 'all' && 
          payment.student?.curso?.nom_curso?.toLowerCase() !== filters.curso.toLowerCase()) return false;
      
      // Date filters
      const paymentDate = new Date(payment.due_date);
      
      // Add month filter
      if (filters.month !== 'all') {
        const paymentMonth = (paymentDate.getMonth() + 1).toString();
        if (paymentMonth !== filters.month) return false;
      }
      
      // Add year filter
      if (filters.year !== 'all') {
        const paymentYear = paymentDate.getFullYear().toString();
        if (paymentYear !== filters.year) return false;
      }
      
      // Start date filter
      if (filters.startDate) {
        const startDate = new Date(filters.startDate);
        startDate.setHours(0, 0, 0, 0);
        if (paymentDate < startDate) return false;
      }
      
      // End date filter
      if (filters.endDate) {
        const endDate = new Date(filters.endDate);
        endDate.setHours(23, 59, 59, 999);
        if (paymentDate > endDate) return false;
      }
      
      // Payment method filter (case-insensitive)
      if (filters.paymentMethod && filters.paymentMethod !== 'all' && 
          payment.payment_method?.toLowerCase() !== filters.paymentMethod.toLowerCase()) {
        return false;
      }

      // Search filter
      if (filters.search) {
        const searchTerm = filters.search.toLowerCase();
        return (
          payment.student?.first_name?.toLowerCase().includes(searchTerm) ||
          payment.student?.apellido_paterno?.toLowerCase().includes(searchTerm) ||
          (payment.student?.whole_name && payment.student.whole_name.toLowerCase().includes(searchTerm))
        );
      }
      
      return true;
    });
  }, [payments, filters]);

  const {
    currentPage,
    pageSize,
    setPageSize,
    totalPages,
    paginatedItems,
    handlePageChange
  } = usePagination(filteredPayments);

  const handleFiltersChange = (newFilters) => {
    setFilters(newFilters);
  };

  const handleClearFilters = () => {
    setFilters({
      search: '',
      status: 'all',
      curso: 'all',
      month: 'all',
      year: 'all',
      paymentMethod: 'all',
      startDate: '',
      endDate: ''
    });
  };

  // Extract unique cursos from payments
  const availableCursos = useMemo(() => {
    const cursos = [...new Set(payments.map(payment => payment.student?.curso?.nom_curso))].filter(Boolean);
    return cursos.sort();
  }, [payments]);

  useEffect(() => {
    fetchPayments();
  }, []);

  const fetchPayments = async () => {
    try {
      setLoading(true);
      
      // Check if user is authenticated
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('No autenticado');
      }

      // Step 1: Fetch fees without nested relations
      const { data: fees, error: feesError } = await supabase
        .from('fee')
        .select('*')
        .order('due_date', { ascending: false });
  
      if (feesError) throw feesError;
  
      if (!fees || fees.length === 0) {
        setPayments([]);
        setLoading(false); // Ensure loading is set to false here
        return;
      }
      
      // Step 3: Fallback - fetch minimal student data without relations that might trigger the policy
      const studentIdsToFetch = [...new Set(fees.map(fee => fee.student_id).filter(id => id != null))]; // Filter out null/undefined IDs
      
      let students = [];
      if (studentIdsToFetch.length > 0) {
        const { data: fetchedStudents, error: studentsError } = await supabase
          .from('students')
          .select('id, first_name, apellido_paterno, curso')
          .in('id', studentIdsToFetch);
    
        if (studentsError) throw studentsError;
        students = fetchedStudents || [];
      }
    
      // Step 4: Fetch curso data separately to avoid nested queries
      const cursoIds = [...new Set(students.filter(s => s && s.curso).map(s => s.curso))]; // Add check for s
    
      let cursosData = [];
      if (cursoIds.length > 0) {
        const { data: cursos, error: cursosError } = await supabase
          .from('cursos')
          .select('id, nom_curso')
          .in('id', cursoIds);
          
        if (cursosError) {
            console.error("Error fetching cursos:", cursosError);
            // Decide if you want to throw or continue without curso data
        } else {
            cursosData = cursos || [];
        }
      }
    
      // Step 5: Join all data together client-side
      const joinedData = fees.map(fee => {
        const studentData = students.find(s => s && s.id === fee.student_id) || {}; // Add check for s
        const cursoObject = studentData.curso ? cursosData.find(c => c && c.id === studentData.curso) : null; // Add check for c
        return {
          ...fee,
          student: {
            ...studentData, 
            curso: cursoObject 
          }
        };
      });
  
      console.log("Fetched payments:", joinedData);
      setPayments(joinedData);

    } catch (error) {
      if (error.message === 'No autenticado') {
        toast.error('Por favor inicia sesión para ver los pagos');
        // Potentially redirect to login or handle appropriately
      } else if (supabase.handleError) { // Check if supabase.handleError exists
        supabase.handleError(error); // This might not be a standard Supabase client method
      } else {
        console.error('Error fetching payments:', error); // Log the actual error object
        toast.error('Error al cargar los pagos. Intente más tarde.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleExportExcel = async (exportAll = false) => {
    try {
      setExporting(true);
      
      // Determine which data to export
      const dataToExport = exportAll ? payments : filteredPayments;
      
      // Transform data for Excel
      const excelData = dataToExport.map(payment => ({
        'Estudiante': `${payment.student.first_name} ${payment.student.apellido_paterno}`,
        'Curso': payment.student.curso?.nom_curso || '-',
        'Monto': payment.amount,
        'Estado': payment.status === 'paid' ? 'Pagado' : payment.status === 'pending' ? 'Pendiente' : 'Vencido',
        'Fecha Vencimiento': format(new Date(payment.due_date), 'dd/MM/yyyy'),
        'Fecha Pago': payment.payment_date ? format(new Date(payment.payment_date), 'dd/MM/yyyy') : '-',
        'Método de Pago': payment.payment_method || '-',
        'Folio Boleta': payment.num_boleta || '-',
        'Mov. Bancario': payment.mov_bancario || '-',
        'Notas': payment.notes || '-'
      }));
      
      // Create workbook and worksheet
      const wb = utils.book_new();
      const ws = utils.json_to_sheet(excelData);
      
      // Add worksheet to workbook
      utils.book_append_sheet(wb, ws, 'Pagos');
      
      // Auto-size columns
      const colWidths = Object.keys(excelData[0] || {}).map(key => ({
        wch: Math.max(key.length, ...excelData.map(row => String(row[key]).length))
      }));
      ws['!cols'] = colWidths;
      
      // Generate filename with timestamp
      const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
      const filename = `pagos_${timestamp}.xlsx`;
      
      // Save file
      writeFile(wb, filename);
      
      toast.success('Archivo Excel exportado exitosamente');
    } catch (error) {
      console.error('Error al exportar:', error);
      toast.error('Error al exportar el archivo Excel');
    } finally {
      setExporting(false);
    }
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4 mb-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Aranceles</h1>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Button
                onClick={() => handleExportExcel(false)}
                disabled={exporting || filteredPayments.length === 0}
                variant="secondary"
                className="flex items-center gap-2"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                  <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48Zm0,144H32V64H224V192ZM76,140a12,12,0,1,1-12-12A12,12,0,0,1,76,140Zm116,0a12,12,0,1,1-12-12A12,12,0,0,1,192,140Z"/>
                </svg>
                {exporting ? 'Exportando...' : 'Exportar Filtrados'}
              </Button>
              <Button
                onClick={() => handleExportExcel(true)}
                disabled={exporting || payments.length === 0}
                variant="secondary"
                className="flex items-center gap-2"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                  <path d="M213.66,82.34l-56-56A8,8,0,0,0,152,24H56A16,16,0,0,0,40,40V216a16,16,0,0,0,16,16H200a16,16,0,0,0,16-16V88A8,8,0,0,0,213.66,82.34ZM160,51.31,188.69,80H160ZM200,216H56V40h88V88a8,8,0,0,0,8,8h48V216Z"/>
                </svg>
                {exporting ? 'Exportando...' : 'Exportar Todo'}
              </Button>
            </div>
            <Button onClick={() => setIsRegisterModalOpen(true)} className="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48Zm0,144H32V64H224V192ZM64,104a8,8,0,0,1,8-8H96a8,8,0,0,1,0,16H72A8,8,0,0,1,64,104Zm128,48a8,8,0,0,1-8,8H72a8,8,0,0,1,0-16H184A8,8,0,0,1,192,152Z" />
              </svg>
              Registrar Pago
            </Button>
          </div>
        </div>

        <div className="p-4">
          <Card>
            <CardHeader>
              <PaymentsFilters
                filters={filters}
                onFiltersChange={handleFiltersChange}
                availableCursos={availableCursos}
                onClearFilters={handleClearFilters}
              />
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
                </div>
              ) : (
                <PaymentsTable
                  payments={paginatedItems}
                  loading={loading}
                  onViewDetails={setSelectedPayment}
                />
              )}
              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                onPageChange={handlePageChange}
                totalRecords={filteredPayments.length}
                pageSize={pageSize}
                onPageSizeChange={setPageSize}
              />
            </CardContent>
          </Card>
        </div>
      </div>

      {selectedPayment && (
        <PaymentDetailsModal
          payment={selectedPayment}
          onClose={() => setSelectedPayment(null)}
          onSuccess={fetchPayments}
        />
      )}
      
      <RegisterPaymentModal
        isOpen={isRegisterModalOpen}
        onClose={() => setIsRegisterModalOpen(false)}
        onSuccess={fetchPayments}
      />
    </main>
  );
}