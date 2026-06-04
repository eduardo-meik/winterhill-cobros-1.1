import { useState, useEffect, useMemo, useRef } from 'react';
import toast from 'react-hot-toast';
import { supabase } from '../../services/supabase';
import { useAcademicYear } from '../../contexts/AcademicYearContext';

const buildDefaultFilters = (year) => ({
  status: 'all',
  guardians: [],
  courses: [],
  students: [],
  startDate: '',
  endDate: '',
  month: 'all',
  year: String(year),
});

export function useReportData() {
  const { academicYear } = useAcademicYear();
  const prevYearRef = useRef(academicYear);

  const [filters, setFilters] = useState(() => buildDefaultFilters(academicYear));
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const [guardians, setGuardians] = useState([]);
  const [courses, setCourses] = useState([]);
  const [students, setStudents] = useState([]);
  const [studentGuardianMap, setStudentGuardianMap] = useState({});
  const [activeTab, setActiveTab] = useState('payments');

  useEffect(() => {
    fetchReferenceData();
    fetchData(buildDefaultFilters(academicYear));
  }, []);

  // Re-fetch when the global academic year changes
  useEffect(() => {
    if (prevYearRef.current !== academicYear) {
      prevYearRef.current = academicYear;
      const updated = { ...filters, year: String(academicYear) };
      setFilters(updated);
      fetchData(updated);
    }
  }, [academicYear]);

  // Memoized filtered data — computed once per data/filters change instead of 8-11× per render
  const filteredData = useMemo(() => {
    const validData = data.filter(payment => payment && payment.student);
    return validData.filter(payment =>
      (filters.status === 'all' || payment.status === filters.status) &&
      (!filters.students.length ||
        (payment.student && filters.students.some(id => String(payment.student.id) === String(id)))) &&
      (!filters.courses.length ||
        filters.courses.includes(payment.student?.curso))
    );
  }, [data, filters.status, filters.students, filters.courses]);

  // MJ-03: Compute debt summary per guardian from fee data
  const guardianDebtMap = useMemo(() => {
    if (!data.length || !Object.keys(studentGuardianMap).length) return {};
    const map = {};
    const today = new Date();
    data.forEach(fee => {
      const studentId = fee.student_id || fee.student?.id;
      if (!studentId) return;
      const guardianIds = studentGuardianMap[studentId] || [];
      const amt = Number(fee.amount) || 0;
      guardianIds.forEach(gid => {
        if (!map[gid]) map[gid] = { paid: 0, pending: 0, overdue: 0, total: 0 };
        map[gid].total += amt;
        if (fee.status === 'paid') map[gid].paid += amt;
        else if (new Date(fee.due_date) < today) map[gid].overdue += amt;
        else map[gid].pending += amt;
      });
    });
    return map;
  }, [data, studentGuardianMap]);

  // Keep getFilteredData as a thin wrapper for the export handler (which passes a different dataset)
  const getFilteredData = (dataToFilter) => {
    if (dataToFilter === data) return filteredData; // reuse memo
    const validData = dataToFilter.filter(payment => payment && payment.student);
    return validData.filter(payment =>
      (filters.status === 'all' || payment.status === filters.status) &&
      (!filters.students.length ||
        (payment.student && filters.students.some(id => String(payment.student.id) === String(id)))) &&
      (!filters.courses.length ||
        filters.courses.includes(payment.student?.curso))
    );
  };

  const fetchData = async (currentFilters) => {
    try {
      setLoading(true);

      if (import.meta.env.DEV) console.log("Fetching data with filters:", JSON.stringify(currentFilters, null, 2));

      // Start building the query
      let query = supabase.from('fee').select(`
        *,
        student:students (
          id,
          first_name,
          apellido_paterno,
          apellido_materno,
          whole_name,
          run,
          curso:cursos (
            id,
            nom_curso,
            nivel
          )
        )
      `);

      // Apply direct filters
      if (currentFilters.status && currentFilters.status !== 'all') {
        query = query.eq('status', currentFilters.status);
      }

      // Year filter at DB level
      if (currentFilters.year && currentFilters.year !== 'all') {
        query = query.eq('year_academico', parseInt(currentFilters.year));
      } else {
        query = query.eq('year_academico', new Date().getFullYear());
      }

      // Date filters
      if (currentFilters.startDate) {
        query = query.gte('due_date', currentFilters.startDate);
      }

      if (currentFilters.endDate) {
        query = query.lte('due_date', currentFilters.endDate);
      }

      // Direct student filter
      if (currentFilters.students && currentFilters.students.length > 0) {
        if (import.meta.env.DEV) console.log("Raw student IDs from filters:", currentFilters.students);

        try {
          const studentIdsAsString = currentFilters.students.map(id => String(id));
          if (import.meta.env.DEV) console.log("Applying student filter to query:", {
            originalIds: currentFilters.students,
            normalizedIds: studentIdsAsString
          });
          query = query.in('student_id', studentIdsAsString);
        } catch (filterError) {
          if (import.meta.env.DEV) console.error("Error normalizing student IDs:", filterError);
        }
      }

      // Execute the base query with all possible database filters
      const { data: feesData, error: feesError } = await query;

      if (feesError) throw feesError;

      if (import.meta.env.DEV) console.log(`Initial query returned ${feesData?.length} records`);

      if (currentFilters.students && currentFilters.students.length > 0 && (!feesData || feesData.length === 0)) {
        if (import.meta.env.DEV) console.warn('No records found for selected students! Student IDs:', currentFilters.students);
      }

      if (import.meta.env.DEV && feesData && feesData.length > 0) {
        console.log('Sample fee record structure:', {
          studentId: feesData[0].student?.id,
          feeStudentId: feesData[0].student_id,
        });
      }

      // Apply post-query filters
      let result = [...feesData];

      // Apply month filter if specified
      if (currentFilters.month && currentFilters.month !== 'all') {
        result = result.filter(fee => {
          if (!fee.due_date) return false;
          const dueDate = new Date(fee.due_date);
          const month = (dueDate.getMonth() + 1).toString();
          return month === currentFilters.month;
        });
      }

      // Apply year filter if specified
      if (currentFilters.year && currentFilters.year !== 'all') {
        result = result.filter(fee => {
          if (!fee.due_date) return false;
          const dueDate = new Date(fee.due_date);
          const year = dueDate.getFullYear().toString();
          return year === currentFilters.year;
        });
      }

      // Apply guardian filter
      if (currentFilters.guardians && currentFilters.guardians.length > 0) {
        try {
          if (import.meta.env.DEV) console.log("Filtering by guardians:", currentFilters.guardians);

          let { data: guardianStudents, error: guardianStudentsError } = await supabase
            .from('student_guardian')
            .select('student_id')
            .in('guardian_id', currentFilters.guardians);

          if (guardianStudentsError) {
            console.error("Error querying student_guardian table:", guardianStudentsError);
            toast.error('Error al obtener la relación estudiante-apoderado');
          } else if (guardianStudents && guardianStudents.length > 0) {
            const studentIdsFromGuardians = guardianStudents.map(gs => String(gs.student_id));
            result = result.filter(fee => {
              if (!fee.student || typeof fee.student.id === 'undefined') return false;
              const feeStudentIdAsString = String(fee.student.id);
              return studentIdsFromGuardians.includes(feeStudentIdAsString);
            });

            if (import.meta.env.DEV) console.log(`After guardian filtering: ${result.length} records remain`);
          } else {
            if (import.meta.env.DEV) console.log('No students found for selected guardians');
            result = [];
          }
        } catch (error) {
          console.error("Error in guardian filtering:", error);
          toast.error('Error al filtrar por apoderados');
        }
      }

      // Apply course filter
      if (currentFilters.courses && currentFilters.courses.length > 0) {
        result = result.filter(fee => {
          if (!fee.student || !fee.student.curso) return false;
          return currentFilters.courses.includes(fee.student.curso);
        });

        if (import.meta.env.DEV) console.log(`After course filtering: ${result.length} records`);
      }

      if (import.meta.env.DEV) console.log(`After filtering: ${result.length} records`);
      setData(result);
    } catch (error) {
      console.error('Error fetching fees:', error);

      if (error.message && error.message.includes('network')) {
        toast.error('Error de conexión. Verifique su conexión a internet.');
      } else if (error.code === 'PGRST116') {
        toast.error('Error en los filtros aplicados. Por favor revise e intente nuevamente.');
      } else {
        toast.error('Error al cargar los aranceles');
      }
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchReferenceData = async () => {
    try {
      if (import.meta.env.DEV) console.log("Fetching reference data...");

      const [guardiansResponse, coursesResponse, studentsResponse, sgResponse] = await Promise.all([
        supabase.from('guardians').select('id, first_name, last_name, run').order('last_name', { ascending: true }),
        supabase.from('cursos').select('id, nom_curso, nivel'),
        supabase.from('students').select('id, first_name, apellido_paterno, whole_name, run'),
        supabase.from('student_guardian').select('student_id, guardian_id')
      ]);

      if (guardiansResponse.error) throw guardiansResponse.error;
      if (coursesResponse.error) throw coursesResponse.error;
      if (studentsResponse.error) throw studentsResponse.error;

      const sgMap = {};
      (sgResponse.data || []).forEach(sg => {
        if (!sgMap[sg.student_id]) sgMap[sg.student_id] = [];
        sgMap[sg.student_id].push(sg.guardian_id);
      });
      setStudentGuardianMap(sgMap);

      const processedGuardians = guardiansResponse.data.map(g => ({
        id: g.id,
        name: `${g.last_name || ''}, ${g.first_name || ''}`.trim(),
        run: g.run
      }));
      setGuardians(processedGuardians);
      setCourses(coursesResponse.data);

      const processedStudents = studentsResponse.data.map(s => ({
        id: s.id,
        name: s.whole_name || `${s.first_name || ''} ${s.apellido_paterno || ''}`.trim(),
        run: s.run
      }));
      setStudents(processedStudents);

      if (import.meta.env.DEV) console.log("Reference data loaded:", processedGuardians.length, "guardians,", coursesResponse.data.length, "courses,", processedStudents.length, "students");
    } catch (error) {
      console.error('Error fetching reference data:', error);
      toast.error('Error al cargar los datos de referencia');
    }
  };

  const handleApplyFilters = async (newFilters) => {
    const safeNewFilters = {
      ...newFilters,
      guardians: Array.isArray(newFilters.guardians) ? [...newFilters.guardians] : [],
      courses: Array.isArray(newFilters.courses) ? [...newFilters.courses] : [],
      students: Array.isArray(newFilters.students) ?
        newFilters.students.map(id => String(id)) : []
    };

    if (import.meta.env.DEV && safeNewFilters.students.length > 0) {
      console.log("Student IDs after normalization:", safeNewFilters.students);
    }

    setFilters(safeNewFilters);

    const hasChanges = Object.keys(safeNewFilters).some(key => {
      if (Array.isArray(safeNewFilters[key]) && Array.isArray(filters[key])) {
        if (safeNewFilters[key].length !== filters[key].length) return true;
        const newSet = new Set(safeNewFilters[key]);
        const currentSet = new Set(filters[key]);
        for (const item of newSet) {
          if (!currentSet.has(item)) return true;
        }
        for (const item of currentSet) {
          if (!newSet.has(item)) return true;
        }
        return false;
      }
      return safeNewFilters[key] !== filters[key];
    });

    if (import.meta.env.DEV) console.log("Has filter changes:", hasChanges);

    if (hasChanges) {
      toast.promise(
        fetchData(safeNewFilters),
        {
          loading: 'Aplicando filtros...',
          success: 'Filtros aplicados exitosamente',
          error: 'Error al aplicar filtros'
        }
      );
    } else {
      if (import.meta.env.DEV) console.log("No filter changes detected, fetching with current filters");
      await fetchData(safeNewFilters);
    }
  };

  const handleResetFilters = async () => {
    if (import.meta.env.DEV) console.log("Resetting filters to defaults");
    const defaults = buildDefaultFilters(academicYear);
    setFilters(defaults);
    setLoading(true);

    try {
      const { data: feesData, error: feesError } = await supabase
        .from('fee')
        .select(`
          *,
          student:students (
            id,
            first_name,
            apellido_paterno,
            apellido_materno,
            whole_name,
            run,
            curso:cursos (
              id,
              nom_curso,
              nivel
            )
          )
        `)
        .eq('year_academico', academicYear)
        .limit(500);

      if (feesError) throw feesError;

      setData(feesData || []);
      if (import.meta.env.DEV) console.log(`Reset successful. Loaded ${feesData?.length || 0} fee records`);
      toast.success('Filtros restablecidos exitosamente');
    } catch (error) {
      console.error('Error resetting filters:', error);
      toast.error('Error al restablecer los filtros');
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  return {
    filters,
    setFilters,
    loading,
    data,
    filteredData,
    guardians,
    courses,
    students,
    guardianDebtMap,
    activeTab,
    setActiveTab,
    getFilteredData,
    handleApplyFilters,
    handleResetFilters,
  };
}
