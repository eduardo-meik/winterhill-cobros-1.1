# 📊 EVALUACIÓN EXHAUSTIVA: Libro de Matrícula - Reporte Excel

**Fecha:** 19 de diciembre de 2025  
**Objetivo:** Generar reporte Excel del Libro de Matrícula con datos completos de estudiantes y apoderados

---

## 1️⃣ VERIFICACIÓN DE ESTADO: PRE_MATRICULADO

### ✅ **SOLUCIÓN IMPLEMENTADA:**

Se agregó el estado `PRE_MATRICULADO` mediante la migración `20251219_add_pre_matriculado_estado.sql`.

Estados válidos actualizados:
```sql
CHECK (estado_std IN ('PRE_MATRICULADO','MATRICULADO','ACTIVO','RETIRADO'))
```

### **Flujo de Estados Correcto:**

```
Estudiante Nuevo (dic 8+)
    ↓
[Proceso de matrícula completado]
    ↓
Estado: PRE_MATRICULADO ← Libro de Matrícula se genera con estos estudiantes
    ↓
[Inicio año escolar - MARZO más cercano]
    ↓
Estado: MATRICULADO (Confirmado para el año escolar)
    ↓
[Durante el año escolar]
    ↓
Estado: ACTIVO (Estudiante cursando)
```

### 🔍 **Query de verificación sugerida:**

```sql
-- Verificar estudiantes matriculados desde dic 8, 2025
SELECT 
  s.id,
  s.first_name,
  s.last_name,
  s.run,
  s.estado_std,
  s.created_at,
  s.fecha_matricula
FROM public.students s
WHERE s.created_at >= '2025-12-08'
   OR s.fecha_matricula >= '2025-12-08'
ORDER BY s.created_at DESC;
```

### 📋 **Cambios Aplicados:**

✅ **Migración creada:** `20251219_add_pre_matriculado_estado.sql`
- Agregado estado `PRE_MATRICULADO` al constraint
- Actualización automática de estudiantes desde dic 8, 2025 → `PRE_MATRICULADO`
- Documentación del flujo de estados en comentarios SQL

✅ **Script de promoción:** `PROMOTE_STUDENTS_TO_MATRICULADO.sql`
- Para ejecutar en MARZO de cada año escolar
- Promueve estudiantes de `PRE_MATRICULADO` → `MATRICULADO`

---

## 2️⃣ MAPEO DE VARIABLES: DB → Excel

### 📋 **Esquema de la Base de Datos:**

#### **Tabla: `students`**
- `id`, `created_at`, `updated_at`
- `first_name`, `last_name`, `run`
- `date_of_birth`, `grade`, `email`
- `nivel`, `curso` (FK a `cursos`)
- `n_inscripcion`, `fecha_matricula`
- `nombre_social`, `genero`
- `nacionalidad`
- `fecha_incorporacion`, `fecha_retiro`, `motivo_retiro`
- `repite_curso_actual`, `institucion_procedencia`
- `direccion`, `comuna`, `con_quien_vive`
- `estado_std` (PRE_MATRICULADO, MATRICULADO, ACTIVO, RETIRADO)

#### **Tabla: `guardians`**
- `id`, `created_at`, `updated_at`
- `first_name`, `last_name`, `run`
- `email`, `phone`, `address`, `comuna`
- `nacionalidad`, `profesion`, `estado_civil`
- `relationship_type` (Padre, Madre, Tutor)

#### **Tabla: `student_guardian`** (relación N:N)
- `student_id`, `guardian_id`
- `is_primary`, `role` (apoderado titular/suplente)

#### **Tabla: `cursos`**
- `id`, `nom_curso`, `nivel`, `letra_curso`, `year_academico`

---

## 3️⃣ PROPUESTA DE MAPEO: Columnas Excel → DB

| # | Columna Excel | Campo DB | Tabla | Transformación/Notas |
|---|---------------|----------|-------|----------------------|
| 1 | **Nivel** | `cursos.nivel` | cursos | Via `students.curso` |
| 2 | **Curso** | `cursos.nom_curso` | cursos | Ej: "1° básico A" |
| 3 | **Nombres** | `students.first_name` | students | - |
| 4 | **Apellido Paterno** | `students.last_name` | students | Split si tiene 2 apellidos |
| 5 | **Apellido Materno** | `students.last_name` | students | Split si tiene 2 apellidos |
| 6 | **Run estudiante** | `students.run` | students | Formato: XX.XXX.XXX-X |
| 7 | **Fecha Nac Estudiante** | `students.date_of_birth` | students | Formato: DD/MM/YYYY |
| 8 | **Nacionalidad** | `students.nacionalidad` | students | Default: "CHILENA" |
| 9 | **Género Estudiante** | `students.genero` | students | MASCULINO/FEMENINO |
| 10 | **¿Con quién vive el estudiante?** | `students.con_quien_vive` | students | - |
| 11 | **Dirección Estudiante** | `students.direccion` | students | - |
| 12 | **Comuna** | `students.comuna` | students | - |
| 13 | **¿El estudiante repite el curso actual?** | `students.repite_curso_actual` | students | Sí/No |
| 14 | **¿Cuál es la institución de procedencia del estudiante?** | `students.institucion_procedencia` | students | - |
| 15 | **¿Cuál es el nombre del apoderado?** | `guardians.first_name` | guardians | PRIMARY guardian |
| 16 | **¿Cuál es el apellido paterno del apoderado?** | `guardians.last_name` | guardians | Split si tiene 2 apellidos |
| 17 | **¿Cuál es el apellido materno del apoderado?** | `guardians.last_name` | guardians | Split si tiene 2 apellidos |
| 18 | **¿Cuál es su relación con el estudiante?** | `guardians.relationship_type` | guardians | Padre/Madre/Tutor |
| 19 | **Fecha nacimiento apoderado** | ❌ **NO EXISTE** | - | **Campo faltante en DB** |
| 20 | **¿Cuál es el RUT del apoderado?** | `guardians.run` | guardians | Formato: XX.XXX.XXX-X |
| 21 | **¿Cuál es el nivel educacional del apoderado?** | ❌ **NO EXISTE** | - | **Campo faltante en DB** |
| 22 | **¿Cuál es la dirección de residencia del apoderado?** | `guardians.address` | guardians | - |
| 23 | **¿Cuál es la comuna de residencia del apoderado?** | `guardians.comuna` | guardians | - |
| 24 | **¿Cuál es el email de contacto del apoderado?** | `guardians.email` | guardians | - |
| 25 | **¿Cuál es su teléfono?** | `guardians.phone` | guardians | - |
| 26 | **Apoderado Secundario** | `guardians.first_name + last_name` | guardians | WHERE `is_primary = false` |
| 27 | **Rut apoderado secundario** | `guardians.run` | guardians | Secondary guardian |
| 28 | **Fecha Nacimiento** | ❌ **NO EXISTE** | - | **Campo faltante en DB** |
| 29 | **Añada el teléfono del contacto distinto al apoderado si fuese el caso** | `guardians.phone` | guardians | Secondary guardian |
| 30 | **mail apoderado secundario** | `guardians.email` | guardians | Secondary guardian |
| 31 | **fecha de retiro del estudiante** | `students.fecha_retiro` | students | Formato: DD/MM/YYYY |
| 32 | **motivo del retiro del estudiante** | `students.motivo_retiro` | students | - |
| 33 | **CONDICION** | `students.estado_std` | students | PRE_MATRICULADO/MATRICULADO/ACTIVO/RETIRADO |

---

## 4️⃣ CAMPOS FALTANTES EN LA BASE DE DATOS

### ❌ **Tabla `guardians` - Campos NO disponibles:**

1. **`fecha_nacimiento`** (Fecha nacimiento apoderado)
   - **Recomendación:** Agregar columna `date_of_birth DATE`

2. **`nivel_educacional`** (Nivel educacional del apoderado)
   - **Recomendación:** Agregar columna `nivel_educacional VARCHAR(100)`
   - **Valores sugeridos:** 
     - "Educación Básica Incompleta"
     - "Educación Básica Completa"
     - "Educación Media Incompleta"
     - "Educación Media Completa"
     - "Técnica Incompleta"
     - "Técnica Completa"
     - "Universitaria Incompleta"
     - "Universitaria Completa"
     - "Postgrado"

### ⚠️ **Campos que requieren procesamiento:**

1. **Apellidos separados (Paterno/Materno):**
   - Actualmente: `first_name`, `last_name` (un solo campo)
   - Se requiere: Split de `last_name` en 2 apellidos
   - **Recomendación:** Agregar columnas `apellido_paterno` y `apellido_materno` tanto en `students` como en `guardians`

2. **Comuna del apoderado:**
   - Actualmente: `guardians.address` (dirección completa)
   - Se requiere: Agregar `guardians.comuna VARCHAR(100)`

---

## 5️⃣ PLAN DE IMPLEMENTACIÓN

### **Fase 1: Preparación de la Base de Datos** 🔧

#### **Migración 1: Agregar estado PRE_MATRICULADO**
```sql
-- Archivo: 20251219_add_pre_matriculado_estado.sql
ALTER TABLE public.students
  DROP CONSTRAINT IF EXISTS students_estado_std_check;

ALTER TABLE public.students
  ADD CONSTRAINT students_estado_std_check
  CHECK (estado_std IN ('ACTIVO','RETIRADO','MATRICULADO','PRE_MATRICULADO'));

-- Actualizar estudiantes matriculados desde dic 8 a PRE_MATRICULADO
UPDATE public.students
SET estado_std = 'PRE_MATRICULADO'
WHERE (created_at >= '2025-12-08' OR fecha_matricula >= '2025-12-08')
  AND estado_std = 'MATRICULADO';
```

#### **Migración 2: Agregar campos faltantes en guardians**
```sql
-- Archivo: 20251219_add_guardian_fields_libro_matricula.sql
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS nivel_educacional VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Migrar last_name a apellido_paterno (temporal, hasta que se actualice data)
UPDATE public.guardians
SET apellido_paterno = last_name
WHERE apellido_paterno IS NULL;

COMMENT ON COLUMN public.guardians.date_of_birth IS 'Fecha de nacimiento del apoderado para Libro de Matrícula';
COMMENT ON COLUMN public.guardians.nivel_educacional IS 'Nivel educacional del apoderado (ej: Universitaria Completa)';
```

#### **Migración 3: Agregar apellidos separados en students**
```sql
-- Archivo: 20251219_add_student_apellidos_separated.sql
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS apellido_paterno VARCHAR(100),
  ADD COLUMN IF NOT EXISTS apellido_materno VARCHAR(100);

-- Migrar last_name a apellido_paterno (temporal)
UPDATE public.students
SET apellido_paterno = last_name
WHERE apellido_paterno IS NULL;
```

#### **Migración 4: Agregar comuna a guardians**
```sql
-- Archivo: 20251219_add_guardian_comuna.sql
ALTER TABLE public.guardians
  ADD COLUMN IF NOT EXISTS comuna VARCHAR(100);
```

---

### **Fase 2: Crear RPC para Generar Reporte** 📊

#### **Función SQL: `generate_libro_matricula_report`**

```sql
CREATE OR REPLACE FUNCTION public.generate_libro_matricula_report(
  p_year INTEGER DEFAULT NULL,
  p_estado VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  nivel TEXT,
  curso TEXT,
  nombres TEXT,
  apellido_paterno TEXT,
  apellido_materno TEXT,
  run_estudiante TEXT,
  fecha_nac_estudiante TEXT,
  nacionalidad TEXT,
  genero_estudiante TEXT,
  con_quien_vive TEXT,
  direccion_estudiante TEXT,
  comuna_estudiante TEXT,
  repite_curso TEXT,
  institucion_procedencia TEXT,
  nombre_apoderado TEXT,
  apellido_paterno_apoderado TEXT,
  apellido_materno_apoderado TEXT,
  relacion_apoderado TEXT,
  fecha_nac_apoderado TEXT,
  run_apoderado TEXT,
  nivel_educacional_apoderado TEXT,
  direccion_apoderado TEXT,
  comuna_apoderado TEXT,
  email_apoderado TEXT,
  telefono_apoderado TEXT,
  nombre_apoderado_secundario TEXT,
  run_apoderado_secundario TEXT,
  fecha_nac_apoderado_secundario TEXT,
  telefono_apoderado_secundario TEXT,
  email_apoderado_secundario TEXT,
  fecha_retiro TEXT,
  motivo_retiro TEXT,
  condicion TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- Curso info
    c.nivel::TEXT,
    c.nom_curso::TEXT,
    
    -- Estudiante
    s.first_name::TEXT AS nombres,
    COALESCE(s.apellido_paterno, split_part(s.last_name, ' ', 1))::TEXT,
    COALESCE(s.apellido_materno, split_part(s.last_name, ' ', 2))::TEXT,
    s.run::TEXT,
    TO_CHAR(s.date_of_birth, 'DD/MM/YYYY')::TEXT,
    UPPER(COALESCE(s.nacionalidad, 'CHILENA'))::TEXT,
    COALESCE(s.genero, '')::TEXT,
    COALESCE(s.con_quien_vive, '')::TEXT,
    COALESCE(s.direccion, '')::TEXT,
    COALESCE(s.comuna, '')::TEXT,
    CASE WHEN COALESCE(s.repite_curso_actual, 'No') ILIKE 'si%' THEN 'Sí' ELSE 'No' END::TEXT,
    COALESCE(s.institucion_procedencia, '')::TEXT,
    
    -- Apoderado principal
    COALESCE(g1.first_name, '')::TEXT,
    COALESCE(g1.apellido_paterno, split_part(g1.last_name, ' ', 1), '')::TEXT,
    COALESCE(g1.apellido_materno, split_part(g1.last_name, ' ', 2), '')::TEXT,
    COALESCE(g1.relationship_type, '')::TEXT,
    COALESCE(TO_CHAR(g1.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g1.run, '')::TEXT,
    COALESCE(g1.nivel_educacional, '')::TEXT,
    COALESCE(g1.address, '')::TEXT,
    COALESCE(g1.comuna, '')::TEXT,
    COALESCE(g1.email, '')::TEXT,
    COALESCE(g1.phone, '')::TEXT,
    
    -- Apoderado secundario
    COALESCE(g2.first_name || ' ' || g2.last_name, '')::TEXT,
    COALESCE(g2.run, '')::TEXT,
    COALESCE(TO_CHAR(g2.date_of_birth, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(g2.phone, '')::TEXT,
    COALESCE(g2.email, '')::TEXT,
    
    -- Retiro
    COALESCE(TO_CHAR(s.fecha_retiro, 'DD/MM/YYYY'), '')::TEXT,
    COALESCE(s.motivo_retiro, '')::TEXT,
    
    -- Condición
    CASE 
      WHEN s.estado_std = 'PRE_MATRICULADO' THEN 'Matrícula en proceso'
      WHEN s.estado_std = 'MATRICULADO' THEN 'Confirmado para año escolar'
      WHEN s.estado_std = 'ACTIVO' THEN 'Cursando'
      WHEN s.estado_std = 'RETIRADO' THEN 'Retirado'
      ELSE COALESCE(s.estado_std, '')
    END::TEXT
    
  FROM public.students s
  LEFT JOIN public.cursos c ON s.curso_id = c.id
  
  -- Apoderado principal
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND (sg.is_primary = true OR sg.role = 'titular')
    LIMIT 1
  ) g1 ON true
  
  -- Apoderado secundario
  LEFT JOIN LATERAL (
    SELECT g.*, sg.role
    FROM public.student_guardian sg
    JOIN public.guardians g ON sg.guardian_id = g.id
    WHERE sg.student_id = s.id
      AND sg.is_primary = false
      AND sg.role = 'suplente'
    LIMIT 1
  ) g2 ON true
  
  WHERE 
    (p_year IS NULL OR c.year_academico = p_year)
    AND (p_estado IS NULL OR s.estado_std = p_estado)
  
  ORDER BY c.nivel, c.nom_curso, s.last_name, s.first_name;
END;
$$;

COMMENT ON FUNCTION public.generate_libro_matricula_report IS 
'Genera reporte completo del Libro de Matrícula con datos de estudiantes, apoderados titular y suplente';
```

---

### **Fase 3: Crear Servicio Frontend** ⚛️

#### **Archivo: `src/services/libroMatricula.ts`**

```typescript
import { supabase } from './supabase';
import * as XLSX from 'xlsx';

export interface LibroMatriculaRow {
  nivel: string;
  curso: string;
  nombres: string;
  apellido_paterno: string;
  apellido_materno: string;
  run_estudiante: string;
  fecha_nac_estudiante: string;
  nacionalidad: string;
  genero_estudiante: string;
  con_quien_vive: string;
  direccion_estudiante: string;
  comuna_estudiante: string;
  repite_curso: string;
  institucion_procedencia: string;
  nombre_apoderado: string;
  apellido_paterno_apoderado: string;
  apellido_materno_apoderado: string;
  relacion_apoderado: string;
  fecha_nac_apoderado: string;
  run_apoderado: string;
  nivel_educacional_apoderado: string;
  direccion_apoderado: string;
  comuna_apoderado: string;
  email_apoderado: string;
  telefono_apoderado: string;
  nombre_apoderado_secundario: string;
  run_apoderado_secundario: string;
  fecha_nac_apoderado_secundario: string;
  telefono_apoderado_secundario: string;
  email_apoderado_secundario: string;
  fecha_retiro: string;
  motivo_retiro: string;
  condicion: string;
}

export async function generateLibroMatriculaReport(
  year?: number,
  estado?: string
): Promise<LibroMatriculaRow[]> {
  const { data, error } = await supabase.rpc('generate_libro_matricula_report', {
    p_year: year || null,
    p_estado: estado || null
  });

  if (error) throw error;
  return data || [];
}

export function exportToExcel(data: LibroMatriculaRow[], filename: string = 'Libro_Matricula.xlsx') {
  // Mapear a formato Excel con headers traducidos
  const excelData = data.map(row => ({
    'Nivel': row.nivel,
    'Curso': row.curso,
    'Nombres': row.nombres,
    'Apellido Paterno': row.apellido_paterno,
    'Apellido Materno': row.apellido_materno,
    'Run estudiante': row.run_estudiante,
    'Fecha Nac Estudiante': row.fecha_nac_estudiante,
    'Nacionalidad': row.nacionalidad,
    'Género Estudiante': row.genero_estudiante,
    '¿Con quién vive el estudiante?': row.con_quien_vive,
    'Dirección Estudiante': row.direccion_estudiante,
    'Comuna': row.comuna_estudiante,
    '¿El estudiante repite el curso actual?': row.repite_curso,
    '¿Cuál es la institución de procedencia del estudiante?': row.institucion_procedencia,
    '¿Cuál es el nombre del apoderado?': row.nombre_apoderado,
    '¿Cuál es el apellido paterno del apoderado?': row.apellido_paterno_apoderado,
    '¿Cuál es el apellido materno del apoderado?': row.apellido_materno_apoderado,
    '¿Cuál es su relación con el estudiante?': row.relacion_apoderado,
    'Fecha nacimiento apoderado': row.fecha_nac_apoderado,
    '¿Cuál es el RUT del apoderado?': row.run_apoderado,
    '¿Cuál es el nivel educacional del apoderado?': row.nivel_educacional_apoderado,
    '¿Cuál es la dirección de residencia del apoderado?': row.direccion_apoderado,
    '¿Cuál es la comuna de residencia del apoderado?': row.comuna_apoderado,
    '¿Cuál es el email de contacto del apoderado?': row.email_apoderado,
    '¿Cuál es su teléfono?': row.telefono_apoderado,
    'Apoderado Secundario': row.nombre_apoderado_secundario,
    'Rut apoderado secundario': row.run_apoderado_secundario,
    'Fecha Nacimiento': row.fecha_nac_apoderado_secundario,
    'Añada el teléfono del contacto distinto al apoderado si fuese el caso': row.telefono_apoderado_secundario,
    'mail apoderado secundario': row.email_apoderado_secundario,
    'fecha de retiro del estudiante': row.fecha_retiro,
    'motivo del retiro del estudiante': row.motivo_retiro,
    'CONDICION': row.condicion
  }));

  const ws = XLSX.utils.json_to_sheet(excelData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Libro Matrícula');
  
  // Auto-ajustar ancho de columnas
  const maxWidth = 50;
  const wscols = Object.keys(excelData[0] || {}).map(key => ({
    wch: Math.min(key.length + 2, maxWidth)
  }));
  ws['!cols'] = wscols;
  
  XLSX.writeFile(wb, filename);
}
```

---

### **Fase 4: Crear Componente UI** 🎨

#### **Archivo: `src/components/reports/LibroMatriculaReport.tsx`**

```tsx
import React, { useState } from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { generateLibroMatriculaReport, exportToExcel } from '../../services/libroMatricula';
import toast from 'react-hot-toast';

export function LibroMatriculaReport() {
  const [loading, setLoading] = useState(false);
  const [year, setYear] = useState<number>(new Date().getFullYear());
  const [estado, setEstado] = useState<string>('');

  const handleGenerateReport = async () => {
    try {
      setLoading(true);
      toast.loading('Generando reporte...', { id: 'libro-reporte' });
      
      const data = await generateLibroMatriculaReport(year, estado || undefined);
      
      if (!data.length) {
        toast.error('No se encontraron datos para el filtro seleccionado', { id: 'libro-reporte' });
        return;
      }
      
      exportToExcel(data, `Libro_Matricula_${year}.xlsx`);
      toast.success(`Reporte generado: ${data.length} estudiantes`, { id: 'libro-reporte' });
    } catch (error) {
      console.error('Error generando reporte:', error);
      toast.error('Error al generar el reporte', { id: 'libro-reporte' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <h2 className="text-xl font-bold">📊 Libro de Matrícula - Exportar a Excel</h2>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Año Académico</label>
            <input
              type="number"
              className="w-full border rounded px-3 py-2"
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              min={2020}
              max={2030}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Estado del Estudiante</label>
            <select
              className="w-full border rounded px-3 py-2"
              value={estado}
              onChange={(e) => setEstado(e.target.value)}
            >
              <option value="">Todos</option>
              <option value="PRE_MATRICULADO">Pre-Matriculado</option>
              <option value="MATRICULADO">Matriculado</option>
              <option value="ACTIVO">Activo</option>
              <option value="RETIRADO">Retirado</option>
            </select>
          </div>
        </div>
        
        <Button
          onClick={handleGenerateReport}
          disabled={loading}
          className="w-full"
        >
          {loading ? '⏳ Generando...' : '📥 Descargar Excel'}
        </Button>
        
        <p className="text-xs text-gray-600">
          El archivo Excel incluirá todos los datos del Libro de Matrícula según los filtros seleccionados.
        </p>
      </CardContent>
    </Card>
  );
}
```

---

## 6️⃣ SUGERENCIAS DE MEJORA

### ✨ **Mejoras Propuestas:**

1. **Validación de RUT:**
   - Agregar función de validación de RUT chileno
   - Auto-formatear RUTs en la exportación (XX.XXX.XXX-X)

2. **Generación de Nombre Completo:**
   - Crear columna computada `whole_name` en estudiantes y guardians
   - Función: `apellido_paterno + ' ' + apellido_materno + ', ' + first_name`

3. **Auditoría de Cambios:**
   - Agregar trigger para registrar cambios en `fecha_retiro` y `motivo_retiro`
   - Log de quién y cuándo cambió el estado del estudiante

4. **Campos Calculados:**
   - Edad del estudiante (calculada desde `date_of_birth`)
   - Años de permanencia en el colegio

5. **Integración con Encuesta de Matrícula:**
   - Importar datos automáticamente desde `guardian_intake` si existen
   - Sincronizar `con_quien_vive`, `institucion_procedencia`, etc.

6. **Reportes Adicionales:**
   - Reporte de estadísticas (% por género, nacionalidad, etc.)
   - Reporte de apoderados sin datos completos (data quality)

---

## 7️⃣ RESUMEN DE ARCHIVOS A CREAR

### **Migraciones SQL:**
1. `supabase/migrations/20251219_add_pre_matriculado_estado.sql`
2. `supabase/migrations/20251219_add_guardian_fields_libro_matricula.sql`
3. `supabase/migrations/20251219_add_student_apellidos_separated.sql`
4. `supabase/migrations/20251219_add_guardian_comuna.sql`
5. `supabase/migrations/20251219_create_libro_matricula_rpc.sql`

### **Frontend:**
1. `src/services/libroMatricula.ts`
2. `src/components/reports/LibroMatriculaReport.tsx`

### **Dependencias:**
- `xlsx` (ya instalado según package.json)

---

## ✅ SIGUIENTE PASO

**Espero tu confirmación para proceder con la implementación.**

¿Deseas que:
1. ✅ Implemente todas las migraciones SQL
2. ✅ Cree el servicio TypeScript
3. ✅ Cree el componente React
4. ⚠️ Aplique alguna modificación al plan propuesto

Por favor confirma o indica ajustes necesarios.
