# Plan de Mejora: Aranceles 2025, Boleta y Visibilidad de Matrículas

## Objetivo

Resolver tres frentes relacionados en el módulo de Aranceles:

1. Habilitar temporalmente la operación normal sobre el año académico 2025 para regularización de pagos atrasados.
2. Restaurar el campo de número de boleta en el flujo real que usa el equipo al registrar pagos.
3. Corregir la invisibilidad de estudiantes con matrícula confirmada que no aparecen en Aranceles.

## Hallazgos Verificados en el Codebase

### 1. El modo "2025 Consulta" es principalmente un problema de año hardcodeado, no de bloqueo visual directo

- El selector de año solo marca 2025 como `Consulta` a nivel de etiqueta visual; no bloquea acciones por sí mismo.
- El problema real está en que varios flujos de pagos siguen usando `new Date().getFullYear()` en vez del año académico seleccionado.

Referencias:

- `src/components/ui/YearSelector.jsx`: el label `Activo/Consulta` es visual.
- `src/components/payments/StudentFeesModal.jsx`: usa `currentYear` para filtrar cuotas del alumno.
- `src/components/payments/RegisterPaymentModal.jsx`: consulta cuotas disponibles con `currentYear` y no con el año seleccionado.
- `src/components/payments/PaymentDetailsModal.jsx`: al registrar un pago, recalcula `year_academico` desde la fecha de pago.

Impacto:

- Si el usuario está operando en 2025 pero el sistema toma 2026 por calendario o por fecha, las cuotas históricas no aparecen o se actualizan con el año equivocado.
- Esto explica la sensación de que 2025 está "bloqueado" aunque la UI siga permitiendo navegar.

### 2. El número de boleta no desapareció del modal principal, desapareció del flujo alternativo

- El modal principal `RegisterPaymentModal` sí tiene el campo `num_boleta`.
- El flujo alternativo dentro de `PaymentDetailsModal` usa un estado separado (`registerData`) que no incluye `num_boleta`.
- Ese flujo también construye el `update` sin `num_boleta`.

Impacto:

- Si el usuario registra el pago desde el detalle de una cuota pendiente, no puede ingresar número de boleta.
- Esto coincide exactamente con el reporte de usuario: "antes estaba".

### 3. Aranceles no lista estudiantes; lista filas existentes de `fee`

- `PaymentsPage` toma `rawFees` y los filtra por `year_academico`.
- `PaymentsTable` renderiza exclusivamente filas de pago/cuota ya existentes.
- Un estudiante confirmado puede existir en Estudiantes o Matrícula y aun así no aparecer en Aranceles si no tiene cuotas generadas en `fee`.

Impacto:

- El Ticket 3 no es solo un problema de búsqueda por apellido.
- Es una inconsistencia entre matrícula confirmada y generación efectiva de cuotas.

### 4. La generación de cuotas depende del RPC `finalize_enrollment`

- El frontend confirma la matrícula llamando a `finalize_enrollment` mediante `finalizeEnrollmentConfirm`.
- Hay migraciones recientes que corrigen generación de `fee`, `year_academico` y conflictos por cuota.
- Si producción no tiene la última versión de ese RPC, o si hubo matrículas confirmadas antes de las correcciones, habrá alumnos confirmados sin cuotas visibles.

## Causas Raíz Probables

### CR-1. Dependencia indebida del año calendario

Se usan valores como `new Date().getFullYear()` o el año derivado de `payment_date` en flujos donde debería mandar el año académico activo en pantalla.

### CR-2. Divergencia entre dos flujos de registro de pago

Hay dos UX distintas:

- Modal principal de registro.
- Registro rápido desde detalle de cuota.

Solo una de ellas mantiene `num_boleta`.

### CR-3. Vista de Aranceles acoplada a `fee` sin reconciliación con matrícula

Cuando falta la fila `fee`, el alumno desaparece del módulo, aunque la matrícula esté confirmada.

### CR-4. Posible deuda histórica de datos o RPC desactualizado

El codebase contiene migraciones orientadas precisamente a corregir `finalize_enrollment`, `year_academico` y conflictos de cuotas. Es probable que existan datos previos a esas correcciones o ambientes con migraciones incompletas.

## Plan de Implementación

## Fase 1. Hotfix de año académico en Aranceles

Objetivo: que 2025 funcione operativamente sin depender del año calendario.

Tareas:

- Pasar explícitamente `academicYear` a `RegisterPaymentModal` y `StudentFeesModal`.
- Reemplazar todo uso de `currentYear` en pagos por el año académico seleccionado en contexto.
- Evitar recalcular `year_academico` desde `payment_date` al registrar o marcar pagos. Debe prevalecer el año académico de la cuota o el año seleccionado.
- Revisar `PaymentDetailsModal` para que el flujo de registro rápido preserve `payment.year_academico` cuando ya existe.

Resultado esperado:

- 2025 debe mostrar cuotas correctas.
- Registrar pagos en 2025 no debe mover cuotas al año 2026.
- El historial de 2025 debe volver a ser operable para regularización.

## Fase 2. Restaurar número de boleta en el flujo realmente usado

Objetivo: unificar campos mínimos obligatorios/operativos en ambos flujos de pago.

Tareas:

- Agregar `num_boleta` a `registerData` en `PaymentDetailsModal`.
- Renderizar el input correspondiente en la sección `Registrar pago` del detalle.
- Persistir `num_boleta` en `updateFee.mutateAsync(...)` del registro rápido.
- Verificar que recibo, email y detalle muestren el folio correctamente después del registro.
- Revisar si el nombre visible al usuario debe ser `Número de boleta` o `Folio boleta` y estandarizar la etiqueta.

Resultado esperado:

- El usuario puede ingresar boleta tanto desde el modal principal como desde el detalle de la cuota.
- No habrá diferencias funcionales entre ambos flujos.

## Fase 3. Hacer visible a estudiantes confirmados aunque falten cuotas

Objetivo: evitar que una inconsistencia de backend deje al alumno invisible para cobranza.

Tareas de corto plazo:

- Crear una consulta diagnóstica para detectar alumnos con matrícula confirmada y sin filas `fee` para el año académico seleccionado.
- Agregar en Aranceles una vía de búsqueda/selección por estudiante confirmada, aunque no tenga cuotas generadas todavía.
- Mostrar estado explícito: `Matrícula confirmada sin plan de aranceles generado`.

Tareas de mediano plazo:

- Agregar acción administrativa para regenerar cuotas faltantes o abrir el caso con diagnóstico claro.
- Evaluar una vista combinada `students/enrollments + fee` para que Aranceles no dependa solo de `fee`.

Resultado esperado:

- Los hermanos Alarcón Huerta y cualquier caso similar quedan visibles para atención.
- El equipo administrativo entiende si el problema es de datos faltantes o solo de búsqueda.

## Fase 4. Validación backend y saneamiento de datos

Objetivo: asegurar que el frontend no vuelva a ocultar un problema que en realidad es de generación de cuotas.

Tareas:

- Confirmar qué versión de `finalize_enrollment` está desplegada en producción.
- Validar que exista la lógica corregida de `year_academico` y del conflicto por `(student_id, year_academico, numero_cuota)`.
- Identificar matrículas 2026 confirmadas sin cuotas `fee`.
- Preparar script SQL de backfill solo para casos faltantes y con trazabilidad.
- Verificar RLS y permisos de `ADMIN`/`ASIST` sobre `fee` y RPC relacionados.

Resultado esperado:

- Queda claro si el problema es de código frontend, de datos históricos o de migración incompleta.
- Se evita seguir corrigiendo manualmente alumno por alumno.

## Orden Recomendado de Ejecución

1. Corregir dependencia de año en `RegisterPaymentModal`, `StudentFeesModal` y `PaymentDetailsModal`.
2. Restaurar `num_boleta` en el flujo de registro desde detalle.
3. Ejecutar diagnóstico de alumnos confirmados sin cuotas.
4. Diseñar y aplicar backfill controlado para casos faltantes.
5. Mejorar la UX de Aranceles para mostrar casos sin plan generado.

## Validación Técnica Recomendada

### Validación frontend

- Seleccionar año 2025 y confirmar que la tabla ya no queda vacía cuando existan cuotas 2025.
- Abrir detalle de una cuota pendiente y verificar que aparezca el campo de boleta.
- Registrar un pago 2025 y confirmar que la fila siga en `year_academico = 2025`.
- Buscar un alumno confirmado sin cuotas y comprobar que aparezca al menos como caso diagnosticable.

### Validación SQL / Supabase

- Buscar alumnos confirmados 2026 sin `fee`.
- Revisar filas `fee` cuyo `payment_date` sea 2026 pero cuyo `year_academico` debería seguir siendo 2025.
- Validar que `finalize_enrollment` inserte cuotas con `meta.source = 'finalize_enrollment'` y año correcto.

## Riesgos

- Si se usa `payment_date` como fuente de verdad para `year_academico`, se seguirá contaminando el histórico.
- Si solo se arregla la UI y no se sanean datos faltantes, seguirán desapareciendo alumnos confirmados.
- Si el ambiente productivo no tiene las migraciones correctas, el problema reaparecerá tras nuevas confirmaciones de matrícula.

## Preguntas que conviene cerrar antes de implementar

1. ¿La habilitación temporal de 2025 aplica para `ADMIN` y `ASIST`, o solo para `ADMIN`?
2. ¿Cuando un alumno se pone al día, siempre se debe pagar sobre cuotas existentes 2025, o también se permitirán `pagos libres` asociados al año 2025?
3. ¿Quieres que Aranceles muestre alumnos sin cuotas como una fila especial dentro de la misma tabla, o prefieres una sección separada de `Casos por regularizar`?
4. ¿Necesitas que deje preparado además el SQL de diagnóstico para Paula y los casos reportados, o por ahora solo avanzamos con el plan y luego implementamos?