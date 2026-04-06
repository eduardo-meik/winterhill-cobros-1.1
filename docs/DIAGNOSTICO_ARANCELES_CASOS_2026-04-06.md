# Diagnostico de Casos de Aranceles 2026

> Nota de vigencia: este diagnostico refleja la revision original del 2026-04-06. Una validacion posterior sobre la base viva mostro que los hermanos Alarcon Huerta ya cuentan con 10 cuotas 2026 generadas por una reparacion previa (`update_20260316.csv` / `unexpected_fee_2026_missing_repair`).

## Resumen

Se revisaron cinco alumnos directamente en Supabase usando `students`, `enrollment_students`, `enrollments`, `cursos` y `fee`.

## Hallazgos por alumno

### ARA IGNACIA SILVA VARGAS

- Estado estudiante: `ACTIVO`.
- Curso actual: `5° BASICO A` 2026.
- Matricula 2026: `completed`.
- Cuotas `fee`: 10 para 2026 y 10 para 2025.

Conclusion: desde el punto de vista de Aranceles, este caso esta estructuralmente sano.

### AYUN CEPEDA FOXON

- Estado estudiante: `RETIRADO`.
- Curso actual: `7° BASICO A` 2026.
- Matricula 2026: `completed`.
- Cuotas `fee`: 10 para 2026.

Conclusion: el problema aqui no es ausencia de cuotas, sino inconsistencia de estado academico. Tiene matricula 2026 completada y cuotas generadas, pero en `students.estado_std` figura `RETIRADO`.

### SANTIAGO MATTIA PAZ

- Estado estudiante: `ACTIVO`.
- Curso actual: `2° BASICO A` 2026.
- Matricula 2026: `completed`.
- Cuotas `fee`: 10 para 2026 y 1 fila legacy en 2025.

Observaciones:

- `whole_name` viene con espacio final.
- `run_numero` esta `NULL` aunque el `run` formateado existe.

Conclusion: Aranceles 2026 existe y deberia ser cobrable. Hay deuda tecnica en normalizacion de datos, pero no falta el plan 2026.

### LETICIA COLOMBA ALARCON HUERTA

- Estado estudiante: `ACTIVO`.
- Curso actual: `5° BASICO A` 2026.
- Matricula 2026: `completed`.
- Cuotas `fee`: 10 para 2025 y solo 1 fila para 2026.

Observaciones:

- La unica fila 2026 esta `paid`.
- La fila 2026 no viene de `finalize_enrollment`; su `meta.source` apunta a `update_20260316.csv` con `sync_reason = monthly_correction_from_user_list`.

Conclusion: este caso esta incompleto para 2026. No existe plan de cuotas 2026 normal; existe solo una correccion manual aislada.

### SANTIAGO AMARO ALARCON HUERTA

- Estado estudiante: `ACTIVO`.
- Curso actual: `4° MEDIO B` 2026.
- Matricula 2026: `completed`.
- Cuotas `fee`: 10 para 2025 y 0 para 2026.

Conclusion: este es el caso mas claro de matricula confirmada sin generacion de aranceles 2026.

## Hallazgo comun de los hermanos Alarcon Huerta

- Ambos comparten la matricula `ENR-2026-000252`.
- La `meta` de esa matricula es minima y no contiene `payment_plan` ni `per_student_plans`.
- Eso contrasta con los casos sanos revisados, donde la `meta` si guarda plan de pago o estructura economica por alumno.

Hipotesis tecnica fuerte: la matricula se completo sin que quedara persistido un plan utilizable para `finalize_enrollment`, o quedo afectada por una version previa/incompleta del flujo.

## Implicancias para Aranceles

- Leticia puede quedar oculta si el filtro esta en `Por Cobrar`, porque su unica fila 2026 esta `paid`.
- Santiago Amaro nunca aparecera en Aranceles 2026 mientras no existan filas `fee` para 2026.
- AYUN puede aparecer como caso inconsistente entre cobranza y estado academico.

## Archivos relacionados

- SQL de diagnostico reusable: `sql/diagnose_aranceles_cases_20260406.sql`
- Plan de implementacion: `docs/PLAN_MEJORA_ARANCELES_2025_BOLETA_2026-04-06.md`