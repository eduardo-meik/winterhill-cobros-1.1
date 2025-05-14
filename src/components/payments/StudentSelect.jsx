import React, { useState, useEffect, useMemo, useRef } from 'react'; // Added useRef
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import clsx from 'clsx';

// Helper function to normalize text (lowercase and remove accents)
const normalizeText = (text = '') => {
  if (!text) return '';
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
};

// Helper function to get only digits and K/k from RUN
const getRunDigitsAndK = (run = '') => {
  if (!run) return '';
  return run.replace(/[^0-9kK]/g, ""); // Keep digits and K/k
}

export function StudentSelect({ value, onChange, error }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isListOpen, setIsListOpen] = useState(false); // State to control list visibility
  const wrapperRef = useRef(null); // Ref for the component wrapper

  // --- Click Outside Handler ---
  useEffect(() => {
    function handleClickOutside(event) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setIsListOpen(false); // Close list if click is outside
      }
    }
    // Bind the event listener
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      // Unbind the event listener on clean up
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [wrapperRef]);
  // --- End Click Outside Handler ---


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

  // Filtering logic using useMemo, depends directly on searchTerm
  const filteredStudents = useMemo(() => {
    const searchNormalized = normalizeText(searchTerm);
    if (!searchNormalized && !isListOpen) { // Don't filter if list isn't open and no search term
        return []; // Or return only the selected one if needed
    }
    if (!searchNormalized) {
      return students; // Return all if search is empty
    }

    return students.filter(student => {
      const nameNormalized = normalizeText(student.whole_name);
      const runDigitsAndK = getRunDigitsAndK(student.run);
      const cursoNormalized = normalizeText(student.cursos?.nom_curso);

      const nameMatch = nameNormalized.includes(searchNormalized);
      // Check digits+K OR raw RUN
      const runMatch = runDigitsAndK.toLowerCase().includes(searchNormalized) ||
                       student.run?.toLowerCase().includes(searchNormalized);
      const cursoMatch = cursoNormalized.includes(searchNormalized);

      return nameMatch || runMatch || cursoMatch;
    });
  }, [students, searchTerm, isListOpen]); // Add isListOpen dependency

  // Find the selected student object for display purposes
  const selectedStudent = useMemo(() => students.find(s => s.id === value), [students, value]);

  // Handle selecting a student
  const handleSelectStudent = (studentId) => {
    onChange(studentId); // Update the value via the prop
    setIsListOpen(false); // Close the list
    // Optional: Clear search term after selection
    // setSearchTerm('');
  };

  return (
    // Add ref to the main wrapper div
    <div className="space-y-2 relative" ref={wrapperRef}>
      {/* Search Input */}
      <div className="relative">
        <input
          type="text"
          placeholder="Buscar por nombre, RUN o curso..."
          value={searchTerm}
          onChange={(e) => {
              setSearchTerm(e.target.value);
              if (!isListOpen) setIsListOpen(true); // Open list when typing if closed
          }}
          onFocus={() => setIsListOpen(true)} // Open list on focus
          // onBlur is handled by click outside now
          className="w-full px-4 py-2 pr-10 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
        />
        {/* Spinner/Icon remains the same */}
        <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none">
          {loading && students.length === 0 ? (
             <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-primary"></div>
          ) : (
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256" className="text-gray-400">
              <path d="M229.66,218.34l-50.07-50.06a88.11,88.11,0,1,0-11.31,11.31l50.06,50.07a8,8,0,0,0,11.32-11.32ZM40,112a72,72,0,1,1,72,72A72.08,72.08,0,0,1,40,112Z" />
            </svg>
          )}
        </div>
      </div>

      {/* Conditionally render Custom List */}
      {isListOpen && (
        <div className="absolute top-full left-0 right-0 z-10 mt-1 max-h-60 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-lg p-2 space-y-1 bg-white dark:bg-dark-card shadow-lg">
          {loading && students.length === 0 ? (
            <p className="text-gray-500 dark:text-gray-400 text-center py-4">Cargando estudiantes...</p>
          ) : filteredStudents.length === 0 ? (
            <p className="text-gray-500 dark:text-gray-400 text-center py-4">No se encontraron estudiantes con "{searchTerm}"</p>
          ) : (
            filteredStudents.map(student => (
              <div
                key={student.id}
                // Use the new handler
                onClick={() => handleSelectStudent(student.id)}
                className={clsx(
                  "flex items-center gap-3 p-2 rounded-md cursor-pointer transition-colors",
                  value === student.id
                    ? 'bg-primary/10 dark:bg-primary/20'
                    : 'hover:bg-gray-50 dark:hover:bg-dark-hover'
                )}
                role="option"
                aria-selected={value === student.id}
                tabIndex={0}
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleSelectStudent(student.id); }}
              >
                {/* Student details rendering remains the same */}
                <div>
                  <p className={clsx(
                    "text-sm font-medium",
                     value === student.id ? 'text-primary dark:text-primary-light' : 'text-gray-900 dark:text-white'
                  )}>
                    {student.whole_name || `${student.apellido_paterno}, ${student.first_name}`}
                  </p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {student.run} ({student.cursos?.nom_curso || 'Sin curso'})
                  </p>
                </div>
              </div>
            ))
          )}
        </div>
      )}
      {/* End Custom List */}

      {/* Display selected student name (optional but helpful) */}
      {selectedStudent && ( // Show always if selected, maybe hide if list is open?
         <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
           Seleccionado: {selectedStudent.whole_name} ({selectedStudent.run})
         </p>
      )}

      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
    </div>
  );
}