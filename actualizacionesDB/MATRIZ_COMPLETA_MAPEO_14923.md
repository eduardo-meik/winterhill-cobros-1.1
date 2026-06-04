# Matriz final Excel -> Base de datos

Archivo analizado: 14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx

## Leyenda

- `EXACTA`: la columna del Excel tiene destino claro en el esquema actual.
- `TRANSFORMADA`: existe destino claro, pero requiere normalización o conversión.
- `DERIVADA`: la columna por sí sola no se guarda, pero participa en un campo derivado.
- `LOOKUP/CONTEXTO`: se usa para localizar o validar registros, no necesariamente para persistirla en esa tabla.
- `SIN MAPEO PRECISO`: hoy no existe un destino inequívoco en la base.

## Reglas base para este archivo

- La clave principal del alumno es `students.run_numero` usando `RUN Estudiante` normalizado a solo dígitos.
- `Dígito verificador` alimenta `students.run_verificador` y junto al RUN forma `students.run`.
- El curso del alumno se resuelve contra `cursos.nom_curso`; lo que se guarda finalmente es `students.curso` con el UUID del curso.
- En apoderados, el campo principal de relación es `guardians.relationship_type`.
- `student_guardian.guardian_role` no es equivalente a `Madre`, `Padre`, `Tutor`; no debe reutilizarse para eso.

## Hoja Estudiantes

| # | Columna Excel | Estado | Destino actual o propuesto | Regla / comentario |
| --- | --- | --- | --- | --- |
| 1 | `RBD` | SIN MAPEO PRECISO | `enrollments.meta.rbd` o `schools.rbd` | Metadato institucional, no del alumno. |
| 2 | `Año` | EXACTA | `enrollments.year` | Además sirve como contexto para validar curso y cohorte. |
| 3 | `Colegio` | SIN MAPEO PRECISO | `enrollments.meta.colegio` o `schools.nombre` | No corresponde a `students`. |
| 4 | `Local escolar` | SIN MAPEO PRECISO | `enrollments.meta.local_escolar` o `sedes.nombre` | Solo crear si operan múltiples sedes. |
| 5 | `Código Nivel Educativo` | SIN MAPEO PRECISO | `cursos.codigo_nivel_educativo` | No reutilizar `students.nivel`. |
| 6 | `Nivel Educativo` | SIN MAPEO PRECISO | `cursos.nivel_educativo_nombre` | No reutilizar `students.nivel`; semántica distinta. |
| 7 | `Curso` | TRANSFORMADA | `students.curso` | Buscar `cursos.id` por `nom_curso = Curso`; el valor final guardado es UUID. |
| 8 | `N° Lista` | SIN MAPEO PRECISO | `enrollment_students.numero_lista` | No reutilizar `students.n_inscripcion`. |
| 9 | `N° Matrícula` | SIN MAPEO PRECISO | `enrollments.numero_matricula_oficial` | En este archivo viene vacío. |
| 10 | `Fecha de Matrícula` | EXACTA | `students.fecha_matricula` | Convertir `DD/MM/YYYY` a `date`. |
| 11 | `RUN Estudiante` | EXACTA | `students.run_numero` | Normalizar a solo dígitos. |
| 12 | `Dígito verificador` | EXACTA | `students.run_verificador` | Guardar como texto. |
| 11 + 12 | `RUN Estudiante` + `Dígito verificador` | DERIVADA | `students.run` | Recomponer como `numero-dv`. |
| 13 | `Primer Apellido Estudiante` | EXACTA | `students.apellido_paterno` | Trim recomendado. |
| 14 | `Segundo Apellido Estudiante` | EXACTA | `students.apellido_materno` | Trim recomendado. |
| 15 | `Nombre Estudiante` | EXACTA | `students.first_name` | Mantener nombres compuestos. |
| 13 + 14 + 15 | nombres y apellidos | DERIVADA | `students.whole_name` | Recomponer nombre completo después del update. |
| 16 | `Estado Estudiante` | TRANSFORMADA | `students.estado_std` | `Vigente -> ACTIVO`; `Retirado -> RETIRADO`. |
| 17 | `Fecha de Nacimiento` | EXACTA | `students.date_of_birth` | Convertir a `date`. |
| 18 | `Género` | EXACTA | `students.genero` | Texto normalizado. |
| 19 | `Origen indígena` | SIN MAPEO PRECISO | `students.origen_indigena` | Crear si se quiere conservar o reportar. |
| 20 | `Nacionalidad` | EXACTA | `students.nacionalidad` | Texto directo. |
| 21 | `Celular estudiante` | SIN MAPEO PRECISO | `students.phone` | Hoy `students` no tiene teléfono. |
| 22 | `Email Estudiante` | EXACTA | `students.email` | Trim y lowercase recomendados. |
| 23 | `PIE` | SIN MAPEO PRECISO | `students.pie` | Crear como boolean si tendrá uso operacional. |
| 24 | `Necesidades educativas especiales tipo` | SIN MAPEO PRECISO | `students.nee_tipo` | Crear si se gestionará en ficha o reportes. |
| 25 | `Diagnóstico` | SIN MAPEO PRECISO | `students.diagnostico_nee` | Dato sensible; crear solo con criterio de acceso. |
| 26 | `Pro-retención` | SIN MAPEO PRECISO | `students.pro_retencion` | No existe columna equivalente actual. |
| 27 | `SEP` | SIN MAPEO PRECISO | `students.categoria_sep` | No reutilizar `students.categoria_social`. |
| 28 | `Repite curso actual` | EXACTA | `students.repite_curso_actual` | Mantener `SI/NO` o normalizar. |
| 29 | `Ingreso año establecimiento` | SIN MAPEO PRECISO | `students.anio_ingreso_establecimiento` | No poblar `fecha_incorporacion` con una fecha inventada. |
| 30 | `Observaciones` | SIN MAPEO PRECISO | `students.observaciones_matricula` | En este archivo viene vacío. |
| 31 | `Motivo de ingreso tardío` | SIN MAPEO PRECISO | `students.motivo_ingreso_tardio` | Crear solo si negocio lo necesita. |
| 32 | `Región` | SIN MAPEO PRECISO | `students.region` | Hoy solo existe comuna y dirección. |
| 33 | `Comuna` | EXACTA | `students.comuna` | Texto directo. |
| 34 | `Dirección` | EXACTA | `students.direccion` | Texto directo. |
| 35 | `Previsión` | SIN MAPEO PRECISO | `students.prevision_salud` | En este archivo viene vacío. |
| 36 | `Grupo Sanguíneo` | SIN MAPEO PRECISO | `students.grupo_sanguineo` | En este archivo viene vacío. |
| 37 | `Estatura (cm)` | SIN MAPEO PRECISO | `students.estatura_cm` | En este archivo viene vacío. |
| 38 | `Peso (kg)` | SIN MAPEO PRECISO | `students.peso_kg` | En este archivo viene vacío. |
| 39 | `Alergias, dificultades físicas y/o cognitivas a considerar` | SIN MAPEO PRECISO | `students.alertas_salud` | Dato sensible; hoy viene vacío. |
| 40 | `Estudiante en situación de embarazo` | SIN MAPEO PRECISO | `students.embarazo_estudiante` | Dato sensible; hoy solo trae `NO`. |
| 41 | `Fecha de Retiro` | EXACTA | `students.fecha_retiro` | Convertir a `date`. |
| 42 | `Razón de Retiro` | EXACTA | `students.motivo_retiro` | Texto directo. |
| 43 | `Foto` | SIN MAPEO PRECISO | `students.tiene_foto` o `students.photo_url` | El archivo solo dice `SI/NO`; no trae imagen. |

## Hoja Apoderados

| # | Columna Excel | Estado | Destino actual o propuesto | Regla / comentario |
| --- | --- | --- | --- | --- |
| 1 | `RBD` | SIN MAPEO PRECISO | `enrollments.meta.rbd` o `schools.rbd` | Metadato institucional. |
| 2 | `Año` | EXACTA | `enrollments.year` | Contexto anual de matrícula. |
| 3 | `Colegio` | SIN MAPEO PRECISO | `enrollments.meta.colegio` o `schools.nombre` | No corresponde a `guardians`. |
| 4 | `Local escolar` | SIN MAPEO PRECISO | `enrollments.meta.local_escolar` o `sedes.nombre` | Solo si existe operación por sedes. |
| 5 | `Código Nivel Educativo` | SIN MAPEO PRECISO | `cursos.codigo_nivel_educativo` | Es contexto del alumno/curso, no del apoderado. |
| 6 | `Nivel Educativo` | SIN MAPEO PRECISO | `cursos.nivel_educativo_nombre` | Contexto del curso. |
| 7 | `Curso` | LOOKUP/CONTEXTO | `students.curso` | Se usa para validar el alumno; no es campo del apoderado. |
| 8 | `N° Lista` | SIN MAPEO PRECISO | `enrollment_students.numero_lista` | No es campo de `guardians`. |
| 9 | `N° Matrícula` | SIN MAPEO PRECISO | `enrollments.numero_matricula_oficial` | En este archivo viene vacío. |
| 10 | `Fecha de Matrícula` | LOOKUP/CONTEXTO | `students.fecha_matricula` | Puede validar consistencia con la hoja Estudiantes. |
| 11 | `RUN Estudiante` | LOOKUP/CONTEXTO | `students.run_numero` | Clave para localizar al alumno vinculado. |
| 12 | `Dígito verificador` | LOOKUP/CONTEXTO | `students.run_verificador` | Validación complementaria del alumno. |
| 13 | `Primer Apellido Estudiante` | LOOKUP/CONTEXTO | `students.apellido_paterno` | Solo para validación del vínculo. |
| 14 | `Segundo Apellido Estudiante` | LOOKUP/CONTEXTO | `students.apellido_materno` | Solo para validación del vínculo. |
| 15 | `Nombre Estudiante` | LOOKUP/CONTEXTO | `students.first_name` | Solo para validación del vínculo. |
| 16 | `Estado Estudiante` | LOOKUP/CONTEXTO | `students.estado_std` | Mejor tratar la hoja Estudiantes como fuente principal para este dato. |
| 17 | `RUN Apoderado` | DERIVADA | `guardians.run` | Se usa junto con el DV para recomponer el RUT completo. |
| 18 | `Dígito verificador Apoderado` | DERIVADA | `guardians.run` | Recomponer como `numero-dv`. |
| 17 + 18 | RUN apoderado + DV | TRANSFORMADA | `guardians.run` | `guardians` guarda el RUT completo, no separado. |
| 19 | `Primer Apellido Apoderado` | EXACTA | `guardians.apellido_paterno` | Además participa en `guardians.last_name`. |
| 20 | `Segundo Apellido Apoderado` | EXACTA | `guardians.apellido_materno` | Además participa en `guardians.last_name`. |
| 19 + 20 | apellidos apoderado | DERIVADA | `guardians.last_name` | Recomponer como `apellido_paterno + apellido_materno`. |
| 21 | `Nombre Apoderado` | EXACTA | `guardians.first_name` | Texto directo. |
| 22 | `Fecha de Nacimiento Apoderado` | EXACTA | `guardians.date_of_birth` | Preferir `date_of_birth` sobre `date_birth`. |
| 23 | `Email Apoderado` | EXACTA | `guardians.email` | Trim y lowercase recomendados. |
| 24 | `Teléfono Apoderado` | EXACTA | `guardians.phone` | Texto directo. |
| 25 | `Registro en Kimche Familia` | SIN MAPEO PRECISO | `guardians.registrado_kimche` | No equivale a `claim_token`, `claimed_at` o `needs_update`. |
| 26 | `Relación con el Estudiante` | EXACTA | `guardians.relationship_type` | Campo principal hoy usado por la app. Opcionalmente se puede espejar en `guardians.family_tie`. |
| 27 | `Puede retirar al estudiante` | SIN MAPEO PRECISO | `student_guardian.puede_retirar` | No equivale a `is_primary`. |
| 28 | `Contacto de emergencia` | SIN MAPEO PRECISO | `student_guardian.contacto_emergencia` | Campo relacional, no del apoderado maestro. |
| 29 | `Vive Con Estudiante` | SIN MAPEO PRECISO | `student_guardian.vive_con_estudiante` | Desde este dato se puede derivar `students.con_quien_vive`. |
| 29 derivado | convivencia final | DERIVADA | `students.con_quien_vive` | Agregar relación(es) con valor `SI`, por ejemplo `Madre`, `Padre`, `Abuela`. |
| 30 | `Último nivel educacional` | EXACTA | `guardians.nivel_educacional` | Texto directo. |
| 31 | `Situación laboral` | SIN MAPEO PRECISO | `guardians.situacion_laboral` | No equivale a `guardians.profesion`. |
| 32 | `Lugar de Trabajo` | SIN MAPEO PRECISO | `guardians.lugar_trabajo` | No equivale a `guardians.profesion`. |
| 33 | `Región Apoderado` | SIN MAPEO PRECISO | `guardians.region` | Hoy `guardians` no tiene región. |
| 34 | `Comuna Apoderado` | EXACTA | `guardians.comuna` | Texto directo. |
| 35 | `Dirección Apoderado` | EXACTA | `guardians.address` | Texto directo. |

## Derivaciones recomendadas

### Students

- `students.run` = `RUN Estudiante` + `-` + `Dígito verificador`
- `students.whole_name` = `Nombre Estudiante` + `Primer Apellido Estudiante` + `Segundo Apellido Estudiante`

### Guardians

- `guardians.run` = `RUN Apoderado` + `-` + `Dígito verificador Apoderado`
- `guardians.last_name` = `Primer Apellido Apoderado` + `Segundo Apellido Apoderado`

### Student_guardian

- `student_guardian.student_id` = alumno encontrado por RUN
- `student_guardian.guardian_id` = apoderado encontrado por RUN
- `students.con_quien_vive` = agregación de filas de apoderado con `Vive Con Estudiante = SI`

## Campos que no conviene forzar con columnas existentes

- `Nivel Educativo` no debe guardarse en `students.nivel`.
- `N° Lista` no debe guardarse en `students.n_inscripcion`.
- `Relación con el Estudiante` no debe guardarse en `student_guardian.guardian_role`.
- `Registro en Kimche Familia` no debe mapearse a `guardians.needs_update`, `claim_token` o `claimed_at`.
- `Puede retirar al estudiante` no debe mapearse a `student_guardian.is_primary`.

## Prioridad práctica de implementación

1. Importar primero todas las columnas `EXACTA` y `TRANSFORMADA`.
2. Construir después los campos `DERIVADA`.
3. Para las `SIN MAPEO PRECISO`, decidir entre:
   - guardar en `enrollments.meta`
   - abrir migración de esquema
   - descartarlas si no aportan valor real