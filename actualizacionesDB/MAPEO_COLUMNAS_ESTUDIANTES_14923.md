# Mapeo de columnas para actualizar estudiantes

Archivo analizado: `14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx`

## Resumen

- Hoja `Estudiantes`: 431 registros de alumnos y 43 columnas.
- Hoja `Apoderados`: 482 registros y 35 columnas.
- La actualización de `students` debe hacerse sobre registros existentes, usando el RUN como clave principal.
- Este Excel no trae `owner_id`, por lo que no sirve por sí solo para inserciones ciegas en `students`.

## Clave de actualización recomendada

1. Buscar coincidencia por `students.run_numero` usando `RUN Estudiante` normalizado a solo dígitos.
2. Validar que `students.run_verificador` coincida con `Dígito verificador`.
3. Persistir también `students.run` como `RUN Estudiante-Dígito verificador`.
4. Recalcular `students.whole_name` como `Nombre Estudiante + Primer Apellido Estudiante + Segundo Apellido Estudiante`.
5. Resolver `students.curso` buscando `cursos.id` por `nom_curso = Curso` y `year_academico = Año`.

## Mapeo utilizable para `students`

| Columna Excel | Cobertura | Destino en BD | Tipo | Regla de transformación |
| --- | --- | --- | --- | --- |
| `Año` | 431/431 | auxiliar para `students.curso` | lookup | No se guarda en `students`; se usa para buscar `cursos.year_academico`. |
| `Curso` | 431/431 | `students.curso` | transformado | Buscar `cursos.id` por `cursos.nom_curso = Curso` y `cursos.year_academico = Año`. |
| `Fecha de Matrícula` | 431/431 | `students.fecha_matricula` | directo | Convertir de `DD/MM/YYYY` a `date`. |
| `RUN Estudiante` | 431/431 | `students.run_numero` | directo/clave | Guardar como numérico normalizado sin puntos ni guion. |
| `Dígito verificador` | 431/431 | `students.run_verificador` | directo/clave | Guardar como texto. |
| `RUN Estudiante` + `Dígito verificador` | 431/431 | `students.run` | derivado | Formar `RUN-DV`, por ejemplo `25938092-8`. |
| `Primer Apellido Estudiante` | 431/431 | `students.apellido_paterno` | directo | Texto tal cual, idealmente trim y uppercase consistente. |
| `Segundo Apellido Estudiante` | 431/431 | `students.apellido_materno` | directo | Texto tal cual. |
| `Nombre Estudiante` | 431/431 | `students.first_name` | directo | Mantener nombres compuestos. |
| `Nombre Estudiante` + apellidos | 431/431 | `students.whole_name` | derivado | Recomponer después de actualizar nombre y apellidos. |
| `Estado Estudiante` | 431/431 | `students.estado_std` | transformado | Mapear `Vigente -> ACTIVO` y `Retirado -> RETIRADO`. Si `Fecha de Retiro` viene informada, forzar `RETIRADO`. |
| `Fecha de Nacimiento` | 427/431 | `students.date_of_birth` | directo | Convertir de `DD/MM/YYYY` a `date`. |
| `Género` | 425/431 | `students.genero` | directo | Guardar texto normalizado, por ejemplo `Masculino` o `Femenino`. |
| `Nacionalidad` | 339/431 | `students.nacionalidad` | directo | Texto tal cual. |
| `Email Estudiante` | 426/431 | `students.email` | directo | Trim y lowercase recomendado. |
| `Repite curso actual` | 431/431 | `students.repite_curso_actual` | directo | Mantener `SI/NO` o normalizar a un catálogo único si la app ya lo exige. |
| `Comuna` | 419/431 | `students.comuna` | directo | Texto tal cual. |
| `Dirección` | 424/431 | `students.direccion` | directo | Texto tal cual. |
| `Fecha de Retiro` | 7/431 | `students.fecha_retiro` | directo | Convertir de `DD/MM/YYYY` a `date`. |
| `Razón de Retiro` | 7/431 | `students.motivo_retiro` | directo | Texto tal cual. |

## Columnas que no conviene mapear directo a `students`

| Columna Excel | Motivo |
| --- | --- |
| `RBD`, `Colegio`, `Local escolar` | Metadatos del establecimiento, no pertenecen a `students`. |
| `Código Nivel Educativo`, `Nivel Educativo` | Sirven como validación del curso, pero no tienen columna compatible en `students`. |
| `N° Lista` | Es número de lista, no corresponde de forma segura a `students.n_inscripcion`. |
| `N° Matrícula` | Viene vacío en 431/431 registros, no usable. |
| `Origen indígena` | No existe columna equivalente en `students`. |
| `Celular estudiante` | `students` no tiene campo de teléfono. |
| `PIE` | No existe columna equivalente en `students`. |
| `Necesidades educativas especiales tipo` | No existe columna equivalente en `students`. |
| `Diagnóstico` | No existe columna equivalente en `students`. |
| `Pro-retención` | No existe columna equivalente en `students`. |
| `SEP` | No tiene correspondencia clara con `students.categoria_social`; no mapear sin definición funcional explícita. |
| `Ingreso año establecimiento` | Solo trae año, pero `students.fecha_incorporacion` es `date`; requiere regla de negocio antes de poblar. |
| `Observaciones` | La hoja viene vacía en 431/431 registros. |
| `Motivo de ingreso tardío` | No tiene campo directo en `students`; podría ir a observaciones si se define esa regla. |
| `Región` | `students` no tiene campo región. |
| `Previsión`, `Grupo Sanguíneo`, `Estatura (cm)`, `Peso (kg)` | No existen columnas equivalentes en `students`. |
| `Alergias, dificultades físicas y/o cognitivas a considerar` | No existe columna equivalente en `students`. |
| `Estudiante en situación de embarazo` | No existe columna equivalente en `students`. |
| `Foto` | El Excel trae `SI/NO`, no un archivo o URL de imagen; no corresponde a un campo actual de `students`. |

## Campo `students.con_quien_vive`

La hoja `Estudiantes` no trae una columna directa para `students.con_quien_vive`, pero la hoja `Apoderados` sí permite derivarlo:

- usar filas con `Vive Con Estudiante = SI`
- tomar `Relación con el Estudiante`
- si hay más de un apoderado con `SI`, concatenar o priorizar según regla de negocio

Ese cruce requiere agregación por RUN del estudiante y no conviene mezclarlo en una actualización simple por fila.

## Reglas de normalización recomendadas

- `RUN Estudiante`: quitar puntos, espacios y guion para `run_numero`.
- `run`: recomponer siempre como `numero-dv`.
- `estado_std`: usar solo valores válidos del sistema: `ACTIVO`, `RETIRADO`, `MATRICULADO`, `PRE_MATRICULADO`.
- `curso`: nunca guardar el nombre del curso en `students`; guardar solo el UUID de `cursos.id`.
- `whole_name`: recomputar después de actualizar nombre y apellidos.
- `email`: trim y lowercase.

## Decisiones prácticas

- Para una actualización segura de estudiantes, este Excel alcanza bien para actualizar identidad, curso, estado, contacto básico, domicilio y retiro.
- No alcanza para poblar campos clínicos, sociales o administrativos que hoy no existen en `students`.
- Si se quiere aprovechar también la hoja `Apoderados`, el siguiente paso natural es generar un mapeo separado para `guardians` y `student_guardian`.