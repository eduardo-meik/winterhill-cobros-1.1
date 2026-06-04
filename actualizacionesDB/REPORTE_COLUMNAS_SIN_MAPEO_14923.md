# Reporte de columnas sin mapeo preciso a la base de datos

Archivo analizado: 14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx

## Criterio usado

Una columna queda en este reporte si ocurre al menos una de estas condiciones:

- no existe una columna actual con semántica equivalente en la base
- existe una columna parecida, pero mezclarla produciría ambigüedad funcional
- el dato pertenece mejor a una relación anual o a metadatos del proceso, no al maestro del estudiante o apoderado

## Resumen ejecutivo

- Hoja Estudiantes: 25 columnas sin mapeo preciso.
- Hoja Apoderados: 14 columnas sin mapeo preciso.
- Hay 3 salidas recomendadas según el caso:
  - no persistir, porque es redundante o no aporta valor operacional
  - guardar temporalmente en enrollments.meta si solo se quiere conservar trazabilidad del origen
  - crear una columna nueva si el dato tendrá uso operativo, filtros, reportes o validaciones

## Reglas generales de diseño

- No reutilizar students.nivel para Nivel Educativo del Excel. Hoy se usa pegado al curso y no representa exactamente Enseñanza Básica o Educación Media H-C Niños.
- No reutilizar students.n_inscripcion para N° Lista. Son conceptos distintos.
- No reutilizar student_guardian.guardian_role para Madre, Padre o Tutor. Ese campo ya tiene otros usos en el repo.
- Si un dato pertenece al proceso anual de matrícula y no al maestro del alumno, priorizar enrollments.meta antes de abrir nuevas columnas en students o guardians.

## Hoja Estudiantes

Total registros: 431

| Columna Excel | Cobertura | Por qué no tiene mapeo preciso hoy | Campo existente reutilizable | Nombre recomendado si se crea | Recomendación |
| --- | --- | --- | --- | --- | --- |
| RBD | 431/431 | Es metadato del establecimiento, no del alumno. | enrollments.meta.rbd | schools.rbd | No crear en students. Si solo quieres trazabilidad del archivo, guardar en enrollments.meta. |
| Colegio | 431/431 | Es nombre institucional, no atributo del alumno. | enrollments.meta.colegio | schools.nombre | No crear en students. Si el sistema seguirá siendo monocoelgio, no persistir. |
| Local escolar | 431/431 | Parece sede o campus, no dato del alumno. | enrollments.meta.local_escolar | sedes.nombre o schools.local_escolar | Crear solo si habrá múltiples sedes. Si no, guardar en enrollments.meta o ignorar. |
| Código Nivel Educativo | 431/431 | El sistema no tiene código oficial de nivel educativo. | enrollments.meta.codigo_nivel_educativo | cursos.codigo_nivel_educativo | Si será usado en integraciones SIGE, crearlo en cursos, no en students. |
| Nivel Educativo | 431/431 | Existe nivel, pero no con esta semántica exacta. | Ninguno recomendable | cursos.nivel_educativo_nombre | No reutilizar students.nivel. Si se necesita para reportes oficiales, crear en cursos. |
| N° Lista | 422/431 | Es dato anual por curso, no atributo maestro del alumno. | Ninguno recomendable | enrollment_students.numero_lista | No reutilizar students.n_inscripcion. Si se usará, debe vivir en enrollment_students. |
| N° Matrícula | 0/431 | No viene informado en este archivo y además sería anual. | enrollments.meta.numero_matricula | enrollments.numero_matricula_oficial | No crear ahora. Si otro origen lo trae, ubicarlo en enrollments. |
| Origen indígena | 56/431 | No existe columna equivalente. Además es categórico, no solo sí/no. | Ninguno | students.origen_indigena | Crear como text si será parte de reportes o ficha del alumno. |
| Celular estudiante | 423/431 | students no tiene teléfono. | Ninguno claro | students.phone | Crear solo si realmente se contactará al alumno; si no, priorizar teléfono del apoderado. |
| PIE | 431/431 | No existe bandera PIE en students. | Ninguno | students.pie | Crear como boolean si tendrá uso pedagógico o de reportabilidad. |
| Necesidades educativas especiales tipo | 105/431 | No existe columna para clasificación NEE. | Ninguno | students.nee_tipo | Crear como text o catálogo si la escuela trabajará esto en UI o reportes. |
| Diagnóstico | 4/431 | No existe columna clínica/pedagógica equivalente. | Ninguno | students.diagnostico_nee | Crear solo si hay tratamiento formal de datos sensibles. Si no, no persistir. |
| Pro-retención | 431/431 | No existe bandera equivalente. | Ninguno | students.pro_retencion | Crear como boolean solo si negocio lo usa; hoy todos los valores son NO. |
| SEP | 431/431 | students.categoria_social no es equivalencia segura. | Ninguno recomendable | students.categoria_sep | No reutilizar categoria_social. Crear solo si se definirá catálogo SEP real. |
| Ingreso año establecimiento | 103/431 | Solo trae año, pero fecha_incorporacion requiere fecha. | Ninguno recomendable | students.anio_ingreso_establecimiento | No poblar fecha_incorporacion con una fecha inventada. Crear entero si el año por sí solo importa. |
| Observaciones | 0/431 | No existe campo general en students y además viene vacío. | Ninguno | students.observaciones_matricula | No crear ahora. |
| Motivo de ingreso tardío | 9/431 | No existe campo específico. | Ninguno | students.motivo_ingreso_tardio | Crear solo si habrá seguimiento de ingresos tardíos. |
| Región | 422/431 | students guarda comuna y dirección, pero no región. | Ninguno | students.region | Crear si habrá reportes territoriales. |
| Previsión | 0/431 | No existe campo equivalente y además viene vacío. | Ninguno | students.prevision_salud | No crear ahora. |
| Grupo Sanguíneo | 0/431 | No existe campo equivalente y además viene vacío. | Ninguno | students.grupo_sanguineo | No crear ahora. |
| Estatura (cm) | 0/431 | No existe campo equivalente y además viene vacío. | Ninguno | students.estatura_cm | No crear ahora. |
| Peso (kg) | 0/431 | No existe campo equivalente y además viene vacío. | Ninguno | students.peso_kg | No crear ahora. |
| Alergias, dificultades físicas y/o cognitivas a considerar | 0/431 | No existe campo equivalente y es dato sensible. | Ninguno | students.alertas_salud | No crear ahora; si se requiere, debe ir con política explícita de acceso. |
| Estudiante en situación de embarazo | 431/431 | No existe campo equivalente y es dato sensible. | Ninguno | students.embarazo_estudiante | No crear ahora; todos los valores actuales son NO. |
| Foto | 431/431 | El archivo no trae imagen, solo indicador SI/NO. | Ninguno preciso | students.tiene_foto | Si el objetivo es solo saber si existe foto, crear boolean. Si habrá archivo real, entonces crear students.photo_url y un flujo de storage separado. |

## Hoja Apoderados

Total registros: 482

| Columna Excel | Cobertura | Por qué no tiene mapeo preciso hoy | Campo existente reutilizable | Nombre recomendado si se crea | Recomendación |
| --- | --- | --- | --- | --- | --- |
| RBD | 482/482 | Metadato institucional, no del apoderado. | enrollments.meta.rbd | schools.rbd | No crear en guardians. |
| Colegio | 482/482 | Nombre institucional, no del apoderado. | enrollments.meta.colegio | schools.nombre | No crear en guardians. |
| Local escolar | 482/482 | Es sede/campus del proceso de matrícula. | enrollments.meta.local_escolar | sedes.nombre o schools.local_escolar | Crear solo si la operación distingue sedes. |
| Código Nivel Educativo | 482/482 | No hay columna equivalente en guardians ni student_guardian. | enrollments.meta.codigo_nivel_educativo | cursos.codigo_nivel_educativo | Si se necesita, ubicarlo en cursos o meta del enrollment. |
| Nivel Educativo | 482/482 | Es metadato del estudiante/curso, no del apoderado. | enrollments.meta.nivel_educativo | cursos.nivel_educativo_nombre | No crear en guardians. |
| N° Lista | 473/482 | Dato anual del alumno en su curso. | Ninguno recomendable | enrollment_students.numero_lista | No reutilizar en guardians. Si se necesita, crear en enrollment_students. |
| N° Matrícula | 0/482 | No viene informado y además sería anual. | enrollments.meta.numero_matricula | enrollments.numero_matricula_oficial | No crear ahora. |
| Registro en Kimche Familia | 482/482 | No hay bandera equivalente. claim_token o claimed_at no significan lo mismo. | Ninguno recomendable | guardians.registrado_kimche | Crear boolean si el dato se usará operativamente. |
| Puede retirar al estudiante | 482/482 | is_primary no significa permiso de retiro. | Ninguno recomendable | student_guardian.puede_retirar | Crear boolean en la relación student_guardian. |
| Contacto de emergencia | 482/482 | No hay campo equivalente. | Ninguno | student_guardian.contacto_emergencia | Crear boolean en la relación student_guardian. |
| Vive Con Estudiante | 482/482 | students.con_quien_vive es agregación final, no la relación cruda por apoderado. | students.con_quien_vive solo como derivado | student_guardian.vive_con_estudiante | Crear boolean en student_guardian y, desde ahí, derivar students.con_quien_vive. |
| Situación laboral | 329/482 | guardians.profesion no representa estado laboral. | Ninguno recomendable | guardians.situacion_laboral | Crear como text o catálogo. |
| Lugar de Trabajo | 262/482 | guardians.profesion no representa lugar o modalidad del trabajo. | Ninguno | guardians.lugar_trabajo | Crear como text. |
| Región Apoderado | 397/482 | guardians tiene comuna y address, pero no región. | Ninguno | guardians.region | Crear si se usará en reportes o formularios. |

## Recomendación de implementación por prioridad

### 1. Guardar ya, sin migración

Estos datos pueden ir a enrollments.meta si solo quieres no perder información del archivo fuente:

- rbd
- colegio
- local_escolar
- codigo_nivel_educativo
- nivel_educativo
- numero_lista
- numero_matricula

### 2. Crear primero porque sí tienen valor operativo

Priorizaría estas columnas nuevas si el objetivo es mejorar la ficha real de alumnos y apoderados:

- students.phone
- students.pie
- students.nee_tipo
- students.origen_indigena
- students.region
- students.anio_ingreso_establecimiento
- student_guardian.puede_retirar
- student_guardian.contacto_emergencia
- student_guardian.vive_con_estudiante
- guardians.registrado_kimche
- guardians.situacion_laboral
- guardians.lugar_trabajo
- guardians.region

### 3. No crear por ahora

No abriría migraciones todavía para estas columnas, porque vienen vacías o sin variación útil en este archivo:

- N° Matrícula
- Observaciones
- Previsión
- Grupo Sanguíneo
- Estatura (cm)
- Peso (kg)
- Alergias, dificultades físicas y/o cognitivas a considerar
- Estudiante en situación de embarazo

## Propuesta mínima de naming si decides migrar

### Students

- phone
- origen_indigena
- pie
- nee_tipo
- diagnostico_nee
- pro_retencion
- categoria_sep
- anio_ingreso_establecimiento
- motivo_ingreso_tardio
- region
- prevision_salud
- grupo_sanguineo
- estatura_cm
- peso_kg
- alertas_salud
- embarazo_estudiante
- tiene_foto

### Guardians

- registrado_kimche
- situacion_laboral
- lugar_trabajo
- region

### Student_guardian

- puede_retirar
- contacto_emergencia
- vive_con_estudiante

### Enrollment_students

- numero_lista

### Cursos

- codigo_nivel_educativo
- nivel_educativo_nombre

## Cierre

Si quieres minimizar cambios de esquema, la estrategia más segura es:

1. mapear lo que ya existe directamente
2. guardar metadatos institucionales en enrollments.meta
3. abrir migraciones solo para los campos con valor operativo real

La prioridad técnica más clara hoy está en los tres booleanos de student_guardian y en los campos de soporte pedagógico básico del estudiante.