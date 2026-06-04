# Modulo Horarios y Asistencia (MVP)

## Objetivo

El MVP implementa dos capacidades de negocio:

1. Prevenir colisiones de asignacion de horario para docente, sala y curso.
2. Conciliar marcas de asistencia (entrada/salida) contra horario planificado para detectar incumplimientos.

## Decision de arquitectura

- Persistencia y reglas criticas en Supabase/PostgreSQL.
- Prevencion de solapamiento en DB con `EXCLUDE USING gist` sobre rangos de tiempo.
- RLS habilitado en todas las tablas nuevas y segmentacion por `owner_id`.
- Servicio de orquestacion en Edge Function (`schedule-attendance`) con validacion Zod.

## Modelo de datos (nuevas tablas)

- `salas`: catalogo de salas por owner.
- `docentes_horarios`: bloques planificados por docente y fecha.
- `asistencia_marcas`: marcas crudas de reloj (entrada/salida).
- `asistencia_conciliacion`: resultado diario por docente.
- `asistencia_discrepancias`: incidencias derivadas de la conciliacion.

## Algoritmo de colisiones

En `docentes_horarios` se genera `rango_horario` como `tsrange([inicio, fin))`.
Se aplican tres constraints de exclusion:

1. No solape por docente: (`owner_id`, `rut_docente`, `rango_horario &&`).
2. No solape por sala: (`owner_id`, `sala_id`, `rango_horario &&`).
3. No solape por curso: (`owner_id`, `curso_id`, `rango_horario &&`).

Cuando hay colision, PostgreSQL responde con `23P01`.
La Edge Function traduce ese error a HTTP `409`.

## Algoritmo de conciliacion diaria

Entradas:

- Bloque planificado del dia (inicio/fin).
- Marcas del dia (entrada/salida).
- Tolerancia en minutos (MVP = 1).

Reglas:

1. Si no existe horario: estado `sin_horario`.
2. Si falta entrada o salida: estado `incompleto`.
3. Si existe par entrada/salida:
   - `minutosPlanificados = finPlanificado - inicioPlanificado`
   - `minutosEfectivos = ultimaSalida - primeraEntrada`
   - `minutosAtraso = max(0, atrasoRaw - tolerancia)`
   - `minutosSalidaAnticipada = max(0, salidaRaw - tolerancia)`
4. Estado final:
   - `atraso` si `minutosAtraso > 0`
   - `salida_anticipada` si `minutosSalidaAnticipada > 0`
   - `cumplimiento` en caso contrario

## Conversion de serial Excel

Se usa epoch de Excel `1899-12-30`:

- `date = epoch + serial * 86400000`

Esto permite convertir valores como `46113.3160` a `Date` estandar para persistencia y conciliacion.

## Endpoints iniciales (Edge Function)

Archivo: `supabase/functions/schedule-attendance/index.ts`

Acciones:

- `create_horario`: inserta bloque planificado.
- `create_marca`: inserta marca de asistencia con `fecha_hora_marca` o `excel_serial`.
- `reconcile_day`: calcula y persiste conciliacion diaria + discrepancias.

## Estado actual

- Implementado backend base (DB + Edge Function + validaciones + tests utilitarios).
- Pendiente integracion de UI (`SchedulingBoard`, `AttendanceReport`) y carga de archivos por stream en ruta dedicada.
