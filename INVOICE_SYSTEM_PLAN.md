# 🧾 INVOICE SYSTEM - Sistema de Facturación/Recibos

## 📋 **OBJETIVO**

Desarrollar sistema de **"Generación de recibo"** como **documentación previa a la generación de boleta en SII**.

**Contexto del proyecto:** Módulo 1, línea 18 de proyecto.txt:
> "Generación de recibo (Documentación previa a la generación de boleta en SII)."

---

## 🎯 **ALCANCE DEL MÓDULO**

### Funcionalidad Principal:
**Generar recibos de pago** que servirán como:
1. **Comprobante para apoderados** - Documento que confirma pago realizado
2. **Documentación previa** para posterior generación de boleta oficial en SII
3. **Registro interno** para auditoría y control financiero

### Integración:
- **Base:** Sistema de cobros existente (`gestion.colegiowinterhill.cl`)
- **Conexión:** Sistema de matrícula ya desarrollado (datos de guardian/estudiante)
- **Futuro:** Preparación para integración con SII (Servicio de Impuestos Internos)

---

## 📊 **FLUJO DE TRABAJO**

### Proceso Actual (Sin Sistema):
```
1. Apoderado realiza pago (transferencia/cheque/efectivo)
2. ❌ Administración debe crear recibo manualmente
3. ❌ No hay trazabilidad automática
4. ❌ Proceso manual para boleta en SII
```

### Proceso Con Sistema (Objetivo):
```
1. Apoderado realiza pago
2. ✅ Administrador ingresa pago al sistema
3. ✅ Sistema genera recibo automáticamente
4. ✅ Recibo se envía por email al apoderado
5. ✅ Data queda lista para boleta SII
6. ✅ Trazabilidad completa en DB
```

---

## 🛠 **COMPONENTES A DESARROLLAR**

### 1. **Registro de Pagos**
- Formulario para ingresar pagos recibidos
- Campos: monto, fecha, método de pago, concepto, estudiante
- Validaciones y verificaciones

### 2. **Generación de Recibos**
- Template de recibo (similar a Pagaré)
- Datos dinámicos: guardian, estudiante, monto, fecha, concepto
- Formato PDF descargable/imprimible

### 3. **Gestión de Recibos**
- Lista de recibos generados
- Búsqueda por apoderado/estudiante/fecha
- Re-impresión de recibos

### 4. **Envío Automático**
- Email automático al apoderado con recibo adjunto
- Templates de email personalizables
- Registro de envíos

---

## 📁 **ESTRUCTURA DE DATOS**

### Tabla: `payment_receipts`
```sql
CREATE TABLE payment_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid REFERENCES enrollments(id),
  guardian_id uuid REFERENCES guardians(id),
  amount decimal(10,2) NOT NULL,
  payment_date date NOT NULL,
  payment_method varchar(50), -- 'transferencia', 'cheque', 'efectivo', 'tarjeta'
  concept varchar(200), -- 'matrícula', 'colegiatura', 'materiales', etc.
  receipt_number varchar(50) UNIQUE, -- Numeración correlativa
  notes text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  sent_email boolean DEFAULT false,
  sent_at timestamptz
);
```

### Campos Clave:
- **`receipt_number`:** Numeración correlativa (ej: "REC-2025-001")
- **`concept`:** Tipo de pago (matrícula, colegiatura mensual, materiales)
- **`payment_method`:** Método usado (integrar con formas de pago del Pagaré)
- **`sent_email`:** Control de envío automático

---

## 🎨 **TEMPLATES DE RECIBO**

### Información a incluir:
```
COLEGIO WINTERHILL
RUT: 65.152.884-4

RECIBO DE PAGO N° REC-2025-001

Fecha: 29 de octubre de 2025

DATOS DEL APODERADO:
Nombre: {{guardian_full_name}}
RUT: {{guardian_run}}
Email: {{guardian_email}}

DATOS DEL ESTUDIANTE:
Nombre: {{student_name}}
Curso: {{student_course}}

DETALLE DEL PAGO:
Concepto: {{concept}}
Monto: ${{amount}}
Método de Pago: {{payment_method}}
Fecha de Pago: {{payment_date}}

Este recibo certifica la recepción del pago indicado.

_________________________
Administración
Colegio Winterhill
```

---

## 🔄 **INTEGRACIÓN CON SISTEMA EXISTENTE**

### Conectar con Matrícula:
- Usar datos de `guardians` y `students` ya existentes
- Aprovechar `enrollments` para vincular pagos
- Reutilizar lógica de generación PDF (jsPDF + html2canvas)

### Conectar con Cobros:
- Integrar con sistema de gestión actual
- Usar misma autenticación y permisos
- Sincronizar con estado de pagos

---

## 📈 **FASES DE DESARROLLO**

### Fase 1: Base de Datos y Servicios (1 semana)
- Crear tabla `payment_receipts`
- Servicios CRUD básicos
- Numeración correlativa

### Fase 2: UI para Registro de Pagos (1 semana)
- Formulario de ingreso de pagos
- Búsqueda de guardian/estudiante
- Validaciones

### Fase 3: Generación de Recibos (1 semana)
- Template de recibo
- Generación PDF
- Descarga/impresión

### Fase 4: Envío Automático (1 semana)
- Integración con servicio de email
- Templates de email
- Logs de envío

---

## 🎯 **CRITERIOS DE ÉXITO**

### MVP (Minimum Viable Product):
1. ✅ Registrar pago manualmente
2. ✅ Generar recibo PDF
3. ✅ Descargar/imprimir recibo
4. ✅ Lista de recibos generados

### Funcionalidades Avanzadas:
5. ✅ Envío automático por email
6. ✅ Búsqueda y filtros avanzados
7. ✅ Reportes de pagos
8. ✅ Integración con estados de cuenta

---

## 📋 **PRÓXIMOS PASOS**

### Immediate TODOs:
1. **Diseñar esquema DB** - Crear tabla `payment_receipts`
2. **Crear servicios base** - CRUD operations
3. **Diseñar UI mockups** - Formulario de registro
4. **Definir template recibo** - Layout y campos
5. **Configurar numeración** - Sistema correlativo

### Decisiones Pendientes:
- **Numeración:** ¿Anual? ¿Global? ¿Por tipo de pago?
- **Conceptos:** Lista fija o libre input?
- **Métodos de pago:** ¿Mismo que Pagaré o extender?
- **Permisos:** ¿Quién puede generar recibos?

---

## 🔗 **RELACIÓN CON PROYECTO GENERAL**

Este módulo es parte del **Módulo 1: Mejoras en el Software de Cobros**:
- ✅ **Pagaré:** Ya completado (documentación para cobro futuro)
- 🚧 **Recibos:** En desarrollo (documentación de pago realizado)
- ⏳ **Acceso apoderados:** Futuro (ver situación financiera)
- ⏳ **Emails automáticos:** Futuro (recordatorios de pago)

**BRANCH:** `invoice` - Listo para desarrollo 🚀