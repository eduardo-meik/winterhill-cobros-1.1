# 📋 Plan: Transición Anual de Estudiantes, Generación de Fees y Mejoras UI/UX

> **Fecha de evaluación:** 22 de febrero de 2026  
> **Versión del sistema:** winterhill-cobros-1.1  
> **Stack:** React + Vite (JSX/TSX) · Supabase (PostgreSQL) · TailwindCSS  

---

## 📑 Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Diagnóstico del Estado Actual](#2-diagnóstico-del-estado-actual)
3. [Brechas Identificadas](#3-brechas-identificadas)
4. [Plan de Implementación](#4-plan-de-implementación)
5. [Fase 1 — Backend: Transición Anual y Generación de Fees](#fase-1)
6. [Fase 2 — Módulo de Estudiantes: Filtrado por Año y Vista Histórica](#fase-2)
7. [Fase 3 — Dashboard con Contexto de Año](#fase-3)
8. [Fase 4 — Mejoras UI/UX Transversales](#fase-4)
9. [Modelo de Datos Propuesto](#5-modelo-de-datos-propuesto)
10. [Riesgos y Mitigaciones](#6-riesgos-y-mitigaciones)
11. [Estimación de Esfuerzo](#7-estimación-de-esfuerzo)

---

## 1. Resumen Ejecutivo

El sistema Winterhill Cobros permite matricular estudiantes y generar documentos contractuales. Sin embargo, **carece de una lógica real de transición anual**: los estudiantes matriculados para 2026 no ven actualizado su curso, no se genera un registro académico histórico, y el módulo de estudiantes no filtra por año. Los fees se generan correctamente durante la finalización de matrícula, pero el Dashboard y el módulo de pagos no ofrecen contexto de año académico adecuado.

### Objetivos del Plan

| # | Objetivo | Prioridad |
|---|----------|-----------|
| 1 | Trasladar estudiantes matriculados 2025 → 2026 (actualizar curso, crear registro académico) | **CRÍTICA** |
| 2 | Poblar el módulo de Estudiantes con datos del año vigente, con filtro por año | **CRÍTICA** |
| 3 | Permitir que estudiantes del año anterior "liberen espacio" pero queden consultables | **ALTA** |
| 4 | Generar fees automáticamente según los datos de la matrícula 2026 | **CRÍTICA** |
| 5 | Mejorar UI/UX general (Dashboard con año, navegación, consistencia) | **ALTA** |

---

## 2. Diagnóstico del Estado Actual

### 2.1 Flujo de Matrícula (funciona parcialmente ✅)

```
Guardian → MatriculaWizard → Selecciona estudiantes → Elige curso 2026 
  → Datos económicos → Documentos → Finalizar
    → finalize_enrollment RPC:
        ✅ Crea registros en tabla `fee` (con year_academico = 2026)
        ✅ Marca enrollment.status = 'completed'
        ✅ Marca student.status = 'MATRICULADO'
        ❌ NO actualiza student.curso a curso 2026
        ❌ NO crea registro en student_academic_records
        ❌ NO implementa lógica de promoción de curso
```

### 2.2 Módulo de Estudiantes (StudentsPage)

| Aspecto | Estado | Problema |
|---------|--------|----------|
| Listado de estudiantes | ✅ Funciona | Muestra TODOS los estudiantes sin distinción de año |
| Filtro por año | ❌ No existe | No hay forma de ver "solo estudiantes 2026" |
| Columna de año | ❌ No visible | El curso se muestra sin indicar el año académico |
| Historial académico | ❌ No implementado | StudentDetailsModal no muestra enrollments previos |
| Promoción de curso | ❌ Stub vacío | `get_student_promotion_suggestion` retorna NULL |
| Estado del estudiante | ⚠️ Confuso | DB "MATRICULADO" = UI "Pendiente"; DB "ACTIVO" = UI "Matriculado" |

### 2.3 Tabla `student_academic_records` (infraestructura muerta)

La tabla **existe en la base de datos** con el esquema correcto:

```sql
student_academic_records (
  id uuid PK,
  student_id FK → students,
  curso_id FK → cursos,
  year_academico integer,
  status text,              -- 'CURSANDO', 'PROMOVIDO', 'REPITENTE'
  enrollment_id FK → enrollments,
  nivel text,
  seccion text,
  fecha_matricula date,
  repite boolean,
  observaciones text,
  created_at, updated_at
)
```

**Tiene RLS policies y triggers configurados**, pero **nada la escribe**. Ni el wizard de matrícula ni el RPC `finalize_enrollment` insertan datos aquí.

### 2.4 Generación de Fees

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Generación al finalizar matrícula | ✅ Funciona | Crea N cuotas con `year_academico`, `enrollment_id` |
| Prevención de duplicados | ✅ Funciona | Unique index `(student_id, year_academico, numero_cuota)` |
| Filtro por año en PaymentsPage | ⚠️ Parcial | Usa `due_date` year, no `year_academico` |
| Filtro por año en Dashboard | ❌ No existe | Métricas mezclan todos los años |

### 2.5 Dashboard

- **Sin filtro de año**: Los 4 StatCards (Deudores Activos, Deuda Total, Ingresos Proyectados, Tasa de Morosidad) agregan fees de **todos los años**.
- **Sin contexto temporal**: No hay selector de período académico.
- Los gráficos (DebtTrendChart, DebtDistributionChart, PaymentProjectionChart) tampoco filtran por año.

### 2.6 Sidebar / Navegación

- Menú funcional pero **no indica el año académico activo**.
- No hay un selector global de año académico.
- El ícono de Matrícula usa el mismo ícono que Apoderados (Guardian).

---

## 3. Brechas Identificadas

### 🔴 CRÍTICAS (bloquean operación 2026)

| ID | Brecha | Impacto |
|----|--------|---------|
| G1 | `finalize_enrollment` no actualiza `student.curso` al curso 2026 seleccionado | Estudiantes matriculados 2026 siguen mostrando curso 2025 |
| G2 | `finalize_enrollment` no crea `student_academic_records` | Sin historial académico, imposible rastrear trayectoria |
| G3 | `get_student_promotion_suggestion` es un stub | No hay sugerencia automática de curso siguiente |
| G4 | StudentsPage no tiene filtro de año | Admin no puede ver solo estudiantes del año vigente |
| G5 | Fees generados correctamente pero Dashboard no los filtra por año | Métricas financieras 2026 mezcladas con años anteriores |

### 🟡 ALTAS (afectan usabilidad)

| ID | Brecha | Impacto |
|----|--------|---------|
| G6 | No hay concepto de "año académico activo" global en la UI | Cada módulo maneja el año independientemente |
| G7 | PaymentsPage filtra por año de `due_date` en vez de `year_academico` | Categorización incorrecta de fees entre años |
| G8 | Nomenclatura de estados confusa (MATRICULADO=Pendiente, ACTIVO=Matriculado) | Confusión operativa |
| G9 | StudentDetailsModal no muestra historial de enrollments/cursos | Sin visibilidad de trayectoria del alumno |
| G10 | No hay herramienta de promoción masiva (batch) | Admin debe re-matricular uno por uno |

### 🟢 DESEABLES (mejoran experiencia)

| ID | Brecha | Impacto |
|----|--------|---------|
| G11 | Sidebar sin indicador de año académico activo | Falta contexto visual |
| G12 | Dashboard sin acceso rápido a métricas por año | Reportes manuales |
| G13 | Falta botón "Promover todos" para cierre de año | Proceso manual propenso a errores |

---

## 4. Plan de Implementación

### Arquitectura de la Solución

```
┌─────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Sidebar +   │  │  Dashboard   │  │  StudentsPage │  │
│  │  AñoSelector │  │  + AñoFilter │  │  + AñoFilter  │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ PaymentsPage │  │  Matrícula   │  │  Promoción    │  │
│  │ + year_acad  │  │  Wizard      │  │  Masiva Page  │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    CAPA DE CONTEXTO                      │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  AcademicYearContext (año activo global: 2026)   │   │
│  │  - selectedYear: number                          │   │
│  │  - availableYears: number[]                      │   │
│  │  - setSelectedYear(year)                         │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    CAPA DE SERVICIOS                     │
│                                                         │
│  matricula.ts    feeService.ts    studentService.ts     │
│  (existente)     (existente)      (NUEVO)               │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                    CAPA DE BASE DE DATOS                 │
│                                                         │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐  │
│  │  students   │ │    fee      │ │ student_academic │  │
│  │  +curso FK  │ │ +year_acad  │ │ _records (ACTIVAR)│  │
│  └─────────────┘ └─────────────┘ └──────────────────┘  │
│                                                         │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐  │
│  │ enrollments │ │   cursos    │ │ enrollment_      │  │
│  │             │ │  +year_acad │ │ students         │  │
│  └─────────────┘ └─────────────┘ └──────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

<a id="fase-1"></a>
## Fase 1 — Backend: Transición Anual y Generación de Fees

### 1.1 Modificar `finalize_enrollment` RPC

**Archivo:** `supabase/migrations/` (nueva migración)  
**Cambios en la función RPC:**

```
PARA CADA estudiante en enrollment_students:
  1. ✅ (existente) Crear fees con year_academico
  2. ✅ (existente) Marcar student.status = 'MATRICULADO'
  3. 🆕 Actualizar student.curso = target_course_id (del meta JSON)
  4. 🆕 INSERT INTO student_academic_records:
     - student_id, curso_id (nuevo), year_academico, status='CURSANDO'
     - enrollment_id, nivel, seccion, fecha_matricula
  5. 🆕 Si existía un registro académico del año anterior:
     - UPDATE student_academic_records SET status='PROMOVIDO' 
       WHERE student_id = X AND year_academico = (year - 1)
```

### 1.2 Implementar `get_student_promotion_suggestion`

**Lógica de promoción automática:**

```
INPUT: student_id, target_year (2026)

1. Obtener curso actual del estudiante (student.curso → cursos)
2. Determinar el nivel siguiente:
   - Pre-Kinder → Kinder
   - Kinder → 1° Básico
   - N° Básico → (N+1)° Básico  (hasta 8°)
   - 8° Básico → 1° Medio
   - N° Medio → (N+1)° Medio (hasta 4°)
   - 4° Medio → EGRESADO
3. Buscar en cursos WHERE nom_curso LIKE '%nivel_siguiente%' 
   AND year_academico = target_year
   AND seccion = mismo_seccion_actual (si existe)
4. RETURN { suggested_curso_id, suggested_nombre, nivel }
```

### 1.3 Crear función `promote_students_batch`

```sql
-- Promoción masiva de estudiantes de un año a otro
promote_students_batch(
  from_year integer,      -- 2025
  to_year integer,        -- 2026
  student_ids uuid[],     -- NULL = todos los ACTIVOS del from_year
  dry_run boolean         -- true = solo preview
)
RETURNS jsonb             -- { promoted: [...], skipped: [...], errors: [...] }
```

### 1.4 Asegurar idempotencia de fees

- **Ya existe**: Unique index `(student_id, year_academico, numero_cuota)` con `ON CONFLICT DO NOTHING`.
- **Verificar**: Que el RPC no genere fees duplicados si se re-ejecuta.

---

<a id="fase-2"></a>
## Fase 2 — Módulo de Estudiantes: Filtrado por Año y Vista Histórica

### 2.1 Contexto Global de Año Académico

**Nuevo archivo:** `src/contexts/AcademicYearContext.jsx`

```
AcademicYearProvider
  - selectedYear: number (default: 2026)
  - availableYears: number[] (extraídos de cursos.year_academico DISTINCT)
  - setSelectedYear(year): function
  - Persiste en localStorage
```

### 2.2 Selector de Año en Sidebar

**Modificar:** `src/components/Sidebar.jsx`

- Agregar un `<select>` o toggle de año académico debajo del logo/menú.
- Visible para roles `admin` y `asist`.
- Conectado al `AcademicYearContext`.

### 2.3 StudentsPage con Filtro de Año

**Modificar:** `src/components/students/StudentsPage.jsx`

| Cambio | Detalle |
|--------|---------|
| Filtro de año | Dropdown con años disponibles (del contexto global) |
| Query filtrada | JOIN `student_academic_records` WHERE `year_academico = selectedYear` |
| Columna de año | Mostrar año académico en la tabla |
| Vista "Todos los años" | Opción para ver historial completo |
| Indicador visual | Badge "2026" o "2025" en cada estudiante |

### 2.4 Lógica de "Liberar Espacio"

**Concepto:** Los estudiantes del año anterior (2025) no se eliminan. Se archivan visualmente:

| Estado en 2025 | Acción | Resultado |
|----------------|--------|-----------|
| ACTIVO (matriculado 2025) | Se matricula para 2026 | `student_academic_records` 2025 → status='PROMOVIDO'. Nuevo registro 2026 → status='CURSANDO'. `student.curso` apunta a curso 2026. |
| ACTIVO (matriculado 2025) | NO se matricula 2026 | Queda en 2025. Visible al filtrar año 2025. En 2026 aparece como "Sin matrícula vigente" |
| RETIRADO | — | Solo visible en historial. No aparece en listado activo de ningún año |

**Filtro por defecto:** StudentsPage mostrará **solo el año seleccionado** (2026), pero permitirá cambiar a 2025 o "Todos".

### 2.5 StudentDetailsModal — Historial Académico

**Modificar:** `src/components/students/StudentDetailsModal.jsx`

Agregar una sección **"Historial Académico"** con:

```
┌──────────────────────────────────────────────────┐
│  📚 Historial Académico                          │
│                                                  │
│  2026 │ 2° Básico A │ CURSANDO    │ Matrícula ✅ │
│  2025 │ 1° Básico A │ PROMOVIDO   │ Matrícula ✅ │
│  2024 │ Pre-Kinder  │ PROMOVIDO   │ Matrícula ✅ │
│                                                  │
│  📄 Fees asociados: 10 cuotas (2026)             │
│  💰 Estado de pago: 3/10 pagadas                 │
└──────────────────────────────────────────────────┘
```

---

<a id="fase-3"></a>
## Fase 3 — Dashboard con Contexto de Año

### 3.1 Filtrar métricas por año académico

**Modificar:** `src/components/Dashboard.jsx`

- Usar `selectedYear` del `AcademicYearContext`.
- Query de fees: `.eq('year_academico', selectedYear)` en lugar de traer todos.
- Los 4 StatCards reflejarán solo el año seleccionado.
- Agregar etiqueta "Año Académico 2026" visible.

### 3.2 Gráficos con contexto de año

**Modificar:** Componentes en `src/components/dashboard/graphs/`

- `DebtTrendChart` → Filtrar por `year_academico`.
- `DebtDistributionChart` → Idem.
- `PaymentProjectionChart` → Idem.
- `DebtorsTable` → Filtrar por `year_academico`.

### 3.3 PaymentsPage — Usar `year_academico`

**Modificar:** `src/components/payments/PaymentsPage.jsx`

- Cambiar filtro de año: de `new Date(fee.due_date).getFullYear()` → `fee.year_academico`.
- Default: año del contexto global.
- Esto corrige la categorización errónea de fees cuyo `due_date` cae en un año calendario diferente al `year_academico`.

---

<a id="fase-4"></a>
## Fase 4 — Mejoras UI/UX Transversales

### 4.1 Herramienta de Promoción Masiva

**Nuevo componente:** `src/components/students/PromotionTool.jsx`

```
┌──────────────────────────────────────────────────┐
│  🎓 Promoción de Estudiantes — Año 2025 → 2026  │
│                                                  │
│  Desde: [2025 ▼]  Hacia: [2026 ▼]               │
│                                                  │
│  ☑ Juan Pérez    │ 1° Básico A → 2° Básico A    │
│  ☑ María López   │ 4° Medio A  → EGRESADO       │
│  ☐ Pedro García  │ 3° Básico B → 4° Básico B    │
│                                                  │
│  📊 Resumen: 45 para promover, 2 egresados       │
│                                                  │
│  [Vista Previa]  [Promover Seleccionados]        │
└──────────────────────────────────────────────────┘
```

- Accesible desde el menú Sidebar (solo admin).
- Llama a `promote_students_batch` RPC con `dry_run=true` primero.
- Confirmación antes de ejecutar.

### 4.2 Correcciones de Consistencia Visual

| Componente | Mejora |
|------------|--------|
| **Sidebar** | Agregar selector de año. Ícono diferente para Matrícula (no repetir Guardian). Indicador de notificaciones. |
| **StudentsTable** | Agregar columna "Año". Mostrar `curso (año)` en vez de solo `curso`. |
| **StatusBadge** | Renombrar para claridad: "Pre-Matriculado" (MATRICULADO en DB), "Confirmado" (ACTIVO en DB), "Retirado" |
| **Dashboard** | Agregar etiqueta de año. Botón de comparación año anterior. |
| **PaymentsPage** | Default al año del contexto global. Usar `year_academico` para filtro. |
| **StudentDetailsModal** | Agregar tabs: Datos Personales | Historial | Fees | Documentos |

### 4.3 Flujo Completo: Estudiante 2025 → 2026

```
Estado Inicial (Feb 2026):
  Estudiante: Juan Pérez
  Curso actual: 1° Básico A (2025)
  Status: ACTIVO
  student_academic_records: [{2025, 1° Básico A, CURSANDO}]

──── OPCIÓN A: Matrícula Individual ────

1. Admin abre MatriculaWizard → año 2026
2. Selecciona guardian → ve a Juan en "Mis Alumnos"
3. EconomicDataStep muestra sugerencia: "2° Básico A (2026)" ← RPC de promoción
4. Completa datos económicos, documentos
5. Finaliza matrícula:
   → student.curso = UUID de "2° Básico A" (2026)
   → student_academic_records += {2026, 2° Básico A, CURSANDO}
   → student_academic_records[2025].status = PROMOVIDO
   → fees[] = 10 cuotas para 2026
   → student.status = MATRICULADO

──── OPCIÓN B: Promoción Masiva ────

1. Admin abre Herramienta de Promoción
2. Selecciona "2025 → 2026"
3. Sistema muestra todos los ACTIVOS de 2025 con sugerencia de curso 2026
4. Admin revisa, ajusta excepciones (repitentes, cambios de sección)
5. Ejecuta promoción:
   → Actualiza cursos masivamente
   → Crea student_academic_records para 2026
   → Marca 2025 como PROMOVIDO
   → Estudiantes quedan como PRE_MATRICULADO (pendiente de matrícula formal)
6. Luego cada guardian completa la matrícula formal (datos económicos, documentos, fees)

──── RESULTADO ────

En StudentsPage filtrado por 2026:
  Juan Pérez │ 2° Básico A │ Matriculado │ 10 cuotas

En StudentsPage filtrado por 2025:
  Juan Pérez │ 1° Básico A │ Promovido │ (histórico, solo lectura)
```

---

## 5. Modelo de Datos Propuesto

### Cambios a tablas existentes

```sql
-- No se requieren cambios de schema en tablas existentes.
-- student_academic_records ya tiene la estructura correcta.
-- Solo se necesita ACTIVAR su uso (escribir datos).
```

### Nuevas funciones RPC

| Función | Propósito | Parámetros |
|---------|-----------|------------|
| `promote_students_batch` | Promoción masiva de un año a otro | `from_year, to_year, student_ids[], dry_run` |
| `get_student_promotion_suggestion` (REESCRIBIR) | Sugerir curso siguiente para un estudiante | `student_id, target_year` |
| `get_students_by_academic_year` | Estudiantes filtrados por año vía `student_academic_records` | `target_year, status_filter` |
| `get_academic_year_stats` | Estadísticas por año para Dashboard | `target_year` |

### Nuevo contexto React

| Archivo | Propósito |
|---------|-----------|
| `src/contexts/AcademicYearContext.jsx` | Año académico global seleccionado |

### Nuevos/modificados componentes

| Archivo | Acción | Propósito |
|---------|--------|-----------|
| `src/components/students/PromotionTool.jsx` | 🆕 CREAR | Herramienta de promoción masiva |
| `src/components/students/AcademicHistoryTab.jsx` | 🆕 CREAR | Tab de historial en StudentDetailsModal |
| `src/components/ui/YearSelector.jsx` | 🆕 CREAR | Componente reutilizable de selector de año |
| `src/components/Sidebar.jsx` | ✏️ MODIFICAR | Agregar YearSelector |
| `src/components/Dashboard.jsx` | ✏️ MODIFICAR | Filtrar por año |
| `src/components/students/StudentsPage.jsx` | ✏️ MODIFICAR | Agregar filtro de año, query por academic_records |
| `src/components/students/StudentsTable.jsx` | ✏️ MODIFICAR | Agregar columna año |
| `src/components/students/StudentDetailsModal.jsx` | ✏️ MODIFICAR | Agregar tab de historial |
| `src/components/payments/PaymentsPage.jsx` | ✏️ MODIFICAR | Usar year_academico |
| `src/components/dashboard/graphs/*` | ✏️ MODIFICAR | Filtrar por año |
| `src/services/feeService.ts` | ✏️ MODIFICAR | Default year del contexto |

---

## 6. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Cursos 2026 no cargados en DB | Alta | Bloqueante | Verificar que existan cursos con `year_academico=2026` antes de promover |
| Datos 2025 inconsistentes (cursos sin año) | Media | Alto | Script de limpieza: asignar `year_academico=2025` a cursos existentes sin año |
| `student_academic_records` vacía | Certeza | Alto | Migración de datos: generar registros 2025 a partir de `students.curso` actual + `enrollments` |
| RPC `finalize_enrollment` ya tiene datos en producción | Alta | Medio | Cambios backwards-compatible: solo agregar lógica, no romper flujo existente |
| Conflicto de status naming | Existente | Confusión | Documentar mapeo claramente; considerar renombrar en DB en migración futura |
| Performance: queries con JOINs adicionales | Baja | Medio | Índices ya existen en `student_academic_records(student_id)`, `(year_academico)`, `(curso_id)` |

---

## 7. Estimación de Esfuerzo

| Fase | Componentes | Estimación |
|------|-------------|------------|
| **Fase 1** — Backend (RPCs, migraciones) | 4 funciones SQL + migración de datos | 6-8 horas |
| **Fase 2** — Módulo Estudiantes | Context + 3 componentes + 2 modificaciones | 8-10 horas |
| **Fase 3** — Dashboard + Payments | 5 componentes modificados | 4-6 horas |
| **Fase 4** — UI/UX + Promoción Masiva | 1 nuevo componente + mejoras visuales | 6-8 horas |
| **Testing & QA** | Verificación de flujos completos | 4-6 horas |
| **TOTAL** | | **28-38 horas** |

### Orden de Prioridad de Implementación

```
1. 🔴 Fase 1.1: Modificar finalize_enrollment (actualizar curso + crear academic_record)
2. 🔴 Fase 1.2: Implementar get_student_promotion_suggestion real
3. 🔴 Fase 2.1: Crear AcademicYearContext
4. 🔴 Fase 2.2: Agregar YearSelector al Sidebar  
5. 🔴 Fase 2.3: Filtrar StudentsPage por año
6. 🟡 Fase 1.3: Crear promote_students_batch
7. 🟡 Fase 3.1: Dashboard filtrado por año
8. 🟡 Fase 3.3: PaymentsPage usar year_academico
9. 🟡 Fase 2.5: StudentDetailsModal con historial
10. 🟢 Fase 4.1: Herramienta de Promoción Masiva (UI)
11. 🟢 Fase 4.2: Correcciones visuales
```

---

## Próximos Pasos

1. **Aprobar este plan** — Confirmar prioridades y alcance.
2. **Verificar datos prerequisitos**:
   - ¿Existen cursos con `year_academico = 2026` en la tabla `cursos`?
   - ¿Cuántos estudiantes tienen `status = 'ACTIVO'` actualmente?
   - ¿Hay enrollments finalizados de 2026 ya existentes?
3. **Crear migración de datos históricos** — Poblar `student_academic_records` con datos 2025 existentes.
4. **Comenzar implementación** por la prioridad indicada.

---

> **Nota:** Este documento es el resultado de una evaluación exhaustiva del código fuente, esquema de base de datos, servicios, componentes UI, y lógica de negocio del sistema Winterhill Cobros v1.1. No se realizaron cambios de código — solo análisis y planificación.
