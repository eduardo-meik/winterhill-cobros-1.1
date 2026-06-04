# Manual de Uso - Plataforma Winterhill Cobros

## 1. Proposito y Alcance
Este manual describe el uso operacional de la plataforma de cobros escolares Winterhill. Cubre los flujos diarios de administradores, asistentes y apoderados, desde el acceso hasta la emision de documentos y seguimiento de pagos.

## 2. Acceso y Roles
### 2.1 Metodos de autenticacion
- Inicio con correo y contrasena registrados en Supabase.
- Inicio mediante Google OAuth (configurado via GOOGLE_AUTH_SETUP.md). Los datos basicos del perfil se completan automaticamente.

### 2.2 Perfiles y permisos
| Perfil | Uso previsto | Capacidades clave |
| --- | --- | --- |
| ADMIN | Equipo de tesoreria / TI | Acceso completo a estudiantes, pagos, documentos y configuraciones. Puede crear pagos libres y modificar registros. |
| ASISTENTE | Personal de apoyo en cobranzas | Gestiona matriculas, visualiza reportes y registra pagos vinculados a cuotas. No elimina ni crea pagos libres. |
| SOLO LECTURA | Directivos o auditores | Navega el dashboard y exporta reportes sin modificar datos. |

### 2.3 Indicadores visuales
Los componentes `usePermissions` muestran chips de estado ("Acceso Completo", "Asistente", "Solo Lectura") y ocultan automaticamente acciones restringidas.

## 3. Interfaz del Usuario y Modulos Principales
La plataforma se divide en contenedores consistentes para todos los perfiles. Conocer su objetivo acelera la operacion diaria.

### 3.1 Barra lateral (Navigation Rail)
- **Ubicacion**: margen izquierdo en desktop; menu plegable en mobile.
- **Objetivo**: brindar acceso directo a los grandes modulos funcionales.
- **Secciones habituales**:
   1. Dashboard (inicio rapido y KPIs).
   2. Estudiantes.
   3. Apoderados.
   4. Pagos / Aranceles.
   5. Documentos (pagares, contratos, recibos).
   6. Reportes.
   7. Configuracion.
- **Comportamiento**: el item activo se resalta y muestra breadcrumb en la parte superior del contenido.

### 3.2 Barra superior (Top Bar)
- Selector de anio lectivo con persistencia (localStorage) que afecta consultas de estudiantes, pagos y reportes.
- Buscador global por RUN, nombre de alumno o apoderado.
- Menu de usuario con avatar, datos basicos y chips de permiso (`Acceso Completo`, `Asistente`, etc.). Desde aqui se accede a cerrar sesion.
- Indicadores rapidos (campanas) muestran tareas pendientes como matriculas incompletas o pagos vencidos.

### 3.3 Dashboard inicial
| Widget | Objetivo | Accion rapida |
| --- | --- | --- |
| KPIs de morosidad | Mostrar total pagado, pendiente y vencido | Botones que llevan al filtro correspondiente en Pagos |
| Proximos vencimientos | Lista de cuotas por vencer en 15 dias | Crear recordatorio o registrar pago |
| Atajos de matricula | Guiar a crear pagaré o editar datos economicos | Abre el Matricula Wizard en el paso adecuado |
| Alertas del sistema | Notificar errores de RLS, migraciones pendientes o tareas de intake | Link a checklist asociado |

### 3.4 Modulos funcionales de contenido
1. **Estudiantes**: tabla filtrable con chips de curso, buscador por RUN, acciones para ver detalles y abrir relacion con apoderados. Objetivo: mantener el padrón actualizado.
2. **Apoderados**: muestra contactos principales, estado de la encuesta e historico de documentos. Objetivo: centralizar datos contractuales y generar permisos para el portal externo.
3. **Pagos**: tarjetas resumen + tabla `FeeTable` con ordenamiento, color por estado y acceso al modal `PaymentDetailsModal`. Objetivo: registrar, revisar y corregir cuotas.
4. **Matricula Wizard**: flujo guiado de seleccion de alumnos, datos economicos y vista previa/descarga del pagaré. Objetivo: emitir documentos listos para firma en minutos.
5. **Documentos**: listado de generar/descargar pagarés y contratos. Objetivo: reutilizar contenido guardado y facilitar reenvios por correo.
6. **Reportes**: panel de filtros + exportadores CSV/Excel. Objetivo: alimentar conciliaciones y auditorias.
7. **Portal Apoderado (vista interna)**: simulacion del dashboard que ven los tutores (AlertBanner, StatusDashboard, FeeSummary). Objetivo: validar contenido antes de publicar y ofrecer soporte.

### 3.5 Componentes transversales
- **Modales contextuales**: se activan con botones primarios (Registrar Pago, Editar Estudiante). Incluyen indicadores visuales de permisos.
- **Toasts/Alertas**: confirman guardados o muestran errores 4xx/5xx con referencia al codigo Supabase.
- **Indicadores de carga**: skeletons y spinners en tablas largas para evitar interacciones mientras el fetch no termina.
- **Modo oscuro**: los tokens Tailwind aseguran contraste en ambos temas.

## 4. Workflow de Gestion de Estudiantes y Apoderados
### 4.1 Alta de estudiante (Rol ADMIN)
1. Ingresar a `Estudiantes > Nuevo`.
2. Completar RUN, nombres, curso y datos de contacto.
3. Verificar que el curso exista (`public.cursos`).
4. Confirmar que el perfil del usuario tenga `role = 'ADMIN'` en `public.profiles` (ver checklist `ADMIN_STUDENT_REGISTRATION_CHECKLIST.md`).
5. Guardar. El sistema valida duplicados de RUN, campos obligatorios y restricciones RLS.

### 4.2 Edicion y errores frecuentes
- **RLS 42501**: revisar funcion `get_current_user_role()` y perfil del administrador.
- **FK 23503**: curso inexistente. Seleccionar un curso valido.
- **Unique 23505**: RUN duplicado; revisar si el estudiante ya existe.

### 4.3 Gestion de apoderados
1. Acceder a `Apoderados`.
2. Crear o actualizar datos personales y relacion con estudiantes (tabla `student_guardian`).
3. Utilizar el formulario de intake para capturar domicilio, profesion y estado civil (ver `GUARDIAN_PROFESION_ESTADO_CIVIL.md`).

## 5. Workflow de Matricula y Pagare digital
### 5.1 Resumen del proceso
El flujo se ejecuta en `Matricula > Wizard` y consta de tres etapas:
0. **Seleccionar Alumnos**: elegir uno o mas estudiantes asociados al apoderado.
1. **Datos Economicos**: definir colegiatura anual, cantidad de cuotas, monto de matricula y descuentos.
2. **Vista Previa y Descarga**: revisar el contrato HTML, descargar o imprimir.

### 5.2 Generacion del documento
1. Completar los pasos 0 y 1 y presionar `Generar Vista Previa`.
2. Revisar la tarjeta con el HTML con bordes y estilos corporativos (ver `WORKFLOW_UPDATE_SUMMARY.md`).
3. En `Acciones del Documento` elegir:
   - `Descargar PDF`: usa `generatePDFFromHTML` en el navegador. El archivo incluye logo proporcional, folio automatico, tablas con 15px de margen y saltos preservados (`MEJORAS_PDF_PAGARE.md`).
   - `Imprimir`: abre la vista HTML en una nueva ventana lista para imprimir.
   - `Editar Datos`: regresa al paso economico.

### 5.3 Detalles del PDF
- Logos cargados desde `/public/logo-winterhill.png` (timeout 3s). Si falta, el header se muestra solo con texto.
- Folio `FOLIO N° XXXXXXXX` generado desde el `documentRecord.id` o timestamp.
- Margenes inferiores: 80 mm con firmas y 30 mm sin firmas.
- Marca de agua eliminada; se envia documento limpio.
- Tablas con `page-break-inside: avoid` para evitar cortes.

### 5.4 Recomendaciones de prueba
1. Generar pagaré con al menos un alumno y verificar header completo.
2. Descargar y revisar que las tablas no se superpongan.
3. Forzar contenido extenso para validar saltos de pagina.

## 6. Workflow de Pagos y Aranceles
### 6.1 Panel de pagos
- Ubicacion: `Pagos > Resumen`.
- Vista de tarjetas con total pagado, pendiente y vencido.
- Barra de filtros por curso, estado (paid/pending/overdue) y mes.

### 6.2 Registrar un pago
1. Seleccionar `Registrar Pago`.
2. Elegir estudiante y cuota a aplicar. Todos los perfiles pueden registrar pagos vinculados a cuota.
3. Ingresar monto, metodo (transferencia, cheque, efectivo, tarjeta) y notas.
4. Solo ADMIN/ASIST pueden usar `Pago libre` para montos no asociados a cuota.
5. Guardar para que el pago quede ligado a la tabla `fee`.

### 6.3 Editar o eliminar un pago
- Solo ADMIN visualiza botones `Editar` y `Eliminar`.
- En `PaymentDetailsModal` los datos del estudiante se muestran en modo solo lectura para evitar reassignacion (ver `PAYMENT_EDIT_STUDENT_PERSISTENCE.md`).
- Para corregir asignacion de estudiante, se recomienda anular el pago y crear uno nuevo.

### 6.4 Permisos rapidos
- `canCreateSpecificPayment`: todos los perfiles operativos.
- `showFreePaymentOption`: ADMIN (y asistentes si se habilita temporalmente).
- `showEditPaymentButton` / `showDeletePaymentButton`: exclusivos ADMIN.

## 7. Workflow del Portal de Apoderados
### 7.1 Componentes principales
- **AlertBanner**: comunica estado de intake, pagos y matricula.
- **StatusDashboard**: tres tarjetas (Intake, Pagos, Matricula) con iconos y acciones.
- **Tabbed Navigation**: Resumen, Estudiantes, Aranceles, Documentos.

### 7.2 Resumen
- Datos del apoderado, acciones rapidas y progreso de encuestas.
- Graficas de pagos pagados vs pendientes.

### 7.3 Estudiantes
1. Cada tarjeta muestra nombre, RUN, curso y resumen de cuotas.
2. Secciones expandibles para datos personales, academicos e informacion de contacto.
3. Acceso rapidos a `Ver cuotas` o `Descargar reportes`.

### 7.4 Aranceles y pagos
- `FeeSummary`: barras por estado (verde pagado, amarillo pendiente, rojo vencido).
- `FeeTable`: columna de cuota, estudiante, monto, vencimiento, estado, fecha de pago y acciones. Permite filtrar/ordenar.
- `PaymentHistory`: lista cronologica con metodo, numero de documento y observaciones.

### 7.5 Documentos
- Espacio reservado para descargar pagarés y otros contratos cuando se habilite el almacenamiento en servidor.

### 7.6 Servicios de datos
- Hooks `useGuardianFees`, `useStudentData` y `useFeeStats` proveen caching y refresco.
- Consultas SQL recomendadas disponibles en `GUARDIAN_PORTAL_UI_PLAN.md`.

## 8. Reportes y Exportaciones
1. Navegar a `Reportes`.
2. Seleccionar rango de fechas y filtros (curso, estado de pago, tipo de documento).
3. Exportar a CSV/Excel para conciliaciones externas.
4. Para estadisticas rapidas, usar graficos en Dashboard o `FeeSummary`.

## 9. Buenas Practicas Operativas
- Mantener actualizados los logos y datos corporativos del header para todos los PDFs.
- Revisar que el `.env.local` contenga las claves correctas antes de desplegar (ver README).
- Despues de cambios en RLS, realizar smoke test de registro de estudiantes y generacion de pagaré.
- Registrar evidencias (capturas y errores) cuando aparezca un mensaje de Supabase para acelerar soporte.

## 10. Resolucion de Problemas Rapidos
| Sintoma | Causa probable | Accion |
| --- | --- | --- |
| Boton Registrar Pago deshabilitado | Perfil sin permisos | Revisar `usePermissions` y asignar rol correcto en perfiles. |
| Error 42501 al crear estudiante | RLS bloquea al usuario | Confirmar perfil ADMIN, funcion `get_current_user_role` y politicas `students_admin_access`. |
| Logo no aparece en PDF | Archivo ausente o ruta incorrecta | Subir `public/logo-winterhill.png` y refrescar cache. |
| PDF con texto cortado | HTML sin margenes | Confirmar que las tablas tengan estilos aplicados y regenerar vista previa. |
| Portal apoderado sin datos | Guardian sin estudiantes vinculados | Revisar tabla `student_guardian` y sincronizar relaciones. |

## 11. Referencias Cruzadas
- `README.md`: configuracion tecnica y scripts `npm`.
- `WORKFLOW_UPDATE_SUMMARY.md`: detalles del wizard de matricula.
- `MEJORAS_PDF_PAGARE.md`: especificacion visual del PDF.
- `PAYMENT_EDIT_STUDENT_PERSISTENCE.md`: reglas de edicion de pagos.
- `GUARDIAN_PORTAL_UI_PLAN.md`: diseno del portal de apoderados.
- `ADMIN_STUDENT_REGISTRATION_CHECKLIST.md`: verificacion de permisos para altas.

## 12. Guía Operativa para Perfil ASIST
### 12.1 Primer arranque diario
1. **Inicia sesión** mediante Google OAuth o credenciales email/password desde `https://app.winterhill.cl`.
2. **Confirma tu rol**: abre el menú de usuario y verifica que el chip muestre `Asistente`. Si aparece `Solo Lectura`, solicita a un ADMIN que actualice tu perfil en `public.profiles`.
3. **Selecciona el año lectivo** en la barra superior; la mayoría de vistas filtran datos según este selector.
4. **Revisa alertas críticas** en el dashboard (morosidad, pendientes de matrícula) para priorizar tareas.

### 12.2 Registro express de estudiante (ASIST)
> Este flujo está habilitado solo si la política local otorga permisos de inserción al rol ASIST. Si recibes error `42501`, escala al equipo ADMIN.

**Checklist operativo**
1. Ir a `Estudiantes > Nuevo` y validar que el formulario muestre el año correcto.
2. Completar los campos obligatorios:
   - RUN con dígito verificador.
   - Nombres y apellidos (se guardan en mayúsculas automáticamente).
   - Curso: seleccionar de la lista cargada desde `public.cursos`.
   - Datos de contacto mínimo (correo y teléfono del apoderado principal).
3. Adjuntar apoderado existente buscando por RUN; si no existe, deja temporalmente vacío y registra en el paso 12.3.
4. Guardar. El sistema ejecuta estas validaciones inmediatas:
   - RUN duplicado → bloquea el guardado (código `23505`).
   - Curso inexistente → muestra error de referencia (`23503`).
   - Campos faltantes → indica los inputs en rojo (`23502`).
5. Tras el guardado exitoso, confirma que el alumno aparezca en el listado filtrado por curso y asigna el apoderado desde la pestaña de relaciones si quedó pendiente.

### 12.3 Creación/actualización de apoderado
1. Entrar a `Apoderados > Nuevo` o seleccionar un registro existente para editar.
2. Registrar datos clave: RUN, nombres completos, estado civil, profesión y dirección (estos campos se utilizan en el pagaré y en el portal de apoderados).
3. Asociar estudiantes mediante la tabla de relaciones:
   - Buscar por nombre/RUN.
   - Definir rol (tutor principal, financiero, etc.).
   - Guardar cambios para que la tabla `student_guardian` quede sincronizada.
4. Completar el formulario de intake (domicilio, ocupación, información socioeconómica) desde la pestaña “Encuesta”. Esto alimenta los reportes y el portal externo (`GUARDIAN_PROFESION_ESTADO_CIVIL.md`).
5. Verificar en el panel lateral que el estado de la encuesta cambie a “Completada”.

### 12.4 Registro rápido de pago asociado a cuota
1. Desde `Pagos > Resumen`, pulsa `Registrar Pago`.
2. Selecciona el estudiante; el sistema muestra las cuotas pendientes para facilitar la asociación.
3. Elegir la cuota correspondiente (ej. “Cuota 03 - Abril”) y confirmar el monto sugerido. Puedes editarlo si hubo abono parcial.
4. Ingresar método de pago (transferencia, cheque, efectivo, tarjeta) y, opcionalmente, número de documento.
5. Mantén desactivada la opción “Pago libre” (solo visible para ADMIN). Si aparece activa por error, evita usarla y reporta el caso.
6. Guardar. Se crea un registro en `fee_payments` vinculado a la cuota; la tarjeta de estado del estudiante se actualiza inmediatamente.
7. Emitir comprobante si el flujo local lo requiere (descarga PDF o nota manual).

### 12.5 Resumen de acciones frecuentes
| Objetivo | Ruta | Validaciones clave | Resultado esperado |
| --- | --- | --- | --- |
| Alta de estudiante | `Estudiantes > Nuevo` | RUN único, curso válido, permisos ASIST | Estudiante visible en listados y asociado a apoderado. |
| Registro/edición de apoderado | `Apoderados > Nuevo/Editar` | RUN único, encuesta completa | Apoderado disponible para matrículas y portal externo. |
| Registro de pago | `Pagos > Registrar Pago` | Cuota seleccionada, método válido, sin pago libre | Cuota marcada como pagada y totales actualizados. |

Mantén esta guía impresa o accesible durante los turnos; reduce tiempos de respuesta y ayuda a detectar rápidamente si un error proviene de permisos (ASIST) o de datos incompletos.
