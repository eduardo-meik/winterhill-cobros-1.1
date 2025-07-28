import React from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { PaymentsTable } from './PaymentsTable';
import { PaymentsFilters } from './PaymentsFilters';
import { RegisterPaymentModal } from './RegisterPaymentModal';
import { PaymentDetailsModal } from './PaymentDetailsModal';
import * as XLSX from 'xlsx';
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
  const [totalCount, setTotalCount] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [currentOffset, setCurrentOffset] = useState(0);
  const BATCH_SIZE = 250; // Optimized smaller batch for faster queries
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

  // Optimize filter options calculation with useMemo and better data structure
  const filterOptions = useMemo(() => {
    if (payments.length === 0) return { cursos: [], years: [], cuotas: [] };
    
    // Use Set for O(1) lookups and better performance
    const cursosSet = new Set();
    const yearsSet = new Set();
    const cuotasSet = new Set();
    
    // Single pass through data for all filter options
    payments.forEach(payment => {
      // Extract curso names
      const cursoName = payment.student?.cursos?.nom_curso;
      if (cursoName) cursosSet.add(cursoName);
      
      // Extract years from due_date
      if (payment.due_date) {
        const year = new Date(payment.due_date).getFullYear().toString();
        yearsSet.add(year);
      }
      
      // Extract cuota numbers
      if (payment.numero_cuota) {
        cuotasSet.add(payment.numero_cuota);
      }
    });
    
    return { 
      cursos: Array.from(cursosSet).sort(),
      years: Array.from(yearsSet).sort(),
      cuotas: Array.from(cuotasSet).sort((a, b) => parseInt(a) - parseInt(b))
    };
  }, [payments]);

  // Optimize filtered payments with better performance and error handling
  const filteredPayments = useMemo(() => {
    if (!payments.length) return [];

    return payments.filter(payment => {
      try {
        // Early returns for better performance
        
        // Status filter
        if (filters.status !== 'all' && payment.status !== filters.status) {
          return false;
        }
        
        // Curso filter
        if (filters.curso !== 'all' && 
            payment.student?.cursos?.nom_curso !== filters.curso) {
          return false;
        }
        
        // Cuota filter
        if (filters.cuota !== 'all' && payment.numero_cuota !== filters.cuota) {
          return false;
        }
        
        // Payment method filter
        if (filters.paymentMethod !== 'all' && 
            payment.payment_method !== filters.paymentMethod) {
          return false;
        }

        // Date filters - process only if payment has due_date
        if (payment.due_date) {
          const paymentDate = new Date(payment.due_date);
          
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
          
          // Date range filters
          if (filters.startDate) {
            const startDate = new Date(filters.startDate);
            startDate.setHours(0, 0, 0, 0);
            if (paymentDate < startDate) return false;
          }
          
          if (filters.endDate) {
            const endDate = new Date(filters.endDate);
            endDate.setHours(23, 59, 59, 999);
            if (paymentDate > endDate) return false;
          }
        }

        // Search filter - optimize string operations
        if (filters.search) {
          const searchTerm = filters.search.toLowerCase();
          const studentName = payment.student?.whole_name || 
            `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`;
          
          // Use includes for faster string matching
          return (
            studentName.toLowerCase().includes(searchTerm) ||
            (payment.student?.run && payment.student.run.toLowerCase().includes(searchTerm)) ||
            (payment.numero_cuota && payment.numero_cuota.toString().includes(searchTerm))
          );
        }
        
        return true;
      } catch (error) {
        // Log error in development only
        if (import.meta.env.DEV) {
          console.error("Error filtering payment:", error, payment);
        }
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
    fetchPayments(true); // Reset and fetch initial batch
  }, []);

  const fetchPayments = async (reset = true) => {
    try {
      if (reset) {
        setLoading(true);
        setCurrentOffset(0);
      }
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('No autenticado');
      }

      const offset = reset ? 0 : currentOffset;
      const startTime = performance.now();

      // First, get the total count efficiently (only on reset)
      if (reset) {
        const { count, error: countError } = await supabase
          .from('fee')
          .select('id', { count: 'exact', head: true });
        
        if (countError) throw countError;
        setTotalCount(count || 0);
      }

      // Ultra-optimized query: Use inner joins instead of left joins for better performance
      // This completely eliminates the LATERAL JOIN issues
      const { data: fees, error: feesError } = await supabase
        .from('fee')
        .select(`
          id,
          student_id,
          amount,
          status,
          due_date,
          payment_date,
          payment_method,
          numero_cuota,
          num_boleta,
          mov_bancario,
          notes,
          created_at,
          students!inner (
            id,
            first_name,
            apellido_paterno,
            whole_name,
            run,
            curso,
            cursos!inner (
              id,
              nom_curso
            )
          )
        `)
        .order('created_at', { ascending: false })
        .range(offset, offset + BATCH_SIZE - 1);

      if (feesError) throw feesError;
      
      // Transform data to match expected structure
      const transformedFees = (fees || []).map(fee => ({
        ...fee,
        student: {
          ...fee.students,
          cursos: fee.students?.cursos
        }
      }));
      
      if (reset) {
        setPayments(transformedFees);
      } else {
        setPayments(prev => [...prev, ...transformedFees]);
      }

      setHasMore(transformedFees.length === BATCH_SIZE);
      setCurrentOffset(offset + BATCH_SIZE);
      
      // Performance logging (development only)
      if (import.meta.env.DEV) {
        const endTime = performance.now();
        const queryTime = endTime - startTime;
        console.log(`✅ Query optimized: ${queryTime.toFixed(2)}ms for ${transformedFees.length} records`);
        
        if (reset) {
          console.log('📊 Performance stats:');
          console.log(`   - Total records available: ${totalCount}`);
          console.log(`   - Batch size: ${BATCH_SIZE}`);
          console.log(`   - Query time: ${queryTime.toFixed(2)}ms`);
          console.log(`   - Records per ms: ${(transformedFees.length / queryTime).toFixed(2)}`);
        }
      }
      
    } catch (error) {
      console.error('Error fetching payments:', error);
      toast.error('Error al cargar los pagos');
    } finally {
      setLoading(false);
    }
  };

  const loadMorePayments = async () => {
    if (!hasMore || loading) return;
    await fetchPayments(false);
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
      
      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.json_to_sheet(excelData);
      
      XLSX.utils.book_append_sheet(wb, ws, 'Pagos');
      
      const colWidths = Object.keys(excelData[0] || {}).map(key => ({
        wch: Math.max(key.length, ...excelData.map(row => String(row[key] || '').length))
      }));
      ws['!cols'] = colWidths;
      
      const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
      const filename = `pagos_${timestamp}.xlsx`;
      
      XLSX.writeFile(wb, filename);
      
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
              
              {/* Load More Button for better performance */}
              {hasMore && !loading && (
                <div className="flex justify-center mt-4">
                  <Button
                    onClick={loadMorePayments}
                    variant="outline"
                    className="flex items-center gap-2"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                      <path d="M224,128a8,8,0,0,1-8,8H128v88a8,8,0,0,1-16,0V136H24a8,8,0,0,1,0-16h88V32a8,8,0,0,1,16,0v88h88A8,8,0,0,1,224,128Z"/>
                    </svg>
                    Cargar más registros ({totalCount - payments.length} restantes)
                  </Button>
                </div>
              )}
              
              {/* Performance info for debugging */}
              {import.meta.env.DEV && (
                <div className="text-xs text-gray-500 mt-2 text-center">
                  Mostrando {payments.length} de {totalCount} registros totales
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {selectedPayment && (
        <PaymentDetailsModal
          payment={selectedPayment}
          onClose={() => setSelectedPayment(null)}
          onSuccess={() => fetchPayments(true)}
        />
      )}
      
      <RegisterPaymentModal
        isOpen={isRegisterModalOpen}
        onClose={() => setIsRegisterModalOpen(false)}
        onSuccess={() => fetchPayments(true)}
      />
    </main>
  );
}