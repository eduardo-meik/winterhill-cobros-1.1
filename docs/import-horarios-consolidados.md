# Importacion de horarios_consolidados.csv a Supabase

Este flujo carga docentes y su plantilla semanal desde el archivo `horarios_consolidados.csv`.

## Requisitos

- Migracion aplicada: `20260525133000_create_docentes_plantilla_horarios.sql`
- `owner_id` valido (UUID) de la gestion/institucion destino

## 1) Generar SQL de carga

```bash
node scripts/generate_horarios_consolidados_sql.cjs \
  --input "C:\\Users\\eduar\\Downloads\\horarios_consolidados.csv" \
  --owner-id "<OWNER_UUID>" \
  --output "tmp_horarios_consolidados_import.sql"
```

Salida esperada:

- `Docentes: 18`
- `Bloques horarios: 1418`

## 2) Ejecutar SQL en Supabase

Ejecuta el archivo generado en SQL Editor o vía pipeline/migracion operativa.

```sql
-- contenido de tmp_horarios_consolidados_import.sql
```

## Normalizaciones aplicadas

- `Profesor` -> `docentes.nombre_display`
- `Profesor` normalizado (sin tildes, lowercase) -> `docentes.nombre_normalizado`
- `Dia` -> `dia_semana` (Lunes=1 ... Domingo=7)
- `Actividad` -> `actividad`
- `es_lectivo` = false para actividades tipo `Sin clases`, `Permanencia`, `Almuerzo`, `Reunion`, `Consejo de Profesores`, `Depto`, `Volante`, `PIE`

## Notas

- El CSV no incluye RUT docente, por eso se carga catalogo de docentes por nombre.
- La carga es idempotente para docentes (`ON CONFLICT`) y evita duplicados de bloques (`DO NOTHING`).
- Se conserva el texto original de actividades (incluyendo curso/asignatura dentro de la descripcion).
