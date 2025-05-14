import React, { useEffect, useState } from 'react';
import { Dialog } from '@headlessui/react';
import { useForm } from 'react-hook-form';
import { Card } from '../ui/Card';
import { supabase } from '../../services/supabase';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

const defaultValues = {
  whole_name: '',
  run: '',
  date_of_birth: format(new Date(), 'yyyy-MM-dd'),
  curso: '', // Cambiado de curso_id a curso para que coincida con la columna de la BD
  email: '',
  nivel: '',
  n_inscripcion: '',
  fecha_matricula: format(new Date(), 'yyyy-MM-dd'),
  nombre_social: '',
  genero: '',
  nacionalidad: '',
  fecha_incorporacion: format(new Date(), 'yyyy-MM-dd'),
  repite_curso_actual: '',
  institucion_procedencia: '',
  direccion: '',
  comuna: '',
  con_quien_vive: ''
};

export function StudentFormModal({ isOpen, onClose, student = null, onSuccess }) {
  // Preparar los valores por defecto, asegurando que estamos usando 'curso'
  const defaultValuesWithCourse = student
    ? {
        ...student,
        // No necesitamos mapear curso_id porque ahora usamos curso directamente
      }
    : defaultValues;

  const { 
    register, 
    handleSubmit, 
    formState: { errors, isSubmitting },
    reset
  } = useForm({
    defaultValues: defaultValuesWithCourse
  });

  const [cursos, setCursos] = useState([]);

  useEffect(() => {
    const fetchCursos = async () => {
      try {
        const { data, error } = await supabase
          .from('cursos')
          .select('*')
          .order('nom_curso');
          
        if (error) throw error;
        setCursos(data);
      } catch (error) {
        console.error('Error al cargar cursos:', error);
      }
    };

    fetchCursos();
  }, []);

  const onSubmit = async (data) => {
    try {
      // Verificar si ya existe un estudiante con este RUN (solo para nuevos estudiantes)
      if (!student) { // Solo verificar para nuevos estudiantes, no para actualizaciones
        const { data: existingStudents, error: checkError } = await supabase
          .from('students')
          .select('id, whole_name')
          .eq('run', data.run);
      
        // Si hay resultados (length > 0), significa que el RUN ya existe
        if (existingStudents && existingStudents.length > 0) {
          toast.error(`Ya existe un estudiante con el RUN ${data.run}`);
          return; // Detener la ejecución para evitar el intento de inserción
        }
      }

      // Extraer first_name, apellido_paterno, etc. (código existente)
      let first_name = '';
      let apellido_paterno = '';
      let apellido_materno = '';
      if (data.whole_name) {
        const nameParts = data.whole_name.trim().split(' ');
        if (nameParts.length > 0) first_name = nameParts[0];
        if (nameParts.length > 1) apellido_paterno = nameParts[1];
        if (nameParts.length > 2) apellido_materno = nameParts.slice(2).join(' ');
        // Asegurar que no sean null si son requeridos
        if (!first_name) first_name = '(Sin nombre)';
        if (!apellido_paterno) apellido_paterno = '(Sin apellido)';
      } else {
        // Manejar caso donde whole_name está vacío si es posible
        first_name = '(Sin nombre)';
        apellido_paterno = '(Sin apellido)';
      }

      // --- Inicio de la corrección ---
      // Crear una copia de los datos para modificarla
      const dataToSend = { ...data };
      // Eliminar explícitamente la clave 'cursos' si existe.
      // Esta clave viene de la consulta con relación y no debe enviarse al guardar/actualizar.
      delete dataToSend.cursos;
      // --- Fin de la corrección ---


      // Validar que se seleccione un curso usando dataToSend
      if (!dataToSend.curso) {
        toast.error('Debe seleccionar un curso');
        return;
      }

      // Manejar el campo genero para cumplir con la restricción en la base de datos
      const genero = dataToSend.genero || null;

      // Crea un nuevo objeto con solo los campos necesarios para la BD usando dataToSend
      const formattedData = {
        whole_name: dataToSend.whole_name,
        first_name,
        apellido_paterno,
        apellido_materno: apellido_materno || null, // Asegurar null si está vacío
        run: dataToSend.run,
        date_of_birth: dataToSend.date_of_birth || format(new Date(), 'yyyy-MM-dd'),
        email: dataToSend.email || null,
        nivel: dataToSend.nivel,
        n_inscripcion: dataToSend.n_inscripcion ? parseInt(dataToSend.n_inscripcion) : null,
        fecha_matricula: dataToSend.fecha_matricula || format(new Date(), 'yyyy-MM-dd'),
        nombre_social: dataToSend.nombre_social || null,
        genero,
        nacionalidad: dataToSend.nacionalidad || null,
        fecha_incorporacion: dataToSend.fecha_incorporacion || null,
        repite_curso_actual: dataToSend.repite_curso_actual || null,
        institucion_procedencia: dataToSend.institucion_procedencia || null,
        direccion: dataToSend.direccion || null,
        comuna: dataToSend.comuna || null,
        con_quien_vive: dataToSend.con_quien_vive || null,
        // La columna en la BD es 'curso' (no 'cursos')
        curso: dataToSend.curso // Usar el valor de dataToSend
      };

      if (student) {
        // Actualizar estudiante
        const { error } = await supabase
          .from('students')
          .update({
            ...formattedData,
            updated_at: new Date().toISOString()
          })
          .eq('id', student.id);

        if (error) throw error;
        toast.success('Estudiante actualizado exitosamente');
      } else {
        // Insertar nuevo estudiante
        const { error } = await supabase
          .from('students')
          .insert([{
            ...formattedData,
            owner_id: (await supabase.auth.getUser()).data.user.id
          }]);

        if (error) throw error;
        toast.success('Estudiante registrado exitosamente');
      }

      onSuccess?.();
      reset();
      onClose();
    } catch (error) {
      console.error('Error:', error);
      // Mostrar un mensaje de error más específico si es posible
      const errorMessage = error.message?.includes("violates foreign key constraint")
        ? "Error: El curso seleccionado no es válido."
        : error.message?.includes("violates not-null constraint")
        ? "Error: Faltan campos requeridos."
        : "Error al guardar el estudiante.";
      toast.error(errorMessage);
    }
  };

  return (
    <Dialog
      open={isOpen}
      onClose={onClose}
      className="relative z-50"
    >
      <div className="fixed inset-0 bg-black/20 dark:bg-black/40" aria-hidden="true" />

      <div className="fixed inset-0 flex items-center justify-center p-4">
        {/* Apply flex column layout and max height to the panel */}
        <Dialog.Panel className="w-full max-w-2xl flex flex-col max-h-[90vh]">
          <Card className="flex flex-col flex-1 overflow-hidden"> {/* Ensure Card also flexes */}
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-gray-800 shrink-0">
              <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                {student ? 'Editar Estudiante' : 'Registrar Estudiante'}
              </Dialog.Title>
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Form Content - Make this part scrollable */}
            <form onSubmit={handleSubmit(onSubmit)} className="flex-1 overflow-y-auto p-6 space-y-6"> {/* Changed classes */}
              <div className="grid grid-cols-2 gap-6">
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nombre Completo *
                  </label>
                  <input
                    type="text"
                    {...register('whole_name', { required: 'Este campo es requerido' })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {errors.whole_name && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.whole_name.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    RUN *
                  </label>
                  <input
                    type="text"
                    {...register('run', { 
                      required: 'Este campo es requerido',
                      pattern: {
                        value: /^\d{7,8}-[\dkK]$/,
                        message: 'RUN inválido (ej: 12345678-9)'
                      }
                    })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    disabled={student && true}
                  />
                  {errors.run && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.run.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha de Nacimiento *
                  </label>
                  <input 
                    type="date"
                    {...register('date_of_birth', { 
                      required: 'Este campo es requerido',
                      validate: value => !!value || 'Este campo es requerido'
                    })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {errors.date_of_birth && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.date_of_birth.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Curso *
                  </label>
                  <select
                    {...register('curso', { required: 'Este campo es requerido' })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  >
                    <option value="">Seleccionar curso</option>
                    {cursos.map(curso => (
                      <option key={curso.id} value={curso.id}>
                        {curso.nom_curso} ({curso.year_academico || 'Sin año'})
                      </option>
                    ))}
                  </select>
                  {errors.curso && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.curso.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nivel *
                  </label>
                  <input
                    type="text"
                    {...register('nivel', { required: 'Este campo es requerido' })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {errors.nivel && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.nivel.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha de Matrícula *
                  </label>
                  <input 
                    type="date"
                    {...register('fecha_matricula', { 
                      required: 'Este campo es requerido',
                      validate: value => !!value || 'Este campo es requerido'
                    })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {errors.fecha_matricula && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.fecha_matricula.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    N° de Inscripción
                  </label>
                  <input
                    type="number"
                    {...register('n_inscripcion', {
                      setValueAs: value => value === "" ? null : parseInt(value),
                      validate: value => !value || Number.isInteger(Number(value)) || 'Debe ser un número entero'
                    })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  {errors.n_inscripcion && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.n_inscripcion.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Género
                  </label>
                  <select
                    {...register('genero')}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  >
                    <option value="">Seleccionar género</option>
                    <option value="MASCULINO">Masculino</option>
                    <option value="FEMENINO">Femenino</option>
                    <option value="NO BINARIO">No Binario</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Nacionalidad
                  </label>
                  <input
                    type="text"
                    {...register('nacionalidad')}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Fecha de Incorporación
                  </label>
                  <input 
                    type="date"
                    {...register('fecha_incorporacion', {
                      validate: value => !value || !!value || 'Fecha inválida'
                    })}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Institución de Procedencia
                  </label>
                  <input
                    type="text"
                    {...register('institucion_procedencia')}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Dirección
                  </label>
                  <input
                    type="text"
                    {...register('direccion')}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Comuna
                  </label>
                  <input
                    type="text"
                    {...register('comuna')}
                    className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                </div>
              </div>
            </form>

            {/* Footer */}
            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-100 dark:border-gray-800 shrink-0">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
              >
                Cancelar
              </button>
              <button
                type="button"
                onClick={handleSubmit(onSubmit)}
                disabled={isSubmitting}
                className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50"
              >
                {isSubmitting ? 'Guardando...' : student ? 'Guardar Cambios' : 'Registrar Estudiante'}
              </button>
            </div>
          </Card>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}