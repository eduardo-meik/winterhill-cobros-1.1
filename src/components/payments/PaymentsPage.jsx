import React from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { PaymentsTable } from './PaymentsTable';
import { PaymentsFilters } from './PaymentsFilters';
import { RegisterPaymentModal } from './RegisterPaymentModal';
import { PaymentDetailsModal } from './PaymentDetailsModal';
import { utils, writeFile } from 'sheetjs-style';
import { useEffect, useState, useMemo } from 'react';
import { supabase } from '@/services/supabase';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';

// Note: Changed from PaymentsPage to PaymentsPage to match import expectations
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
    cuota: 'all', // Added filter for cuota
    startDate: '',
    endDate: ''
  });

  // Extract available filter options from data
  const filterOptions = useMemo(() => {
    if (payments.length === 0) return { cursos: [], years: [], cuotas: [] };
    
    // Extract unique curso names
    const cursos = [...new Set(
      payments.map(payment => payment.student?.cursos?.nom_curso).filter(Boolean)
    )].sort();
    
    // Extract unique years from due_date
    const years = [...new Set(
      payments.map(payment => {
        if (!payment.due_date) return null;
        return new Date(payment.due_date).getFullYear().toString();
      }).filter(Boolean)
    )].sort();
    
    // Extract unique cuota numbers
    const cuotas = [...new Set(
      payments.map(payment => payment.numero_cuota).filter(Boolean)
    )].sort((a, b) => parseInt(a) - parseInt(b));
    
    return { cursos, years, cuotas };
  }, [payments]);

  const filteredPayments = useMemo(() => {
    return payments.filter(payment => {
      try {
        // Status filter
        if (filters.status !== 'all' && payment.status !== filters.status) return false;
        
        // Curso filter
        if (filters.curso !== 'all' && 
            payment.student?.cursos?.nom_curso !== filters.curso) return false;
        
        // Cuota filter (NEW)
        if (filters.cuota !== 'all' && payment.numero_cuota !== filters.cuota) return false;
        
        // Date filters
        const paymentDate = payment.due_date ? new Date(payment.due_date) : null;
        if (paymentDate) {
          // Month filter
          if (filters.month !== 'all') {
            const paymentMonth = (paymentDate.getMonth() + 1).toString();
            if (paymentMonth !== filters.month) return false;
          }
          
          // Year filter
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
        }
        
        // Payment method filter
        if (filters.paymentMethod !== 'all' && 
            payment.payment_method !== filters.paymentMethod) return false;

        // Search filter
        if (filters.search) {
          const searchTerm = filters.search.toLowerCase();
          const studentName = payment.student?.whole_name || 
            `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`;
          
          return (
            studentName.toLowerCase().includes(searchTerm) ||
            payment.student?.run?.toLowerCase().includes(searchTerm) ||
            (payment.numero_cuota && payment.numero_cuota.toString().includes(searchTerm))
          );
        }
        
        return true;
      } catch (error) {
        console.error("Error filtering payment:", error, payment);
        return false;
      }
    });
  }, [payments, filters]);

  // Pagination
  const {
    currentPage,
    pageSize,
    setPageSize,
    totalPages,
    paginatedItems,
    handlePageChange
  } = usePagination(filteredPayments);

  useEffect(() => {
    fetchPayments();
  }, []);

  const fetchPayments = async () => {
    try {
      setLoading(true);
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('No autenticado');
      }

      // Fetch all fees with student and curso information
      const { data: fees, error: feesError } = await supabase
        .from('fee')
        .select(`
          *,
          student:students (
            id,
            first_name,
            apellido_paterno,
            whole_name,
            run,
            curso,
            cursos:curso (
              id,
              nom_curso
            )
          )
        `)
        .order('created_at', { ascending: false })
        .limit(2000);

      if (feesError) throw feesError;
      
      // Log fee data for debugging
      console.log('Total fees fetched:', fees?.length);
      
      // Count distribution of cuotas
      const cuotaDistribution = {};
      fees?.forEach(fee => {
        const cuotaNum = fee.numero_cuota || 'unknown';
        cuotaDistribution[cuotaNum] = (cuotaDistribution[cuotaNum] || 0) + 1;
      });
      
      console.log('Cuota distribution:', cuotaDistribution);
      
      setPayments(fees || []);
    } catch (error) {
      console.error('Error fetching payments:', error);
      toast.error('Error al cargar los pagos');
    } finally {
      setLoading(false);
    }
  };

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
      cuota: 'all',
      startDate: '',
      endDate: ''
    });
  };

  const handleExportExcel = async (exportAll = false) => {
    try {
      setExporting(true);
      
      const dataToExport = exportAll ? payments : filteredPayments;
      
      const excelData = dataToExport.map(payment => ({
        'Estudiante': payment.student?.whole_name || 
          `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`,
        'RUN': payment.student?.run || '-',
        'Curso': payment.student?.cursos?.nom_curso || '-',
        'Cuota N°': payment.numero_cuota || '-',
        'Monto': payment.amount ? `$${Math.round(payment.amount).toLocaleString()}` : '-',
        'Estado': payment.status === 'paid' ? 'Pagado' : 
                 payment.status === 'pending' ? 'Pendiente' : 'Vencido',
        'Fecha Vencimiento': payment.due_date ? format(new Date(payment.due_date), 'dd/MM/yyyy') : '-',
        'Fecha Pago': payment.payment_date ? format(new Date(payment.payment_date), 'dd/MM/yyyy') : '-',
        'Método de Pago': payment.payment_method || '-',
        'Folio Boleta': payment.num_boleta || '-',
        'Mov. Bancario': payment.mov_bancario || '-',
        'Notas': payment.notes || '-'
      }));
      
      const wb = utils.book_new();
      const ws = utils.json_to_sheet(excelData);
      
      utils.book_append_sheet(wb, ws, 'Pagos');
      
      const colWidths = Object.keys(excelData[0] || {}).map(key => ({
        wch: Math.max(key.length, ...excelData.map(row => String(row[key] || '').length))
      }));
      ws['!cols'] = colWidths;
      
      const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
      const filename = `pagos_${timestamp}.xlsx`;
      
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
                variant="outline" /* Changed from secondary to outline */
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
                variant="outline" /* Changed from secondary to outline */
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
                onClearFilters={handleClearFilters}
                filterOptions={filterOptions}
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