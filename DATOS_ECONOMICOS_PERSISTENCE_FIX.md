# 🔧 FIX: Persistencia de Datos Económicos y Formas de Pago

## ❌ **PROBLEMA REPORTADO**

User reported: **"Datos Económicos y Forma de Pago no quedan guardado. por que?"**

### Síntomas:
1. Usuario llena los datos económicos en Step 1
2. Usuario selecciona formas de pago (checkboxes)
3. Click en "💾 Guardar Datos"
4. Al refrescar la página o volver después: **DATOS PERDIDOS** ❌

---

## 🔍 **CAUSA DEL PROBLEMA**

### Problema 1: `handleSaveEconomic` incompleto

**Código ANTES:**
```javascript
const handleSaveEconomic = async () => {
  if (!enrollment) return;
  const patch = {
    colegiatura_anual: Number(economic.colegiatura_anual) || 0,
    cantidad_cuotas: Number(economic.cantidad_cuotas) || 0,
    monto_cuota: Number(economic.monto_cuota) || 0,
    dia_vencimiento: Number(economic.dia_vencimiento) || 0
    // ❌ FALTA: monto_matricula
    // ❌ FALTA: formas de pago (cheques, transferencia, efectivo, tarjeta)
  };
  await updateEnrollmentMeta(enrollment.id, patch);
};
```

**Qué guardaba:**
- ✅ `colegiatura_anual`
- ✅ `cantidad_cuotas`
- ✅ `monto_cuota`
- ✅ `dia_vencimiento`

**Qué NO guardaba:**
- ❌ `monto_matricula`
- ❌ `forma_pago_cheques`
- ❌ `forma_pago_transferencia`
- ❌ `forma_pago_efectivo`
- ❌ `forma_pago_tarjeta`

### Problema 2: No se cargaban los datos al inicio

**Código ANTES:**
```javascript
// NO EXISTÍA ningún useEffect que cargara enrollment.meta
```

Cuando el usuario regresaba, los campos aparecían vacíos aunque los datos estuvieran en la DB.

---

## ✅ **SOLUCIÓN IMPLEMENTADA**

### Fix 1: Guardar TODOS los datos

**Código AHORA:**
```javascript
const handleSaveEconomic = async () => {
  if (!enrollment) return;
  
  const patch = {
    // Economic data - TODOS los campos
    monto_matricula: Number(economic.monto_matricula) || 0,        // ← NUEVO
    colegiatura_anual: Number(economic.colegiatura_anual) || 0,
    cantidad_cuotas: Number(economic.cantidad_cuotas) || 0,
    monto_cuota: Number(economic.monto_cuota) || 0,
    dia_vencimiento: Number(economic.dia_vencimiento) || 0,
    
    // Payment methods - NUEVO
    forma_pago_cheques: paymentMethod.cheques || false,           // ← NUEVO
    forma_pago_transferencia: paymentMethod.transferencia || false, // ← NUEVO
    forma_pago_efectivo: paymentMethod.efectivo || false,          // ← NUEVO
    forma_pago_tarjeta: paymentMethod.tarjeta || false             // ← NUEVO
  };
  
  console.log('💾 Guardando datos económicos y formas de pago:', patch);
  await updateEnrollmentMeta(enrollment.id, patch);
  
  // Auto-calculate monto_cuota if not provided
  if (!economic.monto_cuota && patch.colegiatura_anual && patch.cantidad_cuotas) {
    const calc = Math.round(patch.colegiatura_anual / patch.cantidad_cuotas);
    setEconomic(e => ({ ...e, monto_cuota: calc.toString() }));
  }
  
  toast.success('Datos económicos guardados correctamente'); // ← NUEVO
};
```

### Fix 2: Cargar datos al inicio

**Código NUEVO:**
```javascript
// Load economic data and payment methods from enrollment.meta
useEffect(() => {
  if (!enrollment || !enrollment.meta) return;
  
  console.log('📊 Loading saved economic data from enrollment.meta:', enrollment.meta);
  
  // Load economic data
  setEconomic(prev => ({
    ...prev,
    monto_matricula: enrollment.meta.monto_matricula?.toString() || prev.monto_matricula,
    colegiatura_anual: enrollment.meta.colegiatura_anual?.toString() || prev.colegiatura_anual,
    cantidad_cuotas: enrollment.meta.cantidad_cuotas?.toString() || prev.cantidad_cuotas,
    monto_cuota: enrollment.meta.monto_cuota?.toString() || prev.monto_cuota,
    dia_vencimiento: enrollment.meta.dia_vencimiento?.toString() || prev.dia_vencimiento
  }));
  
  // Load payment methods
  setPaymentMethod(prev => ({
    ...prev,
    cheques: enrollment.meta.forma_pago_cheques ?? prev.cheques,
    transferencia: enrollment.meta.forma_pago_transferencia ?? prev.transferencia,
    efectivo: enrollment.meta.forma_pago_efectivo ?? prev.efectivo,
    tarjeta: enrollment.meta.forma_pago_tarjeta ?? prev.tarjeta
  }));
}, [enrollment]);
```

---

## 📊 **FLUJO COMPLETO**

### Guardar datos:
```
Usuario llena formulario
  ↓
Click "💾 Guardar Datos"
  ↓
handleSaveEconomic()
  ↓
updateEnrollmentMeta(enrollment.id, {
  monto_matricula: 5000,
  colegiatura_anual: 9999999,
  cantidad_cuotas: 10,
  monto_cuota: 999999,
  dia_vencimiento: 5,
  forma_pago_cheques: true,
  forma_pago_transferencia: true,
  forma_pago_efectivo: false,
  forma_pago_tarjeta: false
})
  ↓
Supabase UPDATE enrollments
SET meta = jsonb_build_object(...)
WHERE id = enrollment.id
  ↓
Toast: "Datos económicos guardados correctamente" ✅
```

### Cargar datos:
```
Usuario abre página Matrícula
  ↓
useEffect cargar enrollment
  ↓
getOrCreateEnrollment(guardian.id, year)
  ↓
enrollment = {
  id: "...",
  guardian_id: "...",
  academic_year: 2025,
  meta: {
    monto_matricula: 5000,
    colegiatura_anual: 9999999,
    cantidad_cuotas: 10,
    ...
  }
}
  ↓
useEffect detecta enrollment.meta
  ↓
setEconomic({ monto_matricula: "5000", ... })
setPaymentMethod({ cheques: true, ... })
  ↓
Formulario se llena automáticamente ✅
```

---

## 🧪 **CÓMO PROBAR**

### Paso 1: Guardar datos
1. Ir a **Matrícula**
2. Llenar campos:
   - Monto matrícula: `5000`
   - Colegiatura anual: `9999999`
   - Cantidad cuotas: `10`
   - Día vencimiento: `5`
3. Seleccionar formas de pago:
   - ✅ Cheques
   - ✅ Transferencia
4. Click **"💾 Guardar Datos"**
5. **Verificar toast:** "Datos económicos guardados correctamente"

### Paso 2: Verificar persistencia
1. **Refrescar página** (F5)
2. **Verificar que los campos mantienen valores:**
   - Monto matrícula: `5000` ✅
   - Colegiatura anual: `9999999` ✅
   - Cantidad cuotas: `10` ✅
   - Día vencimiento: `5` ✅
   - Cheques: ✅ (checked)
   - Transferencia: ✅ (checked)
   - Efectivo: ☐ (unchecked)
   - Tarjeta: ☐ (unchecked)

### Paso 3: Verificar en DB
```sql
SELECT 
  id,
  guardian_id,
  academic_year,
  meta->>'monto_matricula' as monto_matricula,
  meta->>'colegiatura_anual' as colegiatura_anual,
  meta->>'forma_pago_cheques' as cheques,
  meta->>'forma_pago_transferencia' as transferencia
FROM enrollments
WHERE guardian_id = 'TU-GUARDIAN-ID'
  AND academic_year = 2025;
```

**Resultado esperado:**
```
| monto_matricula | colegiatura_anual | cheques | transferencia |
|-----------------|-------------------|---------|---------------|
| 5000            | 9999999           | true    | true          |
```

---

## 📝 **ESTRUCTURA DE DATOS**

### Tabla `enrollments`:
```sql
CREATE TABLE enrollments (
  id uuid PRIMARY KEY,
  guardian_id uuid REFERENCES guardians(id),
  academic_year integer,
  meta jsonb,  -- ← Aquí se guardan los datos
  created_at timestamptz,
  updated_at timestamptz
);
```

### Contenido de `meta` (JSONB):
```json
{
  "monto_matricula": 5000,
  "colegiatura_anual": 9999999,
  "cantidad_cuotas": 10,
  "monto_cuota": 999999,
  "dia_vencimiento": 5,
  "forma_pago_cheques": true,
  "forma_pago_transferencia": true,
  "forma_pago_efectivo": false,
  "forma_pago_tarjeta": false
}
```

---

## 🔄 **COMPORTAMIENTO**

### ✅ **AHORA funciona:**
1. Usuario llena formulario → Click "Guardar" → **Datos persisten en DB** ✅
2. Usuario refresca página → **Datos se cargan automáticamente** ✅
3. Usuario cambia datos → Click "Guardar" → **Cambios se actualizan** ✅
4. Usuario genera Pagaré → **Usa datos guardados en meta** ✅

### ❌ **ANTES no funcionaba:**
1. Usuario llena formulario → Click "Guardar" → ❌ Solo guardaba 4 de 9 campos
2. Usuario refresca página → ❌ Todos los campos vacíos
3. Usuario genera Pagaré → ❌ Datos incompletos

---

## 📊 **ARCHIVOS MODIFICADOS**

### `src/components/matricula/MatriculaWizard.jsx`

**Línea ~137-161**: `handleSaveEconomic`
```diff
const patch = {
+ monto_matricula: Number(economic.monto_matricula) || 0,
  colegiatura_anual: Number(economic.colegiatura_anual) || 0,
  cantidad_cuotas: Number(economic.cantidad_cuotas) || 0,
  monto_cuota: Number(economic.monto_cuota) || 0,
  dia_vencimiento: Number(economic.dia_vencimiento) || 0,
+ forma_pago_cheques: paymentMethod.cheques || false,
+ forma_pago_transferencia: paymentMethod.transferencia || false,
+ forma_pago_efectivo: paymentMethod.efectivo || false,
+ forma_pago_tarjeta: paymentMethod.tarjeta || false
};

+ console.log('💾 Guardando datos económicos y formas de pago:', patch);
await updateEnrollmentMeta(enrollment.id, patch);
+ toast.success('Datos económicos guardados correctamente');
```

**Línea ~96-122**: Nuevo `useEffect` para cargar datos
```javascript
+ useEffect(() => {
+   if (!enrollment || !enrollment.meta) return;
+   
+   console.log('📊 Loading saved economic data from enrollment.meta:', enrollment.meta);
+   
+   setEconomic(prev => ({
+     ...prev,
+     monto_matricula: enrollment.meta.monto_matricula?.toString() || prev.monto_matricula,
+     // ...resto de campos
+   }));
+   
+   setPaymentMethod(prev => ({
+     ...prev,
+     cheques: enrollment.meta.forma_pago_cheques ?? prev.cheques,
+     // ...resto de checkboxes
+   }));
+ }, [enrollment]);
```

---

## ✅ **RESULTADO FINAL**

**PROBLEMA RESUELTO:**
- ✅ Todos los datos económicos se guardan
- ✅ Todas las formas de pago se guardan
- ✅ Datos persisten al refrescar
- ✅ Datos se cargan automáticamente
- ✅ Toast confirma guardado exitoso

**PAGARÉ AHORA TIENE DATOS COMPLETOS** 🎉
