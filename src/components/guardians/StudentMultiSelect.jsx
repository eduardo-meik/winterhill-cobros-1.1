import React, { useState, useEffect } from 'react';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function StudentMultiSelect({ selectedIds = [], onChange, error }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchStudents();
  }, []);

  const fetchStudents = async () => {
    try {
      setLoading(true);
      const { data, error: fetchError } = await supabase
        .from('students')
        .select(`
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
        `)
        .order('apellido_paterno', { ascending: true });

      if (fetchError) throw fetchError;

      setStudents(data || []);
    } catch (fetchError) {
      console.error('Error fetching students:', fetchError);
      toast.error('Error al cargar los estudiantes');
    } finally {
      setLoading(false);
    }
  };

  const filteredStudents = students.filter(student => {
    const searchLower = searchTerm.toLowerCase();
    const wholeNameMatch = student.whole_name?.toLowerCase().includes(searchLower);
    const runMatch = student.run?.toLowerCase().includes(searchLower);
    const cursoMatch = student.cursos?.nom_curso?.toLowerCase().includes(searchLower);
    return wholeNameMatch || runMatch || cursoMatch;
  });

  const handleCheckboxChange = (studentId) => {
    const newSelectedIds = selectedIds.includes(studentId)
      ? selectedIds.filter(id => id !== studentId)
      : [...selectedIds, studentId];
    onChange(newSelectedIds);
  };

  return (
    <div className="space-y-2">
      <input
        type="text"
        placeholder="Buscar estudiante por nombre, RUN o curso..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      />
      <div className="max-h-60 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-lg p-2 space-y-2">
        {loading ? (
          <p className="text-gray-500 dark:text-gray-400 text-center py-4">Cargando estudiantes...</p>
        ) : filteredStudents.length === 0 ? (
          <p className="text-gray-500 dark:text-gray-400 text-center py-4">No se encontraron estudiantes.</p>
        ) : (
          filteredStudents.map(student => (
            <label key={student.id} className="flex items-center gap-3 p-2 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-md cursor-pointer">
              <input
                type="checkbox"
                checked={selectedIds.includes(student.id)}
                onChange={() => handleCheckboxChange(student.id)}
                className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
              />
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {student.whole_name || `${student.apellido_paterno}, ${student.first_name}`}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {student.run} ({student.cursos?.nom_curso || 'Sin curso'})
                </p>
              </div>
            </label>
          ))
        )}
      </div>

      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
    </div>
  );
}