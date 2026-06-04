# Staging seguro para actualización desde Excel 14923

Este paquete está diseñado para cumplir exactamente esta regla:

- primero `staging + diff validado`
- después, y solo después, cualquier `update` real

## Qué hace este paquete

1. Crea un schema `staging` separado de producción.
2. Crea tablas raw para importar las dos hojas del Excel.
3. Crea vistas normalizadas que resuelven RUN, fechas, curso y relaciones.
4. Crea vistas de validación para detectar problemas antes de tocar la base real.
5. Crea vistas de diff de solo lectura contra `students`, `guardians` y `student_guardian`.

## Qué NO hace este paquete

- no inserta filas en `students`
- no actualiza filas en `guardians`
- no modifica `student_guardian`
- no aplica cambios productivos automáticamente

## Orden seguro de ejecución

### 1. Crear staging y vistas base

Ejecutar:

- `actualizacionesDB/20260416_staging_matricula_14923_setup.sql`

### 2. Cargar los datos del Excel a staging

Convierte el `.xlsx` a dos CSV y cárgalos en:

- `staging.matricula_14923_estudiantes_raw`
- `staging.matricula_14923_apoderados_raw`

La carga puede hacerse por Table Editor o `COPY`, pero respeta exactamente los nombres de columnas definidos en el SQL.

### 3. Validar antes de cualquier diff

Ejecutar:

- `actualizacionesDB/20260416_staging_matricula_14923_validation.sql`

Revisar:

```sql
select *
from staging.v_matricula_14923_validation_summary
order by sheet_name, issue_code;

select *
from staging.v_matricula_14923_validation_issues
order by sheet_name, source_row_number, issue_code;
```

No avanzar a diff si hay:

- `RUN_INVALIDO`
- `STUDENT_AMBIGUOUS`
- `COURSE_AMBIGUOUS`
- `GUARDIAN_AMBIGUOUS`

## 4. Generar diff de solo lectura

Ejecutar:

- `actualizacionesDB/20260416_staging_matricula_14923_diff.sql`

Revisar:

```sql
select *
from staging.v_matricula_14923_student_diff
order by source_row_number, field_name;

select *
from staging.v_matricula_14923_guardian_diff
order by source_row_number, field_name;

select *
from staging.v_matricula_14923_student_guardian_link_diff
order by source_row_number;

select *
from staging.v_matricula_14923_diff_all
order by entity_name, source_row_number, field_name;
```

## Criterio de seguridad aplicado en el diff

El diff solo muestra cambios cuando:

- hay match único contra producción
- el valor staging ya está normalizado
- el valor staging no es `NULL`
- el valor staging difiere del actual

Eso evita el caso más peligroso de este tipo de procesos:

- sobreescribir datos productivos con vacíos del Excel

## Siguiente paso recomendado

Solo después de revisar y aprobar `staging.v_matricula_14923_diff_all`, el siguiente artefacto debería ser:

- un SQL de update generado desde esas vistas
- en lotes pequeños
- dentro de transacción
- con respaldo previo ya tomado

## SQL de apply seguro para Students y relacionados

Si el alcance aprobado excluye completamente `Matrícula`, usar:

- `actualizacionesDB/20260416_staging_matricula_14923_apply_students_guardians.sql`

Ese archivo:

- hace `preview` de cambios sobre `students`, `guardians` y `student_guardian`
- detecta conflictos si una misma entidad recibe más de un valor staging para el mismo campo
- deja un bloque `APPLY` transaccional comentado
- guarda respaldo JSON de las filas productivas antes de actualizar
- no toca `enrollments`, `enrollments.meta` ni `fee`

## Archivos del paquete

- `actualizacionesDB/20260416_staging_matricula_14923_setup.sql`
- `actualizacionesDB/20260416_staging_matricula_14923_validation.sql`
- `actualizacionesDB/20260416_staging_matricula_14923_diff.sql`
- `actualizacionesDB/20260416_staging_matricula_14923_apply_students_guardians.sql`