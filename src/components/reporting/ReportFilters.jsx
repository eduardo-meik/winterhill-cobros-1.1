import React, { useState, useCallback } from 'react';
import { format } from 'date-fns';
import debounce from 'lodash.debounce';
import { Combobox } from '@headlessui/react';
import { Card } from '../ui/Card';

const currentYear = new Date().getFullYear();
const years = Array.from({ length: 10 }, (_, i) => (currentYear - 5 + i).toString()); // Last 5 years + next 4 years

const months = [
  { value: '1', label: 'Enero' }, { value: '2', label: 'Febrero' },
  { value: '3', label: 'Marzo' }, { value: '4', label: 'Abril' },
  { value: '5', label: 'Mayo' }, { value: '6', label: 'Junio' },
  { value: '7', label: 'Julio' }, { value: '8', label: 'Agosto' },
  { value: '9', label: 'Septiembre' }, { value: '10', label: 'Octubre' },
  { value: '11', label: 'Noviembre' }, { value: '12', label: 'Diciembre' },
];

export function ReportFilters({ 
  filters, 
  onFiltersChange, 
  guardians = [], 
  courses = [], 
  students = [],
  onApplyFilters,
  onResetFilters,
  loading = false 
}) {
  const [localFilters, setLocalFilters] = useState(filters);
  const [guardianQuery, setGuardianQuery] = useState('');
  const [courseQuery, setCourseQuery] = useState('');
  const [studentQuery, setStudentQuery] = useState('');
  
  // Filtered lists for searchable dropdowns
  const filteredGuardians = React.useMemo(() => {
    if (!guardianQuery) return guardians;
    const query = guardianQuery.toLowerCase();
    return guardians.filter(guardian => 
      (guardian.name?.toLowerCase().includes(query)) || 
      (guardian.run?.toLowerCase().includes(query))
    );
  }, [guardians, guardianQuery]);
  
  const filteredCourses = React.useMemo(() => {
    if (!courseQuery) return courses;
    const query = courseQuery.toLowerCase();
    return courses.filter(course => 
      course.nom_curso?.toLowerCase().includes(query)
    );
  }, [courses, courseQuery]);
  
  const filteredStudents = React.useMemo(() => {
    if (!studentQuery) return students;
    const query = studentQuery.toLowerCase();
    return students.filter(student => 
      (student.name?.toLowerCase().includes(query)) || 
      (student.run?.toLowerCase().includes(query))
    );
  }, [students, studentQuery]);
  
  // Update local filters when parent filters change (for reset)
  // This is critical for the reset filters functionality
  React.useEffect(() => {
    console.log("Parent filters changed:", filters);
    // Deep copy of filters to ensure we break references
    const filtersCopy = JSON.parse(JSON.stringify(filters));
    setLocalFilters(filtersCopy);
    
    // Reset search queries when filters change
    setGuardianQuery('');
    setCourseQuery('');
    setStudentQuery('');
  }, [filters]);
  
  const debouncedFiltersChange = useCallback(
    debounce((newFilters) => {
      onFiltersChange(newFilters);
    }, 300),
    []
  );

  const handleFilterChange = (key, value) => {
    console.log(`Filter change: ${key} =`, value);
    
    // Special handling for student IDs to ensure they're strings
    if (key === 'students' && Array.isArray(value)) {
      value = value.map(id => String(id));
    }
    
    const newFilters = { ...localFilters, [key]: value };
    setLocalFilters(newFilters);
    debouncedFiltersChange(newFilters);
    
    // If it's students filter, log what was actually set
    if (key === 'students') {
      console.log("Updated students filter:", newFilters.students);
    }
  };

  return (
    <Card className="mb-6">
      <div className="p-4 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {/* Status Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Estado
            </label>
            <select
              value={localFilters.status}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Todos</option>
              <option value="paid">Pagado</option>
              <option value="pending">Pendiente</option>
              <option value="overdue">Vencido</option>
            </select>
          </div>

          {/* Month Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Mes
            </label>
            <select
              value={localFilters.month}
              onChange={(e) => handleFilterChange('month', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Todos los Meses</option>
              {months.map(month => (
                <option key={month.value} value={month.value}>{month.label}</option>
              ))}
            </select>
          </div>

          {/* Year Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Año
            </label>
            <select
              value={localFilters.year}
              onChange={(e) => handleFilterChange('year', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Todos los Años</option>
              {years.map(year => (
                <option key={year} value={year}>{year}</option>
              ))}
            </select>
          </div>

          {/* Guardian Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Apoderados
            </label>
            <Combobox
              value={localFilters.guardians || []}
              onChange={(value) => {
                console.log("Guardian selection changed to:", value);
                handleFilterChange('guardians', value);
              }}
              multiple
            >
              <div className="relative">
                <div className="flex items-center">                <Combobox.Input
                  className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  placeholder="Buscar o seleccionar apoderados..."
                  onChange={(event) => setGuardianQuery(event.target.value)}
                  displayValue={(selected) => {
                    if (!selected || selected.length === 0) return '';
                    
                    // Make sure we handle empty arrays properly - critical for reset functionality
                    if (selected.length === 0) return '';
                    
                    return selected.map(id => {
                      // Find the guardian by ID
                      const guardian = guardians.find(g => g.id === id);
                      
                      // Return guardian name if found, otherwise fallback to ID
                      return guardian ? guardian.name : id;
                    }).join(', ');
                  }}
                  onClick={(e) => {
                    e.target.select();
                    // Force show dropdown
                    e.target.click();
                  }}
                />
                  {localFilters.guardians && localFilters.guardians.length > 0 && (
                    <button
                      type="button"
                      className="absolute right-2 p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
                      onClick={() => handleFilterChange('guardians', [])}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  )}
                </div>
                <Combobox.Button className="absolute inset-y-0 right-0 flex items-center pr-2">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path fillRule="evenodd" d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </Combobox.Button>
                <Combobox.Options className="absolute z-10 w-full mt-1 bg-white dark:bg-dark-card rounded-md shadow-lg max-h-60 overflow-auto">
                  {filteredGuardians.length === 0 ? (
                    <div className="py-2 px-4 text-sm text-gray-500">
                      {guardians.length === 0 ? "No hay apoderados disponibles" : "No hay resultados para esta búsqueda"}
                    </div>
                  ) : (
                    filteredGuardians.map((guardian) => (
                      <Combobox.Option
                        key={guardian.id}
                        value={guardian.id}
                        className={({ active }) =>
                          `${active ? 'bg-primary text-white' : 'text-gray-900 dark:text-white'}
                          cursor-pointer select-none relative py-2 pl-10 pr-4`
                        }
                      >
                        {({ selected }) => (
                          <>
                            <span className={`block truncate ${selected ? 'font-medium' : 'font-normal'}`}>
                              {guardian.name} {guardian.run ? `(${guardian.run})` : ''}
                            </span>
                            {selected && (
                              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-primary-light">
                                <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                </svg>
                              </span>
                            )}
                          </>
                        )}
                      </Combobox.Option>
                    ))
                  )}
                </Combobox.Options>
              </div>
            </Combobox>
          </div>

          {/* Course Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Cursos
            </label>
            <Combobox
              value={localFilters.courses}
              onChange={(value) => handleFilterChange('courses', value)}
              multiple
            >
              <div className="relative">
                <div className="flex items-center">
                  <Combobox.Input
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    placeholder="Buscar o seleccionar cursos..."
                    onChange={(event) => setCourseQuery(event.target.value)}
                    displayValue={(selected) =>
                      selected.map(id => 
                        courses.find(c => c.id === id)?.nom_curso
                      ).join(', ')
                    }
                  />
                  {localFilters.courses && localFilters.courses.length > 0 && (
                    <button
                      type="button"
                      className="absolute right-2 p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
                      onClick={() => handleFilterChange('courses', [])}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  )}
                </div>
                <Combobox.Button className="absolute inset-y-0 right-0 flex items-center pr-2">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path fillRule="evenodd" d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </Combobox.Button>
                <Combobox.Options className="absolute z-10 w-full mt-1 bg-white dark:bg-dark-card rounded-md shadow-lg max-h-60 overflow-auto">
                  {filteredCourses.length === 0 ? (
                    <div className="py-2 px-4 text-sm text-gray-500">
                      {courses.length === 0 ? "No hay cursos disponibles" : "No hay resultados para esta búsqueda"}
                    </div>
                  ) : (
                    filteredCourses.map((course) => (
                      <Combobox.Option
                        key={course.id}
                        value={course.id}
                        className={({ active }) =>
                          `${active ? 'bg-primary text-white' : 'text-gray-900 dark:text-white'}
                          cursor-pointer select-none relative py-2 pl-10 pr-4`
                        }
                      >
                        {({ selected }) => (
                          <>
                            <span className={`block truncate ${selected ? 'font-medium' : 'font-normal'}`}>
                              {course.nom_curso}
                            </span>
                            {selected && (
                              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-primary-light">
                                <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                </svg>
                              </span>
                            )}
                          </>
                        )}
                      </Combobox.Option>
                    ))
                  )}
                </Combobox.Options>
              </div>
            </Combobox>
          </div>

          {/* Student Selector - Multiple */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Estudiantes
            </label>
            <Combobox
              value={localFilters.students || []}
              onChange={(value) => {
                console.log("Student selection changed to:", value);
                console.log("Selection data type:", typeof value, Array.isArray(value));
                if (Array.isArray(value)) {
                  console.log("First selected ID type:", typeof value[0]);
                }
                handleFilterChange('students', value);
              }}
              multiple
            >
              <div className="relative">
                <div className="flex items-center">
                  <Combobox.Input
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    placeholder="Buscar o seleccionar estudiantes..."
                    onChange={(event) => setStudentQuery(event.target.value)}
                    displayValue={(selected) => {
                      if (!selected || selected.length === 0) return '';
                      if (selected.length === 1) {
                        const student = students.find(s => s.id === selected[0]);
                        return student ? student.name : '';
                      }
                      return `${selected.length} estudiantes seleccionados`;
                    }}
                    onClick={(e) => {
                      e.target.select();
                      // Force show dropdown
                      e.target.click();
                    }}
                  />
                  {localFilters.students && localFilters.students.length > 0 && (
                    <button
                      type="button"
                      className="absolute right-2 p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
                      onClick={() => handleFilterChange('students', [])}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  )}
                </div>
                <Combobox.Button className="absolute inset-y-0 right-0 flex items-center pr-2">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path fillRule="evenodd" d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </Combobox.Button>
                <Combobox.Options className="absolute z-10 w-full mt-1 bg-white dark:bg-dark-card rounded-md shadow-lg max-h-60 overflow-auto">
                  {filteredStudents.length === 0 ? (
                    <div className="py-2 px-4 text-sm text-gray-500">
                      {students.length === 0 ? "No hay estudiantes disponibles" : "No hay resultados para esta búsqueda"}
                    </div>
                  ) : (
                    filteredStudents.map((student) => (
                      <Combobox.Option
                        key={student.id}
                        value={student.id}
                        className={({ active }) =>
                          `${active ? 'bg-primary text-white' : 'text-gray-900 dark:text-white'}
                          cursor-pointer select-none relative py-2 pl-10 pr-4`
                        }
                      >
                        {({ selected }) => (
                          <>
                            <span className={`block truncate ${selected ? 'font-medium' : 'font-normal'}`}>
                              {student.name} {student.run ? `(${student.run})` : ''}
                            </span>
                            {selected && (
                              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-primary-light">
                                <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                </svg>
                              </span>
                            )}
                          </>
                        )}
                      </Combobox.Option>
                    ))
                  )}
                </Combobox.Options>
              </div>
            </Combobox>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Date Range */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Fecha Inicio
            </label>
            <input
              type="date"
              value={localFilters.startDate}
              onChange={(e) => handleFilterChange('startDate', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Fecha Fin
            </label>
            <input
              type="date"
              value={localFilters.endDate}
              min={localFilters.startDate}
              onChange={(e) => handleFilterChange('endDate', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
        </div>

        {/* Action Buttons */}
        {/* Filter Summary */}
        <div className="px-4 mb-3 text-sm">
          {Object.entries({
            guardians: localFilters.guardians?.length || 0,
            courses: localFilters.courses?.length || 0,
            students: localFilters.students?.length || 0,
            date: localFilters.startDate || localFilters.endDate ? 1 : 0,
            month: localFilters.month !== 'all' ? 1 : 0,
            year: localFilters.year !== 'all' ? 1 : 0,
            status: localFilters.status !== 'all' ? 1 : 0,
            search: localFilters.search ? 1 : 0,
          }).reduce((total, [key, val]) => total + val, 0) > 0 ? (
            <div className="flex flex-wrap gap-2 mb-2">
              <span className="text-gray-600 dark:text-gray-300">Filtros activos:</span>
              {localFilters.status !== 'all' && (
                <span className="bg-blue-100 dark:bg-blue-800/30 text-blue-800 dark:text-blue-300 px-2 py-0.5 rounded-full text-xs">
                  Estado: {localFilters.status === 'paid' ? 'Pagado' : 
                          localFilters.status === 'pending' ? 'Pendiente' : 'Vencido'}
                </span>
              )}
              {localFilters.guardians?.length > 0 && (
                <>
                  {localFilters.guardians.map(guardianId => {
                    const guardian = guardians.find(g => g.id === guardianId);
                    if (!guardian) return null;
                    
                    return (
                      <span key={guardianId} className="bg-green-100 dark:bg-green-800/30 text-green-800 dark:text-green-300 px-2 py-0.5 rounded-full text-xs mr-1 mb-1 inline-flex items-center">
                        <span>Apoderado: {guardian.name}</span>
                        <button
                          type="button"
                          className="ml-1 p-0.5 rounded-full hover:bg-green-200 dark:hover:bg-green-700"
                          onClick={(e) => {
                            e.stopPropagation();
                            const updatedGuardians = localFilters.guardians.filter(id => id !== guardianId);
                            handleFilterChange('guardians', updatedGuardians);
                          }}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </span>
                    );
                  })}
                </>
              )}
              {localFilters.courses?.length > 0 && (
                <>
                  {localFilters.courses.map(courseId => {
                    const course = courses.find(c => c.id === courseId);
                    if (!course) return null;
                    
                    return (
                      <span key={courseId} className="bg-purple-100 dark:bg-purple-800/30 text-purple-800 dark:text-purple-300 px-2 py-0.5 rounded-full text-xs mr-1 mb-1 inline-flex items-center">
                        <span>Curso: {course.nom_curso}</span>
                        <button
                          type="button"
                          className="ml-1 p-0.5 rounded-full hover:bg-purple-200 dark:hover:bg-purple-700"
                          onClick={(e) => {
                            e.stopPropagation();
                            const updatedCourses = localFilters.courses.filter(id => id !== courseId);
                            handleFilterChange('courses', updatedCourses);
                          }}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </span>
                    );
                  })}
                </>
              )}
              {localFilters.students?.length > 0 && (
                <>
                  {localFilters.students.map(studentId => {
                    const student = students.find(s => s.id === studentId);
                    if (!student) return null;
                    
                    return (
                      <span key={studentId} className="bg-yellow-100 dark:bg-yellow-800/30 text-yellow-800 dark:text-yellow-300 px-2 py-0.5 rounded-full text-xs mr-1 mb-1 inline-flex items-center">
                        <span>Estudiante: {student.name}</span>
                        <button
                          type="button"
                          className="ml-1 p-0.5 rounded-full hover:bg-yellow-200 dark:hover:bg-yellow-700"
                          onClick={(e) => {
                            e.stopPropagation();
                            const updatedStudents = localFilters.students.filter(id => id !== studentId);
                            handleFilterChange('students', updatedStudents);
                          }}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </span>
                    );
                  })}
                </>
              )}
              {(localFilters.startDate || localFilters.endDate) && (
                <span className="bg-red-100 dark:bg-red-800/30 text-red-800 dark:text-red-300 px-2 py-0.5 rounded-full text-xs">
                  Período
                </span>
              )}
              {localFilters.month !== 'all' && (
                <span className="bg-orange-100 dark:bg-orange-800/30 text-orange-800 dark:text-orange-300 px-2 py-0.5 rounded-full text-xs">
                  Mes: {(() => {
                    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                    return months[parseInt(localFilters.month) - 1];
                  })()}
                </span>
              )}
              {localFilters.year !== 'all' && (
                <span className="bg-teal-100 dark:bg-teal-800/30 text-teal-800 dark:text-teal-300 px-2 py-0.5 rounded-full text-xs">
                  Año: {localFilters.year}
                </span>
              )}
            </div>
          ) : (
            <div className="text-gray-500 dark:text-gray-400 mb-2">No hay filtros activos</div>
          )}
        </div>

        <div className="flex justify-end gap-3 pt-4">
          <button
            type="button"
            onClick={() => {
              console.log("Reset filters button clicked");
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
              
              // Update local state immediately to provide visual feedback
              setLocalFilters(defaultFilters);
              
              // Then call the parent reset function to handle the data fetching
              // This ensures both the UI and the data are in sync
              onResetFilters();
            }}
            disabled={loading}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors disabled:opacity-50"
          >
            Limpiar Filtros
          </button>
          <button
            type="button"
            onClick={() => onApplyFilters(localFilters)}
            disabled={loading}
            className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            {loading ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Aplicando...
              </>
            ) : (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M3 3a1 1 0 011-1h12a1 1 0 011 1v3a1 1 0 01-.293.707L12 11.414V15a1 1 0 01-.293.707l-2 2A1 1 0 018 17v-5.586L3.293 6.707A1 1 0 013 6V3z" clipRule="evenodd" />
                </svg>
                Aplicar Filtros
              </>
            )}
          </button>
        </div>
      </div>
    </Card>
  );
}