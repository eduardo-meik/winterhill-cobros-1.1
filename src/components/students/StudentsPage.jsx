import React, { useState, useEffect, useCallback, useMemo } from 'react'; // Added useMemo
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { StudentsTable } from './StudentsTable';
import { StudentDetailsModal } from './StudentDetailsModal';
import { StudentFormModal } from './StudentFormModal';
import { supabase } from '../../services/supabase';
import { SearchBar } from './SearchBar';
import toast from 'react-hot-toast';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';

export function StudentsPage() {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
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

  // Debounce search term
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearchTerm(searchTerm), 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  // Use useCallback for fetchStudents
  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('students')
        .select(`
          *,
          cursos:curso (
            id,
            nom_curso,
            nivel,
            year_academico
          )
        `)
        .order('apellido_paterno', { ascending: true });

      if (error) throw error;
      setStudents(data || []);
      return data || [];
    } catch (error) {
      toast.error('Error al cargar los estudiantes');
      console.error('Error fetching students:', error);
      setStudents([]);
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStudents();
  }, [fetchStudents]);

  // Generate unique course names AND convenio names for filter dropdowns
  const uniqueCursos = useMemo(() =>
    [...new Set(students.map(s => s.cursos?.nom_curso).filter(Boolean))].sort(),
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
        student.cursos?.nom_curso === filters.curso;
      const statusMatch = filters.status === 'all' ||
        (filters.status === 'active' && !student.fecha_retiro) ||
        (filters.status === 'inactive' && student.fecha_retiro);
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
    fetchStudents();
  };

  const handleDetailsUpdateSuccess = async () => {
    const updatedStudentsList = await fetchStudents();
    if (selectedStudent && updatedStudentsList.length > 0) {
      const newlyUpdatedStudentData = updatedStudentsList.find(s => s.id === selectedStudent.id);
      if (newlyUpdatedStudentData) {
        setSelectedStudent(newlyUpdatedStudentData);
      } else {
        handleCloseDetailsModal();
      }
    } else {
       handleCloseDetailsModal();
    }
  };

  const handleResetFilters = () => {
    setSearchTerm('');
    setFilters({ curso: 'all', status: 'all', convenio: 'all' });
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Estudiantes</h1>
          <Button onClick={() => handleOpenFormModal(null)}>Agregar Estudiante</Button>
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
                  <option value="active">Activos</option>
                  <option value="inactive">Retirados</option>
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
                    students={paginatedItems} // Pass paginated items
                    onViewDetails={handleViewDetails}
                    onSuccess={fetchStudents}
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