# Actualización del Pagaré - Datos Dinámicos Completos

**Fecha:** 27 de octubre de 2025  
**Cambios:** Integración de todos los datos del apoderado, estudiantes y económicos

---

## 🎯 Cambios Realizados

### 1. **Plantilla `contratos/pagare.txt` Actualizada**

#### ✅ Nuevos Placeholders Agregados:

**Fecha Automática:**
- `{{fecha_actual}}` - Genera automáticamente la fecha actual en español (Ej: "27 de octubre del 2025")

**Datos del Apoderado (desde tabla `guardians`):**
- `{{guardian_full_name}}` - Nombre completo del apoderado
- `{{guardian_run}}` - RUT del apoderado
- `{{guardian_address}}` - Dirección del apoderado
- `{{guardian_email}}` - Email del apoderado
- `{{guardian_phone}}` - Teléfono del apoderado
- `{{guardian_nacionalidad}}` - Nacionalidad (default: "Chilena")
- `{{guardian_profesion}}` - Profesión u oficio
- `{{guardian_estado_civil}}` - Estado civil

**Datos de Estudiantes (desde tabla `students`):**
- `{{students_table}}` - Tabla HTML con:
  - Número (índice)
  - Nombre completo
  - RUT
  - Curso año {{year}}

**Datos Económicos (desde formulario):**
- `{{monto_matricula}}` - Monto de la matrícula (nuevo campo)
- `{{colegiatura_anual}}` - Colegiatura anual
- `{{cantidad_cuotas}}` - Cantidad de cuotas
- `{{monto_cuota}}` - Monto por cuota
- `{{dia_vencimiento}}` - Día de vencimiento (1-28)

**Forma de Pago (desde encuesta/formulario):**
- `{{forma_pago_cheques}}` - ☑ o ☐
- `{{forma_pago_transferencia}}` - ☑ o ☐
- `{{forma_pago_efectivo}}` - ☑ o ☐
- `{{forma_pago_tarjeta}}` - ☑ o ☐

**Año Dinámico:**
- `{{year}}` - Año académico seleccionado

---

### 2. **Actualización de `src/services/matricula.ts`**

#### **Interface `PagarePayload` Expandida:**

```typescript
export interface PagarePayload {
  // Fecha automática
  fecha_actual: string;
  
  // Datos completos del apoderado
  guardian_full_name: string;
  guardian_run: string;
  guardian_address: string;
  guardian_email: string;
  guardian_phone: string;
  guardian_nacionalidad: string;  // NUEVO
  guardian_profesion: string;      // NUEVO
  guardian_estado_civil: string;   // NUEVO
  
  // Año
  year: number;
  
  // Tabla de estudiantes
  students_table: string;
  
  // Datos económicos expandidos
  monto_matricula?: number | string;  // NUEVO
  colegiatura_anual?: number | string;
  cantidad_cuotas?: number | string;
  monto_cuota?: number | string;
  dia_vencimiento?: number | string;
  
  // Forma de pago (desde encuesta)
  forma_pago_cheques?: string;        // NUEVO
  forma_pago_transferencia?: string;  // NUEVO
  forma_pago_efectivo?: string;       // NUEVO
  forma_pago_tarjeta?: string;        // NUEVO
}
```

#### **Función `buildPagarePayload()` Mejorada:**

**Nuevas Características:**

1. **Generación Automática de Fecha:**
   ```typescript
   const now = new Date();
   const months = ['enero', 'febrero', ...];
   const fecha_actual = `${day} de ${month} del ${yearFull}`;
   ```

2. **Tabla de Estudiantes con Formato HTML:**
   ```typescript
   const studentsTable = `<table border="1" cellpadding="5" ...>
     <thead><tr><th>Número</th><th>Nombre</th>...</tr></thead>
     <tbody>${tableRows}</tbody>
   </table>`;
   ```

3. **Formato de Moneda Chileno:**
   ```typescript
   const formatCurrency = (value) => {
     return num.toLocaleString('es-CL'); // Ej: 3.600.000
   };
   ```

4. **Checkboxes para Forma de Pago:**
   ```typescript
   forma_pago_cheques: paymentMethod?.cheques ? '☑' : '☐',
   forma_pago_transferencia: paymentMethod?.transferencia ? '☑' : '☐',
   ...
   ```

5. **Valores por Defecto:**
   - Nacionalidad: "Chilena" (si no está en DB)
   - Campos vacíos: `'_______________'` (línea para completar)
   - Números faltantes: `'_______________'`

---

### 3. **Actualización de `src/components/matricula/MatriculaWizard.jsx`**

#### **Nuevo Estado `economic`:**

```jsx
const [economic, setEconomic] = useState({
  monto_matricula: '',     // NUEVO
  colegiatura_anual: '',
  cantidad_cuotas: '10',
  monto_cuota: '',
  dia_vencimiento: '5'
});
```

#### **Nuevo Estado `paymentMethod`:**

```jsx
const [paymentMethod, setPaymentMethod] = useState({
  cheques: false,
  transferencia: true,  // Por defecto
  efectivo: false,
  tarjeta: false
});
```

#### **Paso 1 (Datos Económicos) Renovado:**

**Nuevos Campos:**
- 💰 **Monto Matrícula** - Input numérico con placeholder
- 💰 **Colegiatura Anual** - Input numérico
- 💰 **Cantidad Cuotas** - Input numérico
- 💰 **Monto por Cuota** - Input numérico
- 💰 **Día Vencimiento** - Input numérico (1-28)

**Nueva Sección: Forma de Pago**
- 📝 **Cheques** - Checkbox
- 💸 **Transferencia Electrónica** - Checkbox (marcada por defecto)
- 💵 **Pago en Efectivo** - Checkbox
- 💳 **Tarjeta de Crédito** - Checkbox

**Diseño Mejorado:**
- Secciones separadas con bordes
- Labels con iconos emoji
- Hover effects en checkboxes
- Grid responsive (2 columnas en desktop)

#### **Función `handleGeneratePagare()` Actualizada:**

```jsx
const payload = buildPagarePayload({ 
  guardian, 
  year, 
  students, 
  economic: econNumbers,
  paymentMethod  // ← NUEVO parámetro
});
```

---

## 📊 Ejemplo de Salida

### Antes (placeholders vacíos):
```
En Viña del Mar, a _____ de _____ del 202__ entre...
Don(a), _____ (nacionalidad) _____ (profesión u oficio)...
cédula de identidad N° _____ domiciliado/a en: _____

Por concepto de matricula, al contado, la suma de $ _____
Por concepto de colegiatura anual, el monto correspondiente a
_____ dividido en _____ cuotas mensuales de _____
```

### Después (datos dinámicos):
```
En Viña del Mar, a 27 de octubre del 2025 entre...
Don(a), ESTER ESTAY (nacionalidad) Chilena (profesión u oficio) Profesora
cédula de identidad N° 10.710.002-4 domiciliado/a en: STA MARGARITA 237 C BELLAVISTA

Por concepto de matricula, al contado, la suma de $ 150.000
Por concepto de colegiatura anual, el monto correspondiente a
$3.600.000 dividido en 10 cuotas mensuales de $360.000 cada una para el día 5 de cada mes.

EL/LA APODERADO/A pagará... en la siguiente forma:
Cheques: ☐ Transferencia Electrónica: ☑ Pago en efectivo: ☐ Tarjeta de Crédito: ☐
```

### Tabla de Estudiantes:
```html
<table border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse;">
  <thead>
    <tr style="background-color: #f0f0f0;">
      <th>Número</th>
      <th>Nombre</th>
      <th>RUT</th>
      <th>Curso año 2025</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Juan Pérez González</td>
      <td>23.456.789-0</td>
      <td>3° Básico</td>
    </tr>
    <tr>
      <td>2</td>
      <td>María Pérez González</td>
      <td>24.567.890-1</td>
      <td>1° Medio</td>
    </tr>
  </tbody>
</table>
```

---

## 🔧 Campos de la Tabla `guardians` Necesarios

Para que todos los placeholders funcionen, la tabla `guardians` debe tener:

### ✅ Campos Existentes:
- `first_name` - Nombre
- `last_name` - Apellido
- `run` - RUT
- `address` - Dirección
- `email` - Email
- `phone` - Teléfono

### ❓ Campos Opcionales (si existen en tu DB):
- `nacionalidad` - Nacionalidad (default: "Chilena")
- `profesion` - Profesión u oficio (default: "_______________")
- `estado_civil` - Estado civil (default: "_______________")

**Nota:** Si estos campos no existen en la tabla, el sistema mostrará valores por defecto o líneas para completar manualmente.

---

## 🧪 Prueba del Sistema

### Paso 1: Navegar a Matrícula
1. Ir a la página de Matrícula
2. Agregar al menos 1 estudiante (Step 0)

### Paso 2: Llenar Datos Económicos (Step 1)
Ingresar:
- **Monto Matrícula:** 150000
- **Colegiatura Anual:** 3600000
- **Cantidad Cuotas:** 10
- **Monto por Cuota:** 360000
- **Día Vencimiento:** 5

Seleccionar forma de pago:
- ☑ Transferencia Electrónica

Hacer clic en "💾 Guardar Datos"

### Paso 3: Generar Vista Previa (Step 2)
1. Hacer clic en "Siguiente"
2. Hacer clic en "📄 Generar Vista Previa"

**Verificar que aparezca:**
- ✅ Fecha actual en español (Ej: "27 de octubre del 2025")
- ✅ Nombre completo del apoderado
- ✅ RUT del apoderado
- ✅ Dirección del apoderado
- ✅ Tabla de estudiantes con todos los datos
- ✅ Monto de matrícula: $150.000
- ✅ Colegiatura anual: $3.600.000
- ✅ 10 cuotas de $360.000
- ✅ Vencimiento día 5
- ✅ Forma de pago: ☑ Transferencia, ☐ otros

### Paso 4: Descargar PDF
1. Hacer clic en "📥 Descargar PDF"
2. Abrir el PDF descargado
3. Verificar que todos los datos estén correctos y formateados

---

## 📋 Checklist de Verificación

- [ ] Fecha se genera automáticamente
- [ ] Nombre completo del apoderado aparece
- [ ] RUT del apoderado está formateado correctamente
- [ ] Dirección se muestra completa
- [ ] Tabla de estudiantes tiene todos los datos (Número, Nombre, RUN, Curso)
- [ ] Monto de matrícula tiene separadores de miles
- [ ] Colegiatura anual tiene separadores de miles
- [ ] Cantidad de cuotas se muestra
- [ ] Monto por cuota tiene separadores de miles
- [ ] Día de vencimiento se muestra
- [ ] Forma de pago tiene checkboxes correctos (☑/☐)
- [ ] PDF se descarga correctamente
- [ ] PDF mantiene el formato profesional
- [ ] Todos los placeholders se reemplazan (no quedan `{{...}}`)

---

## 🚀 Próximos Pasos (Opcional)

### 1. **Agregar Campos Faltantes en `guardians`:**

Si quieres capturar más datos del apoderado, ejecuta este SQL:

```sql
ALTER TABLE guardians 
ADD COLUMN IF NOT EXISTS nacionalidad VARCHAR(50) DEFAULT 'Chilena',
ADD COLUMN IF NOT EXISTS profesion VARCHAR(100),
ADD COLUMN IF NOT EXISTS estado_civil VARCHAR(20);
```

### 2. **Integrar con Encuesta de Matrícula:**

Si tienes una tabla de encuestas (`enrollment_surveys`), puedes:
- Guardar la forma de pago seleccionada
- Recuperarla al generar el Pagaré
- Mostrarla automáticamente

### 3. **Calcular Automáticamente Monto por Cuota:**

Agregar lógica en `handleSaveEconomic`:
```jsx
if (economic.colegiatura_anual && economic.cantidad_cuotas) {
  const montoAutomatico = Math.round(
    economic.colegiatura_anual / economic.cantidad_cuotas
  );
  setEconomic(e => ({ ...e, monto_cuota: montoAutomatico }));
}
```

---

## ✅ Estado Actual

**Implementación: COMPLETA**

Todos los datos solicitados ahora se extraen y muestran en el Pagaré:
- ✅ Fecha automática
- ✅ Datos del apoderado (completos)
- ✅ Datos de estudiantes (tabla HTML)
- ✅ Datos económicos (con monto de matrícula)
- ✅ Forma de pago (checkboxes desde formulario)

**Listo para probar!** 🎉

