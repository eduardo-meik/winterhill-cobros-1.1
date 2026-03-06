import React from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { PaymentsTable } from './PaymentsTable';
import { PaymentsFilters } from './PaymentsFilters';
import { RegisterPaymentModal } from './RegisterPaymentModal';
import { PaymentDetailsModal } from './PaymentDetailsModal';
import { useState, useMemo } from 'react';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';
import { useAcademicYear } from '../../contexts/AcademicYearContext';
import { useFeesQuery } from '../../hooks/queries/useFeesQuery';

// Note: Changed from PaymentsPage to PaymentsPage to match import expectations
export function PaymentsPage() {
  const { academicYear, setAcademicYear } = useAcademicYear();
  const isReadOnly = academicYear < new Date().getFullYear();
  const { data: rawFees = [], isLoading: loading } = useFeesQuery(academicYear);
  const [exporting, setExporting] = useState(false);
  const [isRegisterModalOpen, setIsRegisterModalOpen] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [filters, setFilters] = useState({
    search: '',
    status: 'all',
    curso: 'all',
    month: 'all',
    paymentMethod: 'all',
    cuota: 'all',
    startDate: '',
    endDate: ''
  });

  // Sort by created_at desc (server query used to do this)
  const payments = useMemo(() =>
    [...rawFees].sort((a, b) => new Date(b.created_at) - new Date(a.created_at)),
    [rawFees]
  );
  // Optimize filter options calculation with useMemo and better data structure
  const filterOptions = useMemo(() => {
    if (payments.length === 0) return { cursos: [], cuotas: [] };
    
    // Use Set for O(1) lookups and better performance
    const cursosSet = new Set();
    const cuotasSet = new Set();
    
    // Single pass through data for all filter options
    payments.forEach(payment => {
      // Extract curso names
      const cursoName = payment.student?.cursos?.nom_curso;
      if (cursoName) cursosSet.add(cursoName);
      
      // Extract cuota numbers - convert to string for consistent comparison
      if (payment.numero_cuota !== null && payment.numero_cuota !== undefined) {
        cuotasSet.add(payment.numero_cuota.toString());
      }
    });
    
    return { 
      cursos: Array.from(cursosSet).sort(),
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
        
        // Cuota filter - Fix data type comparison (numeric vs string)
        if (filters.cuota !== 'all' && payment.numero_cuota?.toString() !== filters.cuota) {
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

  // loadMorePayments function removed since we now load all records at once

  const handleFiltersChange = (newFilters) => {
    setFilters(newFilters);
  };

  const handleClearFilters = () => {
    setFilters({
      search: '',
      status: 'all',
      curso: 'all',
      month: 'all',
      paymentMethod: 'all',
      cuota: 'all',
      startDate: '',
      endDate: ''
    });
  };

  const handleExportExcel = async (exportAll = false) => {
    try {
      setExporting(true);
      toast.loading('Exportando Excel...', { id: 'payments-export' });
      
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
      
      const ExcelJS = await import('exceljs');
      const wb = new ExcelJS.Workbook();
      const ws = wb.addWorksheet('Pagos');
      
      // Define headers
      const headers = Object.keys(excelData[0] || {});
      ws.addRow(headers);
      
      // Add data rows
      excelData.forEach(row => {
        ws.addRow(Object.values(row));
      });
      
      // Auto-adjust column widths
      headers.forEach((header, index) => {
        const column = ws.getColumn(index + 1);
        const maxLength = Math.max(
          header.length,
          ...excelData.map(row => String(row[header] || '').length)
        );
        column.width = Math.min(maxLength + 2, 50);
      });
      
      const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
      const filename = `pagos_${timestamp}.xlsx`;
      
      // Write file
      const buffer = await wb.xlsx.writeBuffer();
      const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      link.click();
      window.URL.revokeObjectURL(url);
      
      toast.success('Archivo Excel exportado exitosamente', { id: 'payments-export' });
    } catch (error) {
      console.error('Error al exportar:', error);
      toast.error('Error al exportar el archivo Excel', { id: 'payments-export' });
    } finally {
      setExporting(false);
    }
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        {academicYear < new Date().getFullYear() && (
          <div className="mx-4 mt-4 flex items-center gap-3 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <svg className="h-5 w-5 text-blue-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-sm text-blue-700 dark:text-blue-300">
              Estás viendo aranceles del año <strong>{academicYear}</strong>. Estos datos son solo de consulta.
            </p>
            <button
              onClick={() => setAcademicYear(new Date().getFullYear())}
              className="ml-auto text-sm font-medium text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-200 whitespace-nowrap"
            >
              Volver a {new Date().getFullYear()} →
            </button>
          </div>
        )}

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
            {!isReadOnly && (
              <Button onClick={() => setIsRegisterModalOpen(true)} className="flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                  <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48Zm0,144H32V64H224V192ZM64,104a8,8,0,0,1,8-8H96a8,8,0,0,1,0,16H72A8,8,0,0,1,64,104Zm128,48a8,8,0,0,1-8,8H72a8,8,0,0,1,0-16H184A8,8,0,0,1,192,152Z" />
                </svg>
                Registrar Pago
              </Button>
            )}
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
              
              {/* Load More Button disabled to fix search and filter conflicts */}
              {/* 
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
              */}
              
              {/* Performance info for debugging */}
              {import.meta.env.DEV && (
                <div className="text-xs text-gray-500 mt-2 text-center">
                  Mostrando todos los {payments.length} registros (filtros aplicados: {filteredPayments.length})
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
          onSuccess={() => setSelectedPayment(null)}
        />
      )}
      
      <RegisterPaymentModal
        isOpen={isRegisterModalOpen}
        onClose={() => setIsRegisterModalOpen(false)}
        onSuccess={() => setIsRegisterModalOpen(false)}
      />
    </main>
  );
}