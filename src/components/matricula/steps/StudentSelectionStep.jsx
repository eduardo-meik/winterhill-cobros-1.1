import React from 'react';
import { Card, CardContent, CardHeader } from '../../ui/Card';
import { Button } from '../../ui/Button';

/**
 * Step 0: Student selection — show associated students + enrolled students.
 *
 * @param {Object} props
 * @param {number} props.year - academic year
 * @param {Function} props.setYear - year setter
 * @param {Array} props.allMyStudents - associated students via student_guardian
 * @param {Array} props.students - currently enrolled students
 * @param {boolean} props.assistedMode - staff assisted mode
 * @param {Object|null} props.guardian - guardian record
 * @param {Function} props.handleAddStudent - add student to enrollment
 * @param {Function} props.handleRemoveStudent - remove student from enrollment
 * @param {Function} props.setStudentModalOpen - open student registration modal
 */
export function StudentSelectionStep({
  year,
  setYear,
  allMyStudents,
  students,
  assistedMode,
  guardian,
  handleAddStudent,
  handleRemoveStudent,
  setStudentModalOpen,
}) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <h2 className="font-semibold">Seleccionar Alumno y  </h2>
          <div className="flex items-center gap-2">
            <label className="text-sm"> Año:</label>
            <input
              type="number"
              value={year}
              onChange={e => setYear(Number(e.target.value))}
              className="w-28 px-2 py-1 border rounded"
            />
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid md:grid-cols-2 gap-6">
          {/* Available students */}
          <div>
            <h3 className="font-medium mb-2 text-sm">Mis Alumnos Asociados</h3>
            {assistedMode && allMyStudents.length === 0 && (
              <div className="mb-3 rounded-lg border border-yellow-200 dark:border-yellow-700 bg-yellow-50 dark:bg-yellow-900/30 p-3 text-xs text-yellow-800 dark:text-yellow-200">
                <p className="mb-2">
                  Aún no existen estudiantes vinculados a este apoderado. Regístralos para continuar con la matrícula asistida.
                </p>
                <Button size="xs" variant="outline" onClick={() => setStudentModalOpen(true)} disabled={!guardian?.id}>
                  Registrar estudiante
                </Button>
              </div>
            )}
            <ul className="space-y-1 max-h-72 overflow-auto text-sm">
              {allMyStudents.map(st => {
                const cursoLabel = st.curso_nombre || st.curso || null;
                const subtitleParts = [];
                if (st.run && st.whole_name !== st.run) subtitleParts.push(st.run);
                if (cursoLabel) subtitleParts.push(cursoLabel);
                return (
                  <li key={st.id} className="flex items-center justify-between gap-2 bg-gray-50 dark:bg-dark/40 px-2 py-1 rounded">
                    <div className="flex flex-col flex-1 min-w-0">
                      <span className="font-medium truncate">{st.whole_name || st.run}</span>
                      {subtitleParts.length > 0 && (
                        <span className="text-[11px] text-gray-500 truncate">{subtitleParts.join(' | ')}</span>
                      )}
                    </div>
                    <Button variant="outline" size="xs" onClick={() => handleAddStudent(st.id)}>
                      Agregar
                    </Button>
                  </li>
                );
              })}
              {allMyStudents.length === 0 && <li className="text-gray-500">No hay alumnos asociados</li>}
            </ul>
          </div>

          {/* Enrolled students */}
          <div>
            <h3 className="font-medium mb-2 text-sm">Alumnos en la Matrícula</h3>
            <ul className="space-y-1 max-h-72 overflow-auto text-sm">
              {students.map(st => {
                const cursoLabel = st.curso_nombre || st.curso || null;
                const subtitleParts = [];
                if (st.run && st.whole_name !== st.run) subtitleParts.push(st.run);
                if (cursoLabel) subtitleParts.push(cursoLabel);
                return (
                  <li key={st.id} className="flex items-center justify-between gap-2 bg-primary/5 dark:bg-primary/10 px-2 py-1 rounded">
                    <div className="flex flex-col flex-1 min-w-0">
                      <span className="font-medium truncate">{st.whole_name || st.run}</span>
                      {subtitleParts.length > 0 && (
                        <span className="text-[11px] text-gray-600 dark:text-gray-300 truncate">
                          {subtitleParts.join(' | ')}
                        </span>
                      )}
                    </div>
                    <Button variant="destructive" size="xs" onClick={() => handleRemoveStudent(st.id)}>
                      Quitar
                    </Button>
                  </li>
                );
              })}
              {students.length === 0 && <li className="text-gray-500">Aún no agregas alumnos</li>}
            </ul>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
