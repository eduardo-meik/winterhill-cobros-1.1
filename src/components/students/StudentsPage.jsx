import React, { useState, useEffect, useMemo } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { StudentsTable } from './StudentsTable';
import { StudentDetailsModal } from './StudentDetailsModal';
import { StudentFormModal } from './StudentFormModal';
import { SearchBar } from './SearchBar';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';
import { deriveStudentStatusFromRecord, getStudentStatusLabel } from '../../utils/studentStatus';
import { format } from 'date-fns';
import toast from 'react-hot-toast';
import { useStudentsQuery } from '../../hooks/queries/useStudentsQuery';

export function StudentsPage() {
  const { data: allStudents = [], isLoading: loading, refetch: fetchStudents } = useStudentsQuery();
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [filters, setFilters] = useState({
    curso: 'all',
    status: 'all',
    convenio: 'all',
  });
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const isReadOnly = false; // rollback de readonly para años pasados
  const [exporting, setExporting] = useState(false);

  // Debounce search term
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearchTerm(searchTerm), 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  // No filtramos por academicYear a pedido del usuario (rollback de la feature de selector de año)
  const students = useMemo(() => allStudents, [allStudents]);

  // Sync selectedStudent with latest data
  useEffect(() => {
    if (selectedStudent) {
      const updated = students.find(s => s.id === selectedStudent.id);
      if (updated) setSelectedStudent(updated);
    }
  }, [students]);

  // Generate unique course names AND convenio names for filter dropdowns
  const uniqueCursos = useMemo(() =>
    [...new Set(students.map(s => s.curso?.nom_curso).filter(Boolean))].sort(),
    [students]
  );
  const uniqueConvenios = useMemo(() =>
    [...new Set(students.map(s => s.categoria_social).filter(Boolean))].sort(),
    [students]
  );

  // Update Filtering Logic
  const filteredStudents = useMemo(() => {
    const normalizeText = (text) => text
      ?.toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "");
    const searchNormalized = normalizeText(debouncedSearchTerm);

    return students.filter(student => {
      const cursoMatch = filters.curso === 'all' ||
        student.curso?.nom_curso === filters.curso;
      const studentStatus = deriveStudentStatusFromRecord(student);
      const statusMatch = filters.status === 'all' || studentStatus === filters.status;
      const searchMatch = !debouncedSearchTerm ||
        normalizeText(student.whole_name)?.includes(searchNormalized) ||
        normalizeText(student.run)?.includes(searchNormalized);
      const convenioMatch = filters.convenio === 'all' ||
        (filters.convenio === 'Sin convenio' && !student.categoria_social) ||
        student.categoria_social === filters.convenio;

      return cursoMatch && statusMatch && convenioMatch && searchMatch;
    });
  }, [students, filters, debouncedSearchTerm]);

  // --- Add Pagination Hook ---
  const {
    currentPage,
    pageSize,
    setPageSize,
    totalPages,
    paginatedItems,
    handlePageChange
  } = usePagination(filteredStudents);
  // --- End Pagination Hook ---

  const handleViewDetails = (student) => {
    setSelectedStudent(student);
    setIsDetailsModalOpen(true);
  };

  const handleCloseDetailsModal = () => {
    setIsDetailsModalOpen(false);
    setSelectedStudent(null);
  };

  const handleOpenFormModal = (studentToEdit = null) => {
    setSelectedStudent(studentToEdit);
    setIsFormModalOpen(true);
  };

  const handleCloseFormModal = () => {
    setIsFormModalOpen(false);
    setSelectedStudent(null);
  };

  const handleFormSuccess = () => {
    handleCloseFormModal();
  };

  const handleDetailsUpdateSuccess = async () => {
    // Students cache auto-refreshes via React Query invalidation
    // selectedStudent syncs via the useEffect above
    handleCloseDetailsModal();
  };

  const handleResetFilters = () => {
    setSearchTerm('');
    setFilters({ curso: 'all', status: 'all', convenio: 'all' });
  };

  const handleExportExcel = async () => {
    try {
      setExporting(true);
      toast.loading('Exportando Excel...', { id: 'students-export' });
      const dataToExport = filteredStudents;
      const excelData = dataToExport.map(student => ({
        'Nombre': student.whole_name || `${student.first_name || ''} ${student.apellido_paterno || ''}`,
        'RUN': student.run || '-',
        'Curso': student.curso?.nom_curso || '-',
        'Año': student.curso?.year_academico || '-',
        'Estado': getStudentStatusLabel(deriveStudentStatusFromRecord(student)),
        'Convenio': student.categoria_social || 'Sin convenio',
        'G\u00e9nero': student.genero || '-',
        'Nacionalidad': student.nacionalidad || '-',
        'Direcci\u00f3n': student.direccion || '-',
        'Comuna': student.comuna || '-',
        'Fecha Matr\u00edcula': student.fecha_matricula ? format(new Date(student.fecha_matricula), 'dd/MM/yyyy') : '-',
        'Fecha Incorporaci\u00f3n': student.fecha_incorporacion ? format(new Date(student.fecha_incorporacion), 'dd/MM/yyyy') : '-',
      }));

      const ExcelJS = await import('exceljs');
      const wb = new ExcelJS.Workbook();
      const ws = wb.addWorksheet('Estudiantes');
      const headers = Object.keys(excelData[0] || {});
      ws.addRow(headers);
      excelData.forEach(row => ws.addRow(Object.values(row)));
      headers.forEach((header, index) => {
        const column = ws.getColumn(index + 1);
        const maxLength = Math.max(header.length, ...excelData.map(row => String(row[header] || '').length));
        column.width = Math.min(maxLength + 2, 50);
      });

      const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
      const buffer = await wb.xlsx.writeBuffer();
      const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `estudiantes_${timestamp}.xlsx`;
      link.click();
      window.URL.revokeObjectURL(url);
      toast.success('Archivo Excel exportado exitosamente', { id: 'students-export' });
    } catch (error) {
      console.error('Error al exportar:', error);
      toast.error('Error al exportar el archivo Excel', { id: 'students-export' });
    } finally {
      setExporting(false);
    }
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4">
          <div className="flex items-center gap-3">
            <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Estudiantes</h1>
          </div>
          <div className="flex items-center gap-2">
            <Button
              onClick={handleExportExcel}
              disabled={exporting || filteredStudents.length === 0}
              variant="outline"
              className="flex items-center gap-2"
            >
              {exporting ? 'Exportando...' : 'Exportar Excel'}
            </Button>
            {!isReadOnly && <Button onClick={() => handleOpenFormModal(null)}>Agregar Estudiante</Button>}
          </div>
        </div>

        <div className="p-4">
          <Card>
            <CardHeader>
              <div className="flex flex-wrap items-center gap-4">
                <SearchBar
                  value={searchTerm}
                  onChange={setSearchTerm}
                  isSearching={loading && debouncedSearchTerm !== ''}
                  placeholder="Buscar por nombre o RUN..."
                />
                <select
                  value={filters.curso}
                  onChange={(e) => setFilters({ ...filters, curso: e.target.value })}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                >
                  <option value="all">Todos los Cursos</option>
                  {uniqueCursos.map(curso => (
                    <option key={curso} value={curso}>{curso}</option>
                  ))}
                </select>
                <select
                  value={filters.status}
                  onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                >
                  <option value="all">Todos los Estados</option>
                  <option value="PENDIENTE">Pre-Matriculados</option>
                  <option value="ACTIVO">Confirmados</option>
                  <option value="RETIRADO">Retirados</option>
                </select>
                <select
                  value={filters.convenio}
                  onChange={(e) => setFilters({ ...filters, convenio: e.target.value })}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                >
                  <option value="all">Todos los Convenios</option>
                  <option value="Sin convenio">Sin convenio</option>
                  {uniqueConvenios.map(convenio => (
                    <option key={convenio} value={convenio}>{convenio}</option>
                  ))}
                </select>
              </div>
            </CardHeader>
            <CardContent>
              {loading && paginatedItems.length === 0 ? ( // Check paginatedItems
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
                </div>
              ) : !loading && filteredStudents.length === 0 ? ( // Check filteredStudents for no results message
                <div className="flex flex-col items-center justify-center py-8 text-gray-500 dark:text-gray-400">
                  <p>No se encontraron estudiantes que coincidan con los filtros.</p>
                  {(debouncedSearchTerm || filters.curso !== 'all' || filters.status !== 'all' || filters.convenio !== 'all') && (
                    <button
                      onClick={handleResetFilters}
                      className="mt-2 text-primary hover:text-primary-light"
                    >
                      Limpiar filtros
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <StudentsTable
                    students={paginatedItems}
                    onViewDetails={handleViewDetails}
                    onSuccess={fetchStudents}
                    isReadOnly={isReadOnly}
                  />
                  {/* --- Add Pagination Component --- */}
                  <Pagination
                    currentPage={currentPage}
                    totalPages={totalPages}
                    onPageChange={handlePageChange}
                    totalRecords={filteredStudents.length}
                    pageSize={pageSize}
                    onPageSizeChange={setPageSize}
                  />
                  {/* --- End Pagination Component --- */}
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {isDetailsModalOpen && selectedStudent && (
        <StudentDetailsModal
          student={selectedStudent}
          onClose={handleCloseDetailsModal}
          onSuccess={handleDetailsUpdateSuccess}
        />
      )}

      {isFormModalOpen && (
         <StudentFormModal
           isOpen={isFormModalOpen}
           onClose={handleCloseFormModal}
           student={selectedStudent}
           onSuccess={handleFormSuccess}
         />
      )}
    </main>
  );
}