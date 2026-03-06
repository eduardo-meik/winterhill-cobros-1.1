# 🧮 Auto-Cálculo de Monto por Cuota

## ✅ **IMPLEMENTACIÓN COMPLETADA**

### Descripción del Cambio

El campo **"Monto por Cuota (CLP)"** ahora se calcula **automáticamente** cuando el usuario ingresa o modifica:
- **Colegiatura Anual (CLP)**
- **Cantidad de Cuotas**

**Fórmula:**
```javascript
monto_cuota = Math.round(colegiatura_anual / cantidad_cuotas)
```

---

## 📋 **CAMBIOS REALIZADOS**

### 1. Nuevo useEffect para Auto-Cálculo (MatriculaWizard.jsx)

**Ubicación:** Líneas ~127-137

```javascript
// Auto-calculate monto_cuota when colegiatura_anual or cantidad_cuotas change
useEffect(() => {
  const colegiatura = parseFloat(economic.colegiatura_anual);
  const cuotas = parseInt(economic.cantidad_cuotas);
  
  if (!isNaN(colegiatura) && !isNaN(cuotas) && cuotas > 0 && colegiatura > 0) {
    const montoPorCuota = Math.round(colegiatura / cuotas);
    console.log('🧮 Auto-calculando monto_cuota:', { colegiatura, cuotas, montoPorCuota });
    setEconomic(prev => ({ ...prev, monto_cuota: montoPorCuota.toString() }));
  }
}, [economic.colegiatura_anual, economic.cantidad_cuotas]);
```

**Comportamiento:**
- Se ejecuta cada vez que cambia `colegiatura_anual` o `cantidad_cuotas`
- Valida que ambos valores sean números válidos
- Calcula: `colegiatura ÷ cuotas` y redondea al entero más cercano
- Actualiza automáticamente el estado `economic.monto_cuota`
- Log en consola para debugging

---

### 2. Campo de Solo Lectura (MatriculaWizard.jsx)

**ANTES:**
```jsx
<div>
  <label className="block text-xs mb-1 font-medium">Monto por Cuota (CLP)</label>
  <input 
    type="number" 
    className="w-full border rounded px-2 py-1" 
    value={economic.monto_cuota} 
    onChange={e => setEconomic({ ...economic, monto_cuota: e.target.value })} 
    placeholder="Ej: 360000"
  />
</div>
```

**AHORA:**
```jsx
<div>
  <label className="block text-xs mb-1 font-medium">Monto por Cuota (CLP) - Auto-calculado</label>
  <input 
    type="number" 
    className="w-full border rounded px-2 py-1 bg-gray-100" 
    value={economic.monto_cuota} 
    readOnly
    placeholder="Se calcula automáticamente"
  />
</div>
```

**Cambios:**
- ✅ Label indica "Auto-calculado"
- ✅ Campo `readOnly` - usuario no puede editar
- ✅ Clase `bg-gray-100` - fondo gris para indicar deshabilitado
- ✅ Placeholder actualizado

---

### 3. Generación del Pagaré (matricula.ts)

**Ya existente** - El servicio `buildPagarePayload` ya tenía el auto-cálculo:

```typescript
monto_cuota: (() => {
  // Calculate monto_cuota automatically: colegiatura_anual / cantidad_cuotas
  if (economic?.colegiatura_anual && economic?.cantidad_cuotas) {
    const total = typeof economic.colegiatura_anual === 'string' 
      ? parseFloat(economic.colegiatura_anual) 
      : economic.colegiatura_anual;
    const cuotas = typeof economic.cantidad_cuotas === 'string'
      ? parseInt(economic.cantidad_cuotas)
      : economic.cantidad_cuotas;
    
    if (!isNaN(total) && !isNaN(cuotas) && cuotas > 0) {
      const montoPorCuota = Math.round(total / cuotas);
      return formatCurrency(montoPorCuota);
    }
  }
  // Fallback to manual monto_cuota if provided
  return formatCurrency(economic?.monto_cuota) || '_______________';
})(),
```

**Garantiza que el Pagaré siempre use el valor calculado correcto.**

---

## 🎯 **FLUJO COMPLETO**

### Escenario de Uso:

1. **Usuario navega a "Datos Económicos"**
2. **Ingresa Colegiatura Anual:** `9999999`
3. **Ingresa Cantidad de Cuotas:** `10`
4. **useEffect se dispara automáticamente:**
   ```
   colegiatura: 9999999
   cuotas: 10
   montoPorCuota = Math.round(9999999 / 10) = 999999.9 → 1000000
   ```
5. **Campo "Monto por Cuota" se actualiza a:** `1000000`
6. **Usuario click "💾 Guardar Datos"**
7. **Se guarda en DB:** `monto_cuota: 1000000`
8. **Usuario genera Pagaré HTML**
9. **Placeholder `{{monto_cuota}}` se reemplaza con:** `"1.000.000"` (formateado)

---

## 🧪 **PRUEBAS**

### Caso 1: Cálculo básico
```
Colegiatura Anual: 3600000
Cantidad Cuotas: 10

Resultado esperado:
monto_cuota = 3600000 / 10 = 360000 ✅
```

### Caso 2: División con decimales
```
Colegiatura Anual: 9999999
Cantidad Cuotas: 10

Cálculo: 9999999 / 10 = 999999.9
Redondeo: Math.round(999999.9) = 1000000 ✅
```

### Caso 3: Cambio dinámico
```
1. Ingresa Colegiatura: 5000000
2. Ingresa Cuotas: 12
   → monto_cuota = 416667 ✅

3. Cambia Cuotas a: 10
   → monto_cuota = 500000 ✅ (se recalcula automáticamente)
```

### Caso 4: Valores inválidos
```
Colegiatura Anual: (vacío)
Cantidad Cuotas: 10

Resultado: monto_cuota no se actualiza (mantiene valor anterior)
```

---

## 📊 **COMPORTAMIENTO EN EL PAGARÉ**

### Template (pagare.txt)
```
Por concepto de colegiatura anual, el monto correspondiente a ${{colegiatura_anual}} 
dividido en {{cantidad_cuotas}} cuotas mensuales de ${{monto_cuota}} cada una 
para el día {{dia_vencimiento}} de cada mes.
```

### Ejemplo de salida HTML:
```
Por concepto de colegiatura anual, el monto correspondiente a $9.999.999 
dividido en 10 cuotas mensuales de $1.000.000 cada una 
para el día 5 de cada mes.
```

**Formato aplicado:**
- `{{colegiatura_anual}}` → `9.999.999` (separador de miles)
- `{{cantidad_cuotas}}` → `10`
- `{{monto_cuota}}` → `1.000.000` (separador de miles)
- `{{dia_vencimiento}}` → `5`

---

## ✅ **VALIDACIONES**

El useEffect incluye validaciones:

1. ✅ **No NaN:** Verifica que ambos valores sean números válidos
2. ✅ **División por cero:** Solo calcula si `cuotas > 0`
3. ✅ **Valores positivos:** Solo calcula si `colegiatura > 0`
4. ✅ **Redondeo:** Usa `Math.round()` para evitar decimales

---

## 🔄 **SINCRONIZACIÓN**

### Al cargar datos guardados:
```javascript
useEffect(() => {
  if (!enrollment || !enrollment.meta) return;
  
  setEconomic(prev => ({
    ...prev,
    monto_matricula: enrollment.meta.monto_matricula?.toString() || prev.monto_matricula,
    colegiatura_anual: enrollment.meta.colegiatura_anual?.toString() || prev.colegiatura_anual,
    cantidad_cuotas: enrollment.meta.cantidad_cuotas?.toString() || prev.cantidad_cuotas,
    monto_cuota: enrollment.meta.monto_cuota?.toString() || prev.monto_cuota,
    dia_vencimiento: enrollment.meta.dia_vencimiento?.toString() || prev.dia_vencimiento
  }));
}, [enrollment]);
```

**Después de cargar**, el useEffect de auto-cálculo se ejecuta y recalcula si es necesario.

---

## 🎨 **UI/UX**

### Indicadores visuales:

1. **Label:** "Monto por Cuota (CLP) - Auto-calculado"
   - Usuario sabe que no debe editarlo manualmente

2. **Campo readonly:** No permite edición
   - Previene errores de usuario

3. **Fondo gris (`bg-gray-100`):** Indica campo deshabilitado
   - Estándar de diseño para campos calculados

4. **Console log:** `console.log('🧮 Auto-calculando monto_cuota:', ...)`
   - Debugging para desarrolladores
   - Usuario avanzado puede verificar en DevTools

---

## 📝 **RESUMEN**

### ✅ Antes del fix:
- ❌ Usuario debía calcular manualmente
- ❌ Riesgo de errores de cálculo
- ❌ Campo editable causaba inconsistencias

### ✅ Después del fix:
- ✅ Cálculo 100% automático
- ✅ Actualización en tiempo real
- ✅ Campo de solo lectura
- ✅ Consistencia garantizada entre formulario y Pagaré
- ✅ UX mejorada - menos trabajo para el usuario

---

## 🎉 **RESULTADO FINAL**

**El usuario solo debe ingresar:**
1. Monto Matrícula
2. Colegiatura Anual
3. Cantidad de Cuotas
4. Día de Vencimiento

**El sistema calcula automáticamente:**
- ✅ Monto por Cuota = Colegiatura Anual ÷ Cantidad Cuotas

**Y lo muestra en:**
- ✅ Formulario de Datos Económicos (readonly)
- ✅ Vista Previa del Pagaré HTML
- ✅ PDF descargado final
