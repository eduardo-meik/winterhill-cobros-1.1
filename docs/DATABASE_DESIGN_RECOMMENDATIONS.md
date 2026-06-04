# Análisis y Recomendaciones: Estructura de Base de Datos para Pagos y Matrículas Escolares

**Fecha**: 23 de octubre, 2025  
**Contexto**: Sistema de cobros y matrículas escolares Winterhill

---

## 📊 Situación Actual del Esquema

### **Tablas Principales Analizadas**

#### 1. **`cursos`** (Cursos por año académico)
```
- id: uuid (PK)
- year_academico: integer ✅ (ej. 2024, 2025)
- cod_curso: integer
- descripcion_curso: varchar
- letra_curso: varchar
- nom_curso: varchar (ej. "1º Básico A")
- nivel: integer
- codigo_curso_matricula: text
```
**✅ Bien diseñado**: Cada curso tiene un `year_academico` explícito.

#### 2. **`students`** (Estudiantes)
```
- id: uuid (PK)
- first_name, apellido_paterno, apellido_materno: text
- run: text (UNIQUE)
- curso: uuid (FK → cursos.id) ⚠️ PROBLEMA
- date_of_birth: date
- nivel: text
- fecha_matricula: date
- estado_std: text
- owner_id: uuid
```
**⚠️ PROBLEMA CRÍTICO**: 
- `students.curso` apunta a UN solo curso (relación 1:1)
- No hay tabla `student_enrollments` o `matriculas`
- **Implicación**: Al matricular al estudiante en 2026, se SOBRESCRIBE el campo `curso`, perdiendo el historial de 2025

#### 3. **`fee`** (Cuotas/Pagos)
```
- id: uuid (PK)
- student_id: uuid (FK → students.id)
- guardian_id: uuid (FK → guardians.id)
- amount: numeric
- due_date: date ⚠️
- payment_date: date
- status: text ('paid', 'pending', 'overdue')
- fee_curso: uuid (FK → cursos.id) ✅ Buena adición
- numero_cuota: numeric
- owner_id: uuid
```
**⚠️ PROBLEMAS**:
- No tiene columna `year` explícita (el año se debe inferir de `fee_curso → cursos.year_academico`)
- `due_date` es una fecha, no un año académico
- Puede tener cuotas de 2024 (atrasadas) mezcladas con cuotas de 2025

---

## 🚨 Problemas Identificados

### **Problema 1: Año de la Cuota Ambiguo**
```
❌ Consulta actual en el código:
.eq('year', currentYear)  // ← columna 'year' NO EXISTE en fee
```

**Escenarios reales**:
- Un estudiante de 3º Básico 2025 tiene cuotas pendientes de 2024
- En enero 2025, se generan cuotas para todo el año 2025
- Un apoderado paga en diciembre 2025 una cuota de marzo 2025 que estaba atrasada

**Pregunta**: ¿Qué año asignamos?
- ¿El año de `due_date`? (marzo 2025)
- ¿El año de `payment_date`? (diciembre 2025)
- ¿El año del curso al que pertenece el estudiante? (puede haber cambiado)

### **Problema 2: Historial de Matrículas No Existe**
```
students.curso = '3º Básico A 2025'  ← Única referencia
```
En marzo 2026, cuando matriculamos al estudiante en 4º Básico:
```sql
UPDATE students SET curso = '4º Básico B 2026' WHERE id = '...';
```
**Consecuencia**: Perdemos que en 2025 estaba en 3º Básico A.

### **Problema 3: Query de Fees Falla**
```javascript
// GuardianWelcomePage.jsx línea 122
.select('amount, status, year')  // ← 'year' no existe
.eq('year', currentYear)         // ← 400 Bad Request
```

---

## 💡 Recomendaciones de Diseño

### **Opción A: Diseño Normalizado Completo (Recomendado para largo plazo)**

#### **Crear tabla `student_enrollments` (Matrículas)**
```sql
CREATE TABLE student_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  curso_id uuid NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
  year_academico integer NOT NULL,
  fecha_matricula date DEFAULT CURRENT_DATE,
  fecha_retiro date,
  motivo_retiro text,
  estado text CHECK (estado IN ('activo', 'retirado', 'trasladado')) DEFAULT 'activo',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(student_id, year_academico),  -- Un estudiante, una matrícula por año
  CHECK (year_academico >= 2020 AND year_academico <= 2100)
);

CREATE INDEX idx_enrollments_student ON student_enrollments(student_id);
CREATE INDEX idx_enrollments_year ON student_enrollments(year_academico);
CREATE INDEX idx_enrollments_curso ON student_enrollments(curso_id);
```

**Beneficios**:
- ✅ Historial completo: "En 2024 estaba en 2º A, en 2025 en 3º B"
- ✅ Queries claros: "¿En qué curso está este estudiante EN 2025?"
- ✅ Migraciones de curso trackeable
- ✅ Estudiantes que repiten quedan registrados

#### **Modificar tabla `fee`**
```sql
-- Agregar columna year explícita
ALTER TABLE fee 
ADD COLUMN year_academico integer;

-- Poblar con datos del curso vinculado
UPDATE fee f
SET year_academico = c.year_academico
FROM cursos c
WHERE f.fee_curso = c.id;

-- Hacer obligatoria
ALTER TABLE fee 
ALTER COLUMN year_academico SET NOT NULL;

-- Agregar constraint
ALTER TABLE fee 
ADD CONSTRAINT fee_year_valid CHECK (year_academico >= 2020 AND year_academico <= 2100);

-- Índices para performance
CREATE INDEX idx_fee_year ON fee(year_academico);
CREATE INDEX idx_fee_student_year ON fee(student_id, year_academico);
```

**Beneficios**:
- ✅ Queries directos: `.eq('year_academico', 2025)`
- ✅ Reportes por año: "Total recaudado 2024 vs 2025"
- ✅ Cuotas atrasadas identificables: `year_academico=2024 AND status='pending'`

#### **Vista Consolidada (Opcional)**
```sql
CREATE VIEW current_student_courses AS
SELECT 
  s.id as student_id,
  s.whole_name,
  s.run,
  se.curso_id,
  c.nom_curso,
  c.year_academico,
  se.estado as enrollment_status
FROM students s
LEFT JOIN student_enrollments se ON se.student_id = s.id
LEFT JOIN cursos c ON c.id = se.curso_id
WHERE se.year_academico = EXTRACT(YEAR FROM CURRENT_DATE)
  AND se.estado = 'activo';
```

---

### **Opción B: Solución Mínima (Para implementar YA)**

Si no pueden modificar el schema ahora, al menos:

#### **1. Agregar `year_academico` a `fee`**
```sql
-- Ver archivo: supabase/migrations/20251023_add_year_to_fee.sql (ya creado)
ALTER TABLE fee ADD COLUMN year_academico integer;
UPDATE fee SET year_academico = EXTRACT(YEAR FROM due_date);
ALTER TABLE fee ALTER COLUMN year_academico SET NOT NULL;
```

#### **2. Modificar consultas frontend**
```javascript
// ANTES (falla):
.select('amount, status, year')
.eq('year', currentYear)

// DESPUÉS (opción temporal):
.select('amount, status, due_date, fee_curso')
.gte('due_date', `${currentYear}-01-01`)
.lte('due_date', `${currentYear}-12-31`)

// MEJOR (si agregamos year_academico):
.select('amount, status, year_academico')
.eq('year_academico', currentYear)
```

---

## 📋 Plan de Migración Recomendado

### **Fase 1: Emergencia (Esta semana)**
1. ✅ Agregar columna `year_academico` a `fee`
2. ✅ Poblar con año de `due_date` o extraer de `fee_curso`
3. ✅ Actualizar queries frontend para usar `year_academico`
4. ✅ Testing: Verificar dashboard de apoderados muestra totales

### **Fase 2: Corto Plazo (Este mes)**
1. Crear tabla `student_enrollments`
2. Migrar datos actuales: copiar `students.curso` → `student_enrollments` para año actual
3. Agregar columna `enrollment_id` a `fee` (opcional, para traceo estricto)
4. Actualizar aplicación para consultar matrículas por año

### **Fase 3: Largo Plazo (Próximos 3 meses)**
1. Deprecar `students.curso` (mantener por compatibilidad)
2. Crear triggers para sincronizar `students.curso` con matrícula activa
3. Implementar proceso de "cierre de año académico"
4. Implementar proceso de "matrícula masiva para nuevo año"

---

## 🎯 Casos de Uso Resueltos

### **Con la estructura propuesta:**

#### **Caso 1: Apoderado ve pagos de 2025**
```sql
SELECT * FROM fee 
WHERE student_id IN (SELECT student_id FROM student_guardian WHERE guardian_id = ?)
  AND year_academico = 2025;
```

#### **Caso 2: Generar cuotas para estudiante que repite**
```sql
-- Estudiante repite 3º Básico
INSERT INTO student_enrollments (student_id, curso_id, year_academico)
VALUES (?, (SELECT id FROM cursos WHERE nom_curso = '3º Básico A' AND year_academico = 2025), 2025);

-- Generar 10 cuotas para 2025
INSERT INTO fee (student_id, amount, due_date, year_academico, numero_cuota, fee_curso)
SELECT ?, 50000, make_date(2025, generate_series(3,12), 5), 2025, generate_series(1,10), ?;
```

#### **Caso 3: Reporte de deudas históricas**
```sql
SELECT 
  s.whole_name,
  f.year_academico,
  SUM(f.amount) FILTER (WHERE f.status = 'pending') as deuda_pendiente,
  SUM(f.amount) FILTER (WHERE f.status = 'overdue') as deuda_atrasada
FROM students s
JOIN fee f ON f.student_id = s.id
WHERE f.year_academico IN (2024, 2025)
GROUP BY s.id, s.whole_name, f.year_academico
HAVING SUM(f.amount) FILTER (WHERE f.status IN ('pending', 'overdue')) > 0;
```

#### **Caso 4: Matricular estudiante en nuevo año**
```sql
-- Sin afectar datos de años anteriores
INSERT INTO student_enrollments (student_id, curso_id, year_academico)
VALUES (
  '5a85933a-3ff3-4451-9000-209072da1eaa',
  (SELECT id FROM cursos WHERE nom_curso = '4º Básico B' AND year_academico = 2026),
  2026
);

-- Opcional: Actualizar students.curso para retrocompatibilidad
UPDATE students 
SET curso = (SELECT id FROM cursos WHERE nom_curso = '4º Básico B' AND year_academico = 2026)
WHERE id = '5a85933a-3ff3-4451-9000-209072da1eaa';
```

---

## ⚠️ Consideraciones Importantes

### **Momento de Transición de Año**
- **¿Cuándo se matricula para 2026?**: Típicamente Nov-Dic 2025
- **¿Cuándo empiezan clases 2026?**: Marzo 2026
- **Período ambiguo**: Dic 2025 - Marzo 2026

**Recomendación**: 
```sql
-- Function para obtener año académico actual
CREATE OR REPLACE FUNCTION current_academic_year() 
RETURNS integer AS $$
BEGIN
  -- Si estamos en enero o febrero, año anterior aún vigente
  IF EXTRACT(MONTH FROM CURRENT_DATE) <= 2 THEN
    RETURN EXTRACT(YEAR FROM CURRENT_DATE) - 1;
  ELSE
    RETURN EXTRACT(YEAR FROM CURRENT_DATE);
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### **Migraciones de Datos**
```sql
-- Ejemplo: Migrar estudiantes actuales a student_enrollments
INSERT INTO student_enrollments (student_id, curso_id, year_academico, estado)
SELECT 
  s.id,
  s.curso,
  c.year_academico,
  CASE WHEN s.estado_std = 'activo' THEN 'activo' ELSE 'retirado' END
FROM students s
JOIN cursos c ON c.id = s.curso
WHERE c.year_academico = 2025  -- Solo año actual
ON CONFLICT (student_id, year_academico) DO NOTHING;
```

---

## 📝 Conclusión y Decisión Requerida

### **Recomendación Final**
1. **INMEDIATO**: Implementar Opción B (agregar `year_academico` a `fee`)
2. **CORTO PLAZO**: Implementar Opción A completa (`student_enrollments`)
3. **Beneficio**: Sistema preparado para múltiples años sin perder historial

### **Preguntas para el Equipo**
1. ¿Necesitan mantener historial de en qué curso estuvo cada estudiante?
2. ¿Hay estudiantes con deudas de años anteriores que necesitan cobrar?
3. ¿El proceso de matrícula es manual o masivo al inicio de año?
4. ¿Necesitan reportes comparativos entre años (ej. "2024 vs 2025")?

### **Próximos Pasos Sugeridos**
- [ ] Revisar este documento con el equipo
- [ ] Decidir: ¿Opción A completa o solo Opción B mínima?
- [ ] Aplicar migración `20251023_add_year_to_fee.sql`
- [ ] Actualizar código frontend (GuardianWelcomePage.jsx ya modificado)
- [ ] Testing en desarrollo
- [ ] Si aprueban Opción A, crear migration para `student_enrollments`

---

**Documentado por**: GitHub Copilot  
**Revisión requerida por**: Equipo técnico Winterhill
