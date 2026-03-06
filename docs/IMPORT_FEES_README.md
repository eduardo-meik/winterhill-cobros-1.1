# 📋 Importación de Cuotas (Fees) desde CSV

Sistema completo para importar cuotas de pago desde archivos CSV a la base de datos Supabase.

## 🎯 Archivos del Sistema

1. **`IMPORT_FEES_FROM_CSV.sql`** - Funciones SQL base (ejecutar primero)
2. **`generate_fee_import_sql.ps1`** - Script PowerShell generador
3. **`cuotas_importacion.csv`** - Archivo CSV con datos a importar
4. **`IMPORT_FEES_README.md`** - Este archivo (instrucciones)

## 🚀 Método Rápido: Usar Generador PowerShell

### Paso 1: Preparar CSV

Edita `cuotas_importacion.csv` con tus datos reales. El formato debe ser:

```csv
"APELLIDO PATERNO","APELLIDO MATERNO","NOMBRES","RUN","VERIFICADOR","CURSO","CUOTA"," MONTO ","FECHA","ESTADO"
"CATALÁN","VÁSQUEZ","INARA SAYEN","25372029","","3° básico A","1"," $99.324 ","05-03-2025","PAGADO"
```

**Campos importantes:**
- `RUN`: Sin puntos ni guiones (ej: `25372029`)
- `CURSO`: Nombre del curso (ej: `3° básico A`)
- `CUOTA`: Número de cuota (1-10)
- `MONTO`: Con símbolo $ y punto de miles (ej: ` $99.324 `)
- `FECHA`: Formato DD-MM-YYYY (ej: `05-03-2025`)
- `ESTADO`: `PAGADO` o `PENDIENTE`

### Paso 2: Obtener tu User ID

En Supabase SQL Editor, ejecuta:

```sql
SELECT auth.uid();
```

Copia el UUID resultado (ej: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

### Paso 3: Generar SQL

Ejecuta el generador PowerShell:

```powershell
.\generate_fee_import_sql.ps1 -CsvPath "cuotas_importacion.csv" -OwnerUuid "tu-uuid-aqui"
```

Esto genera `IMPORT_FEES_GENERATED.sql` con todos tus datos.

### Paso 4: Ejecutar en Supabase

1. **Primero**: Ejecuta `IMPORT_FEES_FROM_CSV.sql` (funciones base)
2. **Segundo**: Ejecuta `IMPORT_FEES_GENERATED.sql` (tus datos)

## 📝 Método Manual: Editar SQL Directamente

Si prefieres no usar PowerShell:

### Paso 1: Ejecutar funciones base

Abre `IMPORT_FEES_FROM_CSV.sql` en Supabase SQL Editor y ejecútalo completo.

### Paso 2: Editar datos

Busca la sección `DO $$` en el archivo y cambia:

1. **Owner ID**: Reemplaza `TU_USER_ID_AQUI` con tu UUID
2. **Datos**: Agrega llamadas a `import_fee()` con tus datos

Ejemplo:

```sql
FOR v_result IN SELECT * FROM import_fee(
  '25372029',           -- RUN
  '3° básico A',        -- Curso
  1,                    -- Número de cuota
  99324,                -- Monto (sin símbolos)
  '2025-03-05'::date,   -- Fecha (YYYY-MM-DD)
  'PAGADO',             -- Estado
  v_owner_id            -- Owner ID
) LOOP
  -- Manejo de resultado...
END LOOP;
```

## 🔍 Características del Sistema

### ✅ Upsert Automático

- **Si la cuota NO existe**: Se crea nueva
- **Si la cuota YA existe**: Se actualiza con nuevos valores
- **Criterio único**: `(student_id, year_academico, numero_cuota)`

### 🔎 Búsqueda Inteligente de Estudiantes

- Normaliza RUN automáticamente (quita puntos, guiones, mayúsculas)
- Busca coincidencias exactas
- **Ejemplo**: `25.372.029-K`, `25372029K`, `25372029` → todos encuentran al mismo estudiante

### 📊 Logging Detallado

El script muestra:
- ✅ Cuotas insertadas
- 🔄 Cuotas actualizadas  
- ❌ Errores con detalles
- 📊 Total procesado

### 🛡️ Validaciones

- Estudiante debe existir (busca por RUN)
- Curso es opcional (puede ser NULL)
- Estado se convierte: `PAGADO` → `paid`, `PENDIENTE` → `pending`
- Fecha de pago solo si estado = `paid`
- Año académico se extrae de fecha de vencimiento

## 📋 Queries de Validación Post-Importación

### Ver cuotas importadas recientemente

```sql
SELECT 
  s.run,
  s.nombres,
  s.apellido_paterno,
  f.numero_cuota,
  f.amount,
  f.due_date,
  f.status,
  f.payment_date,
  c.nombre as curso,
  f.created_at
FROM fee f
JOIN students s ON f.student_id = s.id
LEFT JOIN cursos c ON f.fee_curso = c.id
ORDER BY f.created_at DESC
LIMIT 50;
```

### Resumen por estudiante

```sql
SELECT 
  s.run,
  s.nombres,
  s.apellido_paterno,
  COUNT(*) as total_cuotas,
  SUM(CASE WHEN f.status = 'paid' THEN 1 ELSE 0 END) as cuotas_pagadas,
  SUM(CASE WHEN f.status = 'pending' THEN 1 ELSE 0 END) as cuotas_pendientes,
  SUM(f.amount) as monto_total,
  SUM(CASE WHEN f.status = 'paid' THEN f.amount ELSE 0 END) as monto_pagado
FROM students s
JOIN fee f ON s.id = f.student_id
WHERE f.year_academico = 2025
GROUP BY s.id, s.run, s.nombres, s.apellido_paterno
ORDER BY s.apellido_paterno, s.nombres;
```

### Detectar duplicados (no debería haber)

```sql
SELECT 
  student_id,
  year_academico,
  numero_cuota,
  COUNT(*) as duplicados
FROM fee
GROUP BY student_id, year_academico, numero_cuota
HAVING COUNT(*) > 1;
```

### Estudiantes del CSV no encontrados

```sql
WITH csv_runs AS (
  SELECT unnest(ARRAY['25372029', '25412424', '25607211']) as run
)
SELECT 
  cr.run,
  s.id IS NULL as no_encontrado
FROM csv_runs cr
LEFT JOIN students s ON normalize_run(s.run) = normalize_run(cr.run)
WHERE s.id IS NULL;
```

## 🔧 Solución de Problemas

### Error: "Estudiante no encontrado"

**Causa**: El RUN no coincide con ningún registro en la tabla `students`

**Solución**:
1. Verifica que el estudiante existe: `SELECT * FROM students WHERE run ILIKE '%25372029%'`
2. Revisa el formato del RUN en ambas fuentes
3. Usa la query de "no encontrados" para listar todos los RUNs problemáticos

### Error: "Duplicate key value violates unique constraint"

**Causa**: Ya existe una cuota con mismo `student_id + year_academico + numero_cuota`

**Solución**:
- El script hace UPSERT automático, esto NO debería ocurrir
- Si ocurre, verifica que ejecutaste primero `IMPORT_FEES_FROM_CSV.sql`
- O usa `UPDATE` manual en lugar de `INSERT`

### Warning: "Curso no encontrado"

**Causa**: El nombre del curso no coincide exactamente

**Solución**:
- Esto es solo un warning, la cuota se crea igual (con `fee_curso = NULL`)
- Para corregir, ejecuta:
  ```sql
  UPDATE fee 
  SET fee_curso = (SELECT id FROM cursos WHERE nombre ILIKE '%3° básico A%' LIMIT 1)
  WHERE notes LIKE '%Cuota 1%' AND fee_curso IS NULL;
  ```

## 📚 Estructura de Base de Datos

### Tabla `fee`

```sql
CREATE TABLE fee (
  id uuid PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  student_id uuid NOT NULL REFERENCES students(id),
  guardian_id uuid REFERENCES guardians(id),
  amount numeric NOT NULL,
  due_date date NOT NULL,
  payment_date date,
  status text DEFAULT 'pending',  -- 'paid', 'pending', 'overdue'
  payment_method text,             -- 'efectivo', 'transferencia', 'tarjeta', 'cheque'
  num_boleta text,
  mov_bancario text,
  notes text,
  owner_id uuid NOT NULL REFERENCES auth.users(id),
  fee_curso uuid REFERENCES cursos(id),
  numero_cuota numeric,
  institucion_financiera text,
  year_academico integer NOT NULL,
  enrollment_id uuid REFERENCES enrollments(id),
  meta jsonb DEFAULT '{}'::jsonb,
  
  -- Constraint único: un estudiante no puede tener 2 cuotas #1 del mismo año
  CONSTRAINT ux_fee_student_year_cuota UNIQUE (student_id, year_academico, numero_cuota)
);
```

## 💡 Tips y Mejores Prácticas

1. **Prueba primero con pocos registros**: Edita el CSV con solo 3-5 líneas para probar
2. **Verifica el owner_id**: Usa `SELECT auth.uid()` para obtener el correcto
3. **Backup antes de ejecutar**: Haz backup de la tabla `fee` si ya tiene datos
4. **Revisa logs**: El script muestra detalles de cada operación
5. **Usa transacciones**: El script completo corre en una transacción, si falla hace rollback automático

## 📞 Soporte

Si tienes problemas:
1. Revisa la sección "Solución de Problemas"
2. Ejecuta las queries de validación
3. Verifica los logs de la ejecución SQL
4. Consulta el esquema de la base de datos en `prompt/Public_Schema_Column_Inventory.json`

---

**Última actualización**: 2025-12-29
