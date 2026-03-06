# SOLUCIÓN TÉCNICA: ENROLLMENT ID SHARING
## Análisis del Problema

**Situación Actual:**
- Un apoderado matricula 2+ estudiantes en un solo proceso
- Todos los estudiantes comparten el mismo `enrollment_id`
- Esto es **funcionalmente correcto** desde el punto de vista de negocio
- Pero genera conflictos en queries y lógica que asume 1 enrollment = 1 estudiante

**Arquitectura Actual:**
```
enrollments (1) ←──── (N) enrollment_students (N) ────→ (1) students
    ↓
guardian_id (un apoderado matricula múltiples hijos)
```

---

## OPCIÓN 1: COMPOSITE KEY (RECOMENDADA) ✅

**Concepto:** Usar `(enrollment_id, student_id)` como identificador compuesto

### Ventajas:
- ✅ **CERO cambios en estructura de base de datos** (ya es PRIMARY KEY compuesto)
- ✅ **Mínimo impacto en código** - solo ajustar queries
- ✅ **Mantiene integridad referencial**
- ✅ **No requiere migración de datos**
- ✅ **Production-ready inmediatamente**

### Cambios Requeridos:

#### 1. **Backend: Ajustar queries que asumen 1:1**
```typescript
// ANTES (asume 1 enrollment = 1 estudiante)
const enrollment = await supabase
  .from('enrollments')
  .select('*, students(*)')
  .eq('id', enrollmentId)
  .single();

// DESPUÉS (maneja 1 enrollment = N estudiantes)
const enrollment = await supabase
  .from('enrollments')
  .select(`
    *,
    enrollment_students!inner(
      student_id,
      students(*)
    )
  `)
  .eq('id', enrollmentId);
```

#### 2. **Frontend: Mostrar múltiples estudiantes por enrollment**
```typescript
// Componente de matrícula
interface EnrollmentWithStudents {
  id: string;
  guardian_id: string;
  year: number;
  students: Student[];  // Array en vez de objeto único
}

// Render
{enrollment.students.map((student, index) => (
  <StudentCard 
    key={student.id} 
    student={student}
    enrollmentId={enrollment.id}
    position={index + 1}  // Número secuencial para UI
  />
))}
```

#### 3. **Reportes: Agrupar por enrollment_id**
```sql
-- Reporte de matrículas con múltiples estudiantes
SELECT 
  e.id as enrollment_id,
  e.year,
  g.first_name || ' ' || g.apellido_paterno as apoderado,
  COUNT(es.student_id) as cantidad_estudiantes,
  STRING_AGG(
    s.first_name || ' ' || s.apellido_paterno, 
    ', ' 
    ORDER BY s.apellido_paterno
  ) as estudiantes
FROM enrollments e
INNER JOIN guardians g ON g.id = e.guardian_id
INNER JOIN enrollment_students es ON es.enrollment_id = e.id
INNER JOIN students s ON s.id = es.student_id
GROUP BY e.id, e.year, g.first_name, g.apellido_paterno
ORDER BY cantidad_estudiantes DESC;
```

#### 4. **Validación en forms**
```typescript
// Al crear matrícula múltiple
const createMultiStudentEnrollment = async (
  guardianId: string,
  year: number,
  studentIds: string[]
) => {
  // 1. Crear UN enrollment
  const { data: enrollment } = await supabase
    .from('enrollments')
    .insert({ guardian_id: guardianId, year })
    .select()
    .single();

  // 2. Asociar MÚLTIPLES estudiantes
  const enrollmentStudents = studentIds.map(studentId => ({
    enrollment_id: enrollment.id,
    student_id: studentId
  }));

  await supabase
    .from('enrollment_students')
    .insert(enrollmentStudents);

  return enrollment;
};
```

---

## OPCIÓN 2: STUDENT_SEQUENCE (ALTERNATIVA)

**Concepto:** Agregar columna `student_sequence` a `enrollment_students`

### Migración:
```sql
-- 1. Agregar columna
ALTER TABLE enrollment_students 
ADD COLUMN student_sequence INTEGER;

-- 2. Poblar con números secuenciales
WITH numbered AS (
  SELECT 
    enrollment_id,
    student_id,
    ROW_NUMBER() OVER (
      PARTITION BY enrollment_id 
      ORDER BY created_at, student_id
    ) as seq
  FROM enrollment_students
)
UPDATE enrollment_students es
SET student_sequence = n.seq
FROM numbered n
WHERE es.enrollment_id = n.enrollment_id 
  AND es.student_id = n.student_id;

-- 3. Hacer NOT NULL y agregar a constraint
ALTER TABLE enrollment_students 
ALTER COLUMN student_sequence SET NOT NULL;

-- 4. Crear unique constraint compuesto
ALTER TABLE enrollment_students
ADD CONSTRAINT enrollment_students_sequence_unique
UNIQUE (enrollment_id, student_sequence);
```

### Ventajas:
- ✅ Identificador simple: `enrollment_id + student_sequence`
- ✅ Fácil ordenar hermanos (Estudiante 1, 2, 3)
- ✅ Útil para reportes

### Desventajas:
- ❌ Requiere migración de datos existentes
- ❌ Complejidad adicional en inserts (calcular próximo sequence)
- ❌ Mantenimiento de secuencias si se borran estudiantes

---

## OPCIÓN 3: SPLIT ENROLLMENTS (NO RECOMENDADO) ❌

**Concepto:** 1 enrollment por estudiante, vincular con `parent_enrollment_id`

### Por qué NO:
- ❌ **Rompe modelo de negocio** (un proceso = múltiples hijos)
- ❌ Duplicación masiva de datos
- ❌ Complejidad en cuotas compartidas
- ❌ Migración compleja y riesgosa
- ❌ Pérdida de información histórica

---

## RECOMENDACIÓN FINAL: OPCIÓN 1 (COMPOSITE KEY)

### Plan de Implementación (3-5 días):

#### **Fase 1: Auditoría (1 día)**
```sql
-- Identificar queries problemáticos
SELECT 
  e.id,
  COUNT(es.student_id) as students_count
FROM enrollments e
LEFT JOIN enrollment_students es ON es.enrollment_id = e.id
GROUP BY e.id
HAVING COUNT(es.student_id) > 1
ORDER BY students_count DESC;
```

#### **Fase 2: Backend (2 días)**
1. Refactorizar funciones que asumen 1:1
2. Actualizar tipos TypeScript
3. Ajustar RLS policies si necesario
4. Unit tests para enrollments múltiples

#### **Fase 3: Frontend (1-2 días)**
1. Componentes que muestran lista de estudiantes
2. Forms de matrícula múltiple
3. Validaciones

#### **Fase 4: Testing (1 día)**
1. Test con enrollments existentes (61+ casos)
2. Test de creación nuevos enrollments múltiples
3. Test de reportes y PDFs

### Código de Referencia:

```typescript
// utils/enrollment.ts
export const getEnrollmentWithStudents = async (enrollmentId: string) => {
  const { data, error } = await supabase
    .from('enrollments')
    .select(`
      *,
      guardian:guardians(*),
      enrollment_students(
        created_at,
        student:students(*)
      )
    `)
    .eq('id', enrollmentId)
    .single();

  if (error) throw error;

  return {
    ...data,
    students: data.enrollment_students.map(es => ({
      ...es.student,
      enrollment_joined_at: es.created_at
    }))
  };
};

// Función para generar número de matrícula único por estudiante
export const getEnrollmentStudentNumber = (
  enrollmentId: string,
  studentId: string
) => {
  // Formato: ENROLLMENT-YEAR-SEQUENCE
  // Ejemplo: 2026-001-1, 2026-001-2
  return `${enrollmentId.slice(0, 8)}-${studentId.slice(0, 4)}`;
};
```

### Impacto Estimado:
- **Base de datos:** 0% (sin cambios)
- **Backend:** ~15-20 archivos a modificar
- **Frontend:** ~10-15 componentes a ajustar
- **Tiempo:** 3-5 días
- **Riesgo:** BAJO (sin migración de datos)

---

## DOCUMENTACIÓN ADICIONAL

### Query para analizar casos actuales:
```sql
-- Ver distribución de enrollments por cantidad de estudiantes
SELECT 
  students_per_enrollment,
  COUNT(*) as enrollment_count
FROM (
  SELECT 
    enrollment_id,
    COUNT(student_id) as students_per_enrollment
  FROM enrollment_students
  GROUP BY enrollment_id
) subquery
GROUP BY students_per_enrollment
ORDER BY students_per_enrollment;
```

¿Quieres que genere los scripts SQL de auditoría y ejemplos de código TypeScript específicos para tu proyecto?
