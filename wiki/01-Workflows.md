# Workflows funcionales

Este documento describe los workflows principales de la plataforma, de forma operativa y orientada a soporte.

## 1) Workflow de autenticación y entrada por rol

**Objetivo:** dirigir a cada usuario a su experiencia correcta.

**Rutas clave:**
- Públicas: `/login`, `/register`, `/forgot-password`, `/auth/callback`, `/registro-apoderado`
- Protegidas staff: `/dashboard`, `/students`, `/guardians`, `/payments`, `/reporting`, `/matricula`
- Protegidas apoderado: `/apoderado/bienvenido`, `/apoderado/encuesta`, `/apoderado/portal`, `/apoderado/matricula`

**Flujo:**
1. Usuario inicia sesión (email/password o Google OAuth).
2. La app evalúa autenticación y rol.
3. Redirección raíz:
   - `guardian` → `/apoderado/bienvenido`
   - otros perfiles → `/dashboard`
4. `StaffRoute` protege módulos internos de staff.

**Controles críticos:**
- Validar perfil real del usuario (`ADMIN`, `ASIST`, `READONLY`).
- Si no hay perfil, el sistema aplica mínimo privilegio (`READONLY`).

---

## 2) Workflow diario de staff (operación base)

**Objetivo:** iniciar jornada y priorizar trabajo.

**Actor:** `ADMIN` / `ASIST` / `READONLY`.

**Flujo:**
1. Ingreso a `/dashboard`.
2. Selección de año lectivo.
3. Revisión de KPIs: pendientes, vencidos, morosidad.
4. Derivación a módulos:
   - alumnos/apoderados para completar datos,
   - pagos para regularizar deudas,
   - matrícula para emisión de documentos.

**Checklist rápido:**
- Año correcto.
- Alertas sin resolver.
- Permisos del operador correctos para la tarea.

---

## 3) Workflow de gestión de estudiantes y apoderados

**Objetivo:** mantener padrón y relaciones correctas.

### 3.1 Alta/edición de estudiante
1. Ir a `/students`.
2. Crear o editar estudiante (RUN, nombres, curso, contacto).
3. Validar duplicados y curso existente.
4. Guardar y confirmar aparición en listado.

**Errores típicos:**
- `23505` RUN duplicado.
- `23503` curso inválido.
- `42501` permisos/RLS insuficientes.

### 3.2 Alta/edición de apoderado
1. Ir a `/guardians`.
2. Registrar datos personales y de contacto.
3. Vincular estudiante(s) en relación estudiante-apoderado.
4. Completar intake (domicilio, profesión, estado civil) cuando aplique.

**Resultado esperado:**
- Relación estudiante–apoderado consistente para matrícula y portal.

---

## 4) Workflow de matrícula y pagaré (wizard)

**Objetivo:** generar documento contractual en flujo guiado.

**Ruta:** `/matricula`

**Etapas:**
1. **Seleccionar Alumnos**
2. **Datos Económicos**
3. **Vista Previa y Descarga**

**Flujo operativo:**
1. Seleccionar apoderado/alumnos.
2. Ingresar datos económicos (colegiatura, cuotas, vencimiento, descuentos).
3. Generar vista previa HTML del documento.
4. Acción final:
   - **Descargar PDF** (generación cliente), o
   - **Imprimir**.

**Cambio importante de arquitectura:**
- Se eliminó generación de PDF en servidor para este flujo base.
- Se prioriza preview + descarga local para evitar fallos RLS y reducir latencia.

**Controles críticos:**
- Verificar que la vista previa tenga alumnos y montos correctos.
- Confirmar estado de regularización/deuda cuando aplique.

---

## 5) Workflow de pagos y aranceles

**Objetivo:** registrar y controlar cuotas pagadas/pendientes/vencidas.

**Ruta:** `/payments`

**Flujo:**
1. Aplicar filtros (estado, curso, cuota, fechas, método, búsqueda).
2. Abrir registro de pago.
3. Asociar estudiante + cuota.
4. Guardar método, monto y observaciones.
5. Revisar detalle en modal de pago.

**Permisos esperados:**
- Registro de pago asociado a cuota: perfiles operativos.
- Edición/eliminación: restringido (según política activa, normalmente `ADMIN`).
- Pago libre: restringido por perfil.

**Punto de control:**
- Evitar reasignación de estudiante en edición de pago; preferir anular y recrear cuando sea necesario.

---

## 6) Workflow del portal de apoderados

**Objetivo:** autoservicio para estado de matrícula, aranceles y documentos.

**Rutas:**
- `/apoderado/bienvenido`
- `/apoderado/encuesta`
- `/apoderado/portal`
- `/apoderado/matricula`

**Flujo:**
1. Apoderado entra y completa/actualiza encuesta (`intake`).
2. Visualiza estado de matrícula y pagos.
3. Revisa alumnos asociados y detalle de cuotas.
4. Accede a documentos disponibles.

**Bloqueos frecuentes:**
- Apoderado sin estudiantes vinculados.
- Intake incompleto.
- Datos de relación desactualizados.

---

## 7) Workflow de reportes y exportaciones

**Objetivo:** análisis y conciliación operacional.

**Ruta:** `/reporting`

**Flujo:**
1. Definir rango de fechas y filtros de negocio.
2. Consultar resultados en tabla/gráficos.
3. Exportar (CSV/Excel) para análisis externo.

**Buenas prácticas:**
- Exportar con el mismo año lectivo activo.
- Guardar snapshot de filtro para trazabilidad.

---

## 8) Workflow de incidencias operativas (runbook mínimo)

**Objetivo:** reducir tiempo de resolución ante errores comunes.

1. Capturar error exacto (código + módulo + acción).
2. Verificar rol/permisos del usuario.
3. Verificar datos maestros (curso, relaciones, año, RUN).
4. Reintentar flujo de punta a punta.
5. Si persiste, escalar con evidencia (captura + hora + usuario + pasos).

---

## Próxima iteración recomendada de la wiki

1. Convertir `04-Arquitectura.md` en diagrama C4 (contexto/contenedores/componentes).
2. Consolidar diccionario de datos por módulo (partiendo de `03-Modelo-Datos-RLS.md`).
3. Consolidar matriz formal de permisos por acción (partiendo de `02-RBAC.md`).
4. Expandir `06-Operacion-Soporte.md` con playbooks por severidad (SEV1/SEV2/SEV3).
5. Guías por rol: `ADMIN`, `ASIST`, `READONLY`, `guardian`.
