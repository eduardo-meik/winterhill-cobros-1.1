# Análisis Completo: Arquitectura de Datos Existente vs Propuesta

**Fecha**: 23 de octubre, 2025  
**Sistema**: Winterhill - Gestión Escolar y Cobros

---

## 🔍 HALLAZGO CRÍTICO: Sistema de Matrículas Ya Existe

### **Tablas Existentes Detectadas**

#### 1. **`enrollments`** (Proceso de Matrícula Anual)
```sql
CREATE TABLE enrollments (
  id uuid PRIMARY KEY,
  guardian_id uuid → guardians(id),  -- ✅ Un apoderado matricula
  year integer NOT NULL,              -- ✅ Año académico explícito
  status text ('draft','pending','completed','rejected'),
  meta jsonb,                         -- Datos económicos, preferencias
  created_at, updated_at timestamptz,
  UNIQUE (guardian_id, year)          -- ✅ Una matrícula por apoderado/año
);
```

**Propósito**: Proceso administrativo de matrícula (documentos, pagarés, declaraciones).  
**Alcance**: Guardian-centric, año completo.

#### 2. **`enrollment_students`** (Estudiantes por Matrícula)
```sql
CREATE TABLE enrollment_students (
  enrollment_id uuid → enrollments(id),
  student_id uuid → students(id),
  created_at timestamptz,
  PRIMARY KEY (enrollment_id, student_id)
);
```

**Propósito**: Many-to-many entre `enrollments` y `students`.  
**Problema**: ❌ **NO tiene `curso_id`** → No registra EN QUÉ CURSO se matriculó el estudiante.

#### 3. **`enrollment_documents`** (Pagarés, Declaraciones)
```sql
CREATE TABLE enrollment_documents (
  id uuid PRIMARY KEY,
  enrollment_id uuid → enrollments(id),
  type text ('PAGARE','DECLARACION','OTRO'),
  template_version integer,
  status text ('draft','generated','signed'),
  pdf_url, storage_path text,
  generated_payload jsonb,
  signed_at timestamptz
);
```

**Propósito**: Documentos legales firmados por apoderado.

#### 4. **Tablas Auxiliares Existentes**
- `document_templates`: Plantillas de pagaré con placeholders
- `signatures`: Auditoría de firmas digitales
- `pre_receipts`: Pre-boletas antes de emisión SII

---

## 🎯 Diferencias: `enrollments` vs `student_enrollments` (propuesta)

| Aspecto | `enrollments` (EXISTE) | `student_enrollments` (PROPUESTA) |
|---------|------------------------|-----------------------------------|
| **Enfoque** | Proceso administrativo del apoderado | Historial académico del estudiante |
| **Granularidad** | Uno por apoderado/año | Uno por estudiante/año |
| **Entidad Principal** | `guardian_id` | `student_id` |
| **Propósito** | Gestión de matrícula (docs, pagos anuales) | Tracking de curso/nivel por año |
| **Incluye Curso** | ❌ NO | ✅ SÍ (`curso_id`, `year_academico`) |
| **Tracking Histórico** | ❌ No registra curso específico | ✅ "En 2024 estaba en 2º A, 2025 en 3º B" |
| **Casos de Uso** | - Firma de pagaré<br>- Cuotas económicas<br>- Documentos legales | - Historial académico<br>- Reportes MINEDUC<br>- Promoción/repitencia |

---

## 📊 Ecosistema Actual: Cómo se Relacionan las Tablas

```
guardians (apoderados)
    ↓
enrollments (proceso matrícula año X)
    ↓
enrollment_students (N estudiantes en esa matrícula)
    ↓
students (datos del estudiante)
    ├── curso: uuid → cursos(id)  ⚠️ PROBLEMA: solo UN curso actual
    └── nivel: text

cursos (cursos por año)
    ├── year_academico: integer ✅
    └── nom_curso: "3º Básico A"

fee (cuotas de pago)
    ├── student_id: uuid
    ├── fee_curso: uuid → cursos(id) ✅
    ├── due_date: date
    └── year_academico: ❌ NO EXISTE (propuesta agregar)
```

### **Flujo Actual**
1. **Matrícula Inicial**: Apoderado inicia proceso → crea `enrollment` para 2025
2. **Agregar Estudiantes**: Se agregan estudiantes a `enrollment_students`
3. **Firma Documentos**: Pagaré generado → `enrollment_documents`
4. **Actualiza `students.curso`**: ⚠️ Se sobrescribe el campo `curso` (pierde historial)
5. **Genera Cuotas**: Crea registros en `fee` con `fee_curso` del año actual

### **Problema al Año Siguiente (2026)**
```sql
-- Estudiante avanza de 3º → 4º
UPDATE students SET curso = '4º-B-2026' WHERE id = '...';
-- ❌ Perdemos que en 2025 estaba en 3º-A
```

---

## 💡 RECOMENDACIÓN ARQUITECTÓNICA

### **Opción Recomendada: Sistema Híbrido (Reutilizar + Extender)**

#### **Mantener como están**:
✅ `enrollments` → Proceso administrativo anual del apoderado  
✅ `enrollment_students` → Relación matrícula ↔ estudiantes  
✅ `enrollment_documents` → Documentos legales  
✅ `fee` → Cuotas de pago

#### **Agregar Nueva Tabla**: `student_academic_records`
```sql
-- Historial académico: en qué curso estuvo cada estudiante cada año
CREATE TABLE student_academic_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  curso_id uuid NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
  year_academico integer NOT NULL CHECK (year_academico BETWEEN 2020 AND 2100),
  
  -- Datos académicos del período
  fecha_inicio date,
  fecha_termino date,
  estado text CHECK (estado IN ('activo','completado','retirado','repitio')) DEFAULT 'activo',
  promedio_anual numeric(3,2),
  asistencia_porcentaje numeric(5,2),
  observaciones text,
  
  -- Link opcional al proceso de matrícula administrativa
  enrollment_id uuid REFERENCES enrollments(id) ON DELETE SET NULL,
  
  -- Auditoría
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Constraints
  UNIQUE(student_id, year_academico),  -- Un estudiante, un curso por año
  CHECK (promedio_anual IS NULL OR promedio_anual BETWEEN 1.0 AND 7.0),
  CHECK (asistencia_porcentaje IS NULL OR asistencia_porcentaje BETWEEN 0 AND 100)
);

-- Índices para performance
CREATE INDEX idx_academic_student ON student_academic_records(student_id);
CREATE INDEX idx_academic_year ON student_academic_records(year_academico);
CREATE INDEX idx_academic_curso ON student_academic_records(curso_id);
CREATE INDEX idx_academic_student_year ON student_academic_records(student_id, year_academico);

-- RLS
ALTER TABLE student_academic_records ENABLE ROW LEVEL SECURITY;

-- Policy: Apoderados ven registros de sus estudiantes
CREATE POLICY academic_records_guardian_access ON student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM student_guardian sg
      JOIN guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_academic_records.student_id
      AND g.owner_id = auth.uid()
    )
  );

-- Policy: Admins/teachers pueden modificar
CREATE POLICY academic_records_admin_write ON student_academic_records
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role IN ('admin','teacher','director')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role IN ('admin','teacher','director')
    )
  );
```

#### **Extender `fee` con `year_academico`**
```sql
-- Migración ya creada: 20251023_add_year_to_fee.sql
ALTER TABLE fee ADD COLUMN year_academico integer;
UPDATE fee SET year_academico = (
  SELECT c.year_academico FROM cursos c WHERE c.id = fee.fee_curso
);
ALTER TABLE fee ALTER COLUMN year_academico SET NOT NULL;
CREATE INDEX idx_fee_year ON fee(year_academico);
```

#### **Opcional: Extender `enrollment_students` (sin romper existente)**
```sql
-- Agregar referencia al registro académico (relación opcional)
ALTER TABLE enrollment_students 
ADD COLUMN academic_record_id uuid REFERENCES student_academic_records(id) ON DELETE SET NULL;

-- Permite vincular: "Esta matrícula administrativa corresponde a este registro académico"
CREATE INDEX idx_enrollment_academic ON enrollment_students(academic_record_id);
```

---

## 🏗️ Arquitectura Propuesta Final

```
┌─────────────────────────────────────────────────────────────┐
│  PROCESO ADMINISTRATIVO (Guardian-centric)                   │
│                                                              │
│  guardians                                                   │
│      ↓                                                       │
│  enrollments (matrícula anual del apoderado)                │
│      ↓                                                       │
│  enrollment_students (estudiantes en proceso)               │
│      ├→ student_id                                           │
│      └→ academic_record_id (NUEVO, opcional)                │
│      ↓                                                       │
│  enrollment_documents (pagaré, declaraciones)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  HISTORIAL ACADÉMICO (Student-centric) - NUEVO              │
│                                                              │
│  students                                                    │
│      ↓                                                       │
│  student_academic_records (curso por año)                   │
│      ├→ curso_id (3º A 2024, 4º B 2025, etc.)              │
│      ├→ year_academico                                      │
│      ├→ estado (activo/completado/retirado/repitió)        │
│      └→ promedio, asistencia, observaciones                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  TRANSACCIONES FINANCIERAS                                   │
│                                                              │
│  fee (cuotas)                                                │
│      ├→ student_id                                           │
│      ├→ fee_curso (curso que genera la cuota)               │
│      ├→ year_academico (NUEVO)                              │
│      ├→ due_date, amount, status                            │
│      └→ guardian_id (quien paga)                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  MAESTRO DE CURSOS                                           │
│                                                              │
│  cursos (catálogo)                                           │
│      ├→ year_academico (2024, 2025, etc.)                   │
│      ├→ nom_curso ("3º Básico A")                           │
│      └→ nivel, letra_curso, cod_curso                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Tablas a ELIMINAR

### ❌ **Ninguna** (por ahora)

**Justificación**:
- `enrollments` tiene propósito diferente (proceso admin vs historial académico)
- `enrollment_students` es útil para vincular matrícula ↔ estudiantes
- Eliminar tablas existentes con datos requiere migración compleja

**Estrategia**: Extender, no reemplazar.

---

## 📋 Tablas a EXTENDER

### 1. **`fee`** → Agregar `year_academico`
✅ Migración lista: `20251023_add_year_to_fee.sql`

### 2. **`enrollment_students`** → Agregar `academic_record_id` (opcional)
Permite vincular proceso admin ↔ registro académico.

### 3. **`students.curso`** → Mantener como "curso actual" (view helper)
```sql
-- Trigger para auto-actualizar students.curso con curso activo del año actual
CREATE OR REPLACE FUNCTION sync_student_current_curso()
RETURNS TRIGGER AS $$
BEGIN
  -- Si se inserta/actualiza registro del año actual, actualizar students.curso
  IF NEW.year_academico = EXTRACT(YEAR FROM CURRENT_DATE) THEN
    UPDATE students 
    SET curso = NEW.curso_id 
    WHERE id = NEW.student_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_student_curso
AFTER INSERT OR UPDATE ON student_academic_records
FOR EACH ROW
EXECUTE FUNCTION sync_student_current_curso();
```

---

## 🎯 Casos de Uso Resueltos

### **Caso 1: Matrícula de Estudiante para 2026**
```sql
-- 1. Proceso administrativo (apoderado firma pagaré)
INSERT INTO enrollments (guardian_id, year, status)
VALUES ('guardian-uuid', 2026, 'draft');

-- 2. Agregar estudiante al proceso
INSERT INTO enrollment_students (enrollment_id, student_id)
VALUES ('enrollment-uuid', 'student-uuid');

-- 3. Registro académico (historial)
INSERT INTO student_academic_records (student_id, curso_id, year_academico, estado)
VALUES (
  'student-uuid',
  (SELECT id FROM cursos WHERE nom_curso = '4º Básico B' AND year_academico = 2026),
  2026,
  'activo'
);

-- 4. (Opcional) Vincular ambos
UPDATE enrollment_students
SET academic_record_id = (
  SELECT id FROM student_academic_records 
  WHERE student_id = 'student-uuid' AND year_academico = 2026
)
WHERE enrollment_id = 'enrollment-uuid' AND student_id = 'student-uuid';
```

### **Caso 2: Query "¿En qué curso estuvo Juan en 2024?"**
```sql
SELECT 
  s.whole_name,
  c.nom_curso,
  sar.estado,
  sar.promedio_anual,
  sar.asistencia_porcentaje
FROM students s
JOIN student_academic_records sar ON sar.student_id = s.id
JOIN cursos c ON c.id = sar.curso_id
WHERE s.run = '12345678-9'
  AND sar.year_academico = 2024;
```

### **Caso 3: Reporte de Cuotas por Año Académico**
```sql
-- Ahora funciona porque fee.year_academico existe
SELECT 
  s.whole_name,
  f.year_academico,
  SUM(f.amount) FILTER (WHERE f.status = 'paid') as pagado,
  SUM(f.amount) FILTER (WHERE f.status = 'pending') as pendiente
FROM students s
JOIN fee f ON f.student_id = s.id
WHERE f.year_academico IN (2024, 2025)
GROUP BY s.id, s.whole_name, f.year_academico;
```

### **Caso 4: Dashboard Apoderado (GuardianWelcomePage)**
```sql
-- Cuotas del año actual (ahora funciona)
SELECT * FROM fee
WHERE student_id IN (
  SELECT student_id FROM student_guardian WHERE guardian_id = ?
)
AND year_academico = 2025;

-- Estudiantes asociados con su curso actual
SELECT 
  s.*,
  sar.curso_id,
  c.nom_curso
FROM students s
JOIN student_guardian sg ON sg.student_id = s.id
LEFT JOIN student_academic_records sar ON sar.student_id = s.id 
  AND sar.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN cursos c ON c.id = sar.curso_id
WHERE sg.guardian_id = ?;
```

---

## 🛡️ Seguridad: Row Level Security (RLS)

### **Políticas Existentes (mantener)**
- ✅ `enrollments`: Guardian ve solo sus matrículas
- ✅ `enrollment_students`: Acceso vía enrollment padre
- ✅ `fee`: ¿Política actual? (revisar)

### **Nuevas Políticas Requeridas**
```sql
-- student_academic_records: Apoderados ven registros de sus estudiantes
CREATE POLICY academic_guardian_read ON student_academic_records
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM student_guardian sg
      JOIN guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_academic_records.student_id
      AND g.owner_id = auth.uid()
    )
  );

-- student_academic_records: Solo admins/teachers modifican
CREATE POLICY academic_admin_write ON student_academic_records
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() AND role IN ('admin','teacher')
    )
  );
```

---

## 🚀 Plan de Implementación

### **Fase 1: Emergencia (Esta semana) ✅**
- [x] Agregar `year_academico` a `fee`
- [x] Actualizar query frontend (GuardianWelcomePage.jsx)
- [ ] Testing: Dashboard muestra totales correctos

### **Fase 2: Estructura Académica (Este mes)**
1. Crear tabla `student_academic_records`
2. Migrar datos actuales de `students.curso` al año 2025
3. Agregar columna `academic_record_id` a `enrollment_students`
4. Implementar trigger para sync `students.curso`
5. Documentar flujo de matrícula 2026

### **Fase 3: Integration (Próximos 2 meses)**
1. Actualizar servicios frontend para usar `student_academic_records`
2. Crear vistas SQL consolidadas para reportes
3. Implementar proceso de "cierre de año académico"
4. UI para admin: asignar cursos masivamente
5. Reportes MINEDUC con historial completo

### **Fase 4: Optimización (Trimestre)**
1. Índices adicionales basados en queries reales
2. Particionamiento de `fee` por año (si >1M registros)
3. Archived tables para años antiguos (>5 años)
4. Auditoría de acceso a datos académicos sensibles

---

## ⚠️ Consideraciones de Producción

### **Migración de Datos Existentes**
```sql
-- Poblar student_academic_records con datos actuales (2025)
INSERT INTO student_academic_records (student_id, curso_id, year_academico, estado)
SELECT 
  s.id,
  s.curso,
  c.year_academico,
  CASE 
    WHEN s.estado_std = 'activo' THEN 'activo'
    WHEN s.fecha_retiro IS NOT NULL THEN 'retirado'
    ELSE 'completado'
  END
FROM students s
JOIN cursos c ON c.id = s.curso
WHERE c.year_academico = 2025  -- Solo año actual por seguridad
ON CONFLICT (student_id, year_academico) DO NOTHING;
```

### **Rollback Plan**
```sql
-- Si hay problemas, revertir cambios
DROP TABLE IF EXISTS student_academic_records CASCADE;
ALTER TABLE enrollment_students DROP COLUMN IF EXISTS academic_record_id;
ALTER TABLE fee DROP COLUMN IF EXISTS year_academico;
```

### **Performance Monitoring**
```sql
-- Queries lentas a monitorear
EXPLAIN ANALYZE
SELECT * FROM fee WHERE year_academico = 2025 AND student_id = ?;

EXPLAIN ANALYZE
SELECT * FROM student_academic_records WHERE student_id = ? ORDER BY year_academico DESC;
```

---

## 📊 Métricas de Éxito

- ✅ Dashboard de apoderados muestra totales correctos (sin error 400)
- ✅ Historial académico completo de cada estudiante
- ✅ Reportes de deuda por año sin ambigüedades
- ✅ Proceso de matrícula 2026 sin perder datos 2025
- ✅ Queries < 100ms para 10,000 estudiantes
- ✅ RLS policies protegen datos sensibles
- ✅ Auditoría completa de cambios de curso

---

## 🎓 Conclusión

### **Recomendación Final: Sistema Híbrido**

**REUTILIZAR**:
- ✅ `enrollments` (proceso administrativo)
- ✅ `enrollment_students` (vínculo matrícula-estudiante)
- ✅ `enrollment_documents` (documentos legales)
- ✅ Toda la infraestructura de RLS y triggers existente

**AGREGAR**:
- 🆕 `student_academic_records` (historial académico por año)
- 🆕 `fee.year_academico` (columna para queries)
- 🆕 Trigger para sync `students.curso` automático

**ELIMINAR**:
- ❌ Nada (por ahora)

**Beneficios**:
- 🎯 Separation of concerns: Admin vs Académico
- 🔒 Seguridad: RLS policies granulares
- 📈 Escalabilidad: Índices optimizados
- 🔄 Trazabilidad: Historial completo sin pérdida
- ✅ Production-ready: Rollback plan, monitoring

---

**Próximos Pasos Inmediatos**:
1. Revisar este documento con equipo técnico
2. Aprobar creación de `student_academic_records`
3. Aplicar migración `20251023_add_year_to_fee.sql`
4. Testing en staging
5. Deploy a producción por fases

---

**Documentado por**: GitHub Copilot  
**Requiere Aprobación**: Equipo Técnico + Dirección Académica Winterhill
