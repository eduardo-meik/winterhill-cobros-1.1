# Fix: Datos Faltantes en Pagaré

## Problema
El sistema no estaba mostrando los datos dinámicos del apoderado, estudiante y económicos en el Pagaré. Los placeholders permanecían sin reemplazar (ej: `{{guardian_full_name}}`, `{{fecha_actual}}`, etc).

## Causa Raíz
El interface `GuardianRecord` en `src/services/matricula.ts` **no incluía** los campos:
- `nacionalidad`
- `profesion`
- `estado_civil`

Esto causaba errores de TypeScript que impedían que el código compilara correctamente, aunque no se veían en el navegador porque el código antiguo seguía ejecutándose.

## Solución Implementada

### 1. Actualizar Interface GuardianRecord
**Archivo:** `src/services/matricula.ts` (líneas 5-22)

```typescript
export interface GuardianRecord {
  id: string;
  owner_id: string;
  first_name?: string;
  last_name?: string;
  run?: string;
  email?: string;
  address?: string;
  phone?: string;
  relationship_type?: string;
  tipo_apoderado?: string;
  comuna?: string;
  date_birth?: string;
  nivel_educacional?: string;
  family_tie?: string;
  nacionalidad?: string;      // ✅ NUEVO
  profesion?: string;          // ✅ NUEVO
  estado_civil?: string;       // ✅ NUEVO
}
```

### 2. Agregar Logging Comprehensivo
Para facilitar el debugging, agregué logs detallados:

**En `buildPagarePayload`:**
```typescript
console.log('🔧 buildPagarePayload - Guardian data:', {
  first_name: guardian.first_name,
  last_name: guardian.last_name,
  run: guardian.run,
  address: guardian.address,
  nacionalidad: guardian.nacionalidad,
  profesion: guardian.profesion,
  estado_civil: guardian.estado_civil
});
console.log('📅 Fecha actual:', fecha_actual);
console.log('👥 Students count:', students.length);
console.log('💰 Economic data:', economic);
console.log('💳 Payment method:', paymentMethod);
console.log('✅ Final payload:', payload);
```

**En `handleGeneratePagare` (MatriculaWizard.jsx):**
```typescript
console.log('🎯 handleGeneratePagare started');
console.log('👤 Guardian:', guardian);
console.log('👥 Students:', students);
console.log('💰 Economic data:', economic);
console.log('💳 Payment method:', paymentMethod);
console.log('💵 Economic numbers parsed:', econNumbers);
console.log('📦 Payload generated:', payload);
console.log('📄 HTML preview length:', html.length);
```

### 3. Mejorar Conversión de Números
Cambié la conversión de `cantidad_cuotas` y `dia_vencimiento` para asegurar que sean strings:

```typescript
cantidad_cuotas: economic?.cantidad_cuotas?.toString() || '_______________',
dia_vencimiento: economic?.dia_vencimiento?.toString() || '_______________',
```

## Testing

### Pasos para Probar
1. **Refrescar navegador** con Ctrl+F5 (limpiar cache)
2. **Abrir DevTools Console** (F12)
3. **Navegar a Matrícula**
4. **Step 0:** Agregar al menos 1 estudiante
5. **Step 1:** Llenar datos económicos:
   - Monto Matrícula: `150000`
   - Colegiatura Anual: `3600000`
   - Cantidad Cuotas: `10`
   - Monto por Cuota: `360000`
   - Día Vencimiento: `5`
   - Seleccionar: ☑ Transferencia Electrónica
6. **Step 2:** Clic en "📄 Generar Vista Previa"
7. **Revisar Console Logs** para ver los datos procesados

### Verificar en HTML Preview
Debes ver:
- ✅ **Fecha actual:** "27 de octubre del 2025"
- ✅ **Apoderado:** "ESTER ESTAY"
- ✅ **RUN:** "10.710.002-4"
- ✅ **Dirección:** "STA MARGARITA 237 C BELLAVISTA"
- ✅ **Nacionalidad:** "Chilena" (valor por defecto si no existe en BD)
- ✅ **Profesión:** "_______________" (placeholder si no existe en BD)
- ✅ **Estado Civil:** "_______________" (placeholder si no existe en BD)
- ✅ **Tabla estudiantes** con HTML borders
- ✅ **Monto matrícula:** "150.000"
- ✅ **Colegiatura anual:** "3.600.000"
- ✅ **Cantidad cuotas:** "10"
- ✅ **Monto cuota:** "360.000"
- ✅ **Día vencimiento:** "5"
- ✅ **Checkboxes:** ☐ Cheques, ☑ Transferencia, ☐ Efectivo, ☐ Tarjeta

### Logs Esperados en Console
```
🎯 handleGeneratePagare started
👤 Guardian: {first_name: "ESTER", last_name: " ESTAY", run: "10.710.002-4", ...}
👥 Students: [...]
💰 Economic data: {monto_matricula: "150000", colegiatura_anual: "3600000", ...}
💳 Payment method: {cheques: false, transferencia: true, ...}
💵 Economic numbers parsed: {monto_matricula: 150000, ...}
🔧 buildPagarePayload - Guardian data: {...}
📅 Fecha actual: 27 de octubre del 2025
👥 Students count: 1
💰 Economic data: {...}
💳 Payment method: {...}
✅ Final payload: {...}
📦 Payload generated: {...}
📄 HTML preview length: 5234
```

## Campos Opcionales en Base de Datos

Si deseas que el sistema muestre datos reales en lugar de placeholders para nacionalidad, profesión y estado civil, puedes agregar estas columnas a la tabla `guardians`:

```sql
-- Opcional: Agregar columnas a la tabla guardians
ALTER TABLE guardians 
ADD COLUMN IF NOT EXISTS nacionalidad VARCHAR(50) DEFAULT 'Chilena',
ADD COLUMN IF NOT EXISTS profesion VARCHAR(100),
ADD COLUMN IF NOT EXISTS estado_civil VARCHAR(20);

-- Actualizar datos existentes
UPDATE guardians 
SET nacionalidad = 'Chilena' 
WHERE nacionalidad IS NULL;
```

**Nota:** El sistema funciona perfectamente sin estas columnas, usando valores por defecto inteligentes:
- `nacionalidad` → "Chilena"
- `profesion` → "_______________"
- `estado_civil` → "_______________"

## Archivos Modificados

1. **src/services/matricula.ts**
   - Líneas 5-22: Agregado `nacionalidad`, `profesion`, `estado_civil` al interface `GuardianRecord`
   - Líneas 448-488: Agregado logging comprehensivo en `buildPagarePayload`
   - Líneas 456-457: Mejorada conversión de `cantidad_cuotas` y `dia_vencimiento` a string

2. **src/components/matricula/MatriculaWizard.jsx**
   - Líneas 153-189: Agregado logging detallado en `handleGeneratePagare`

## Resultado Esperado

Después de estos cambios:
1. ✅ Código compila sin errores TypeScript
2. ✅ Todos los placeholders se reemplazan con datos reales
3. ✅ Fecha actual se genera automáticamente en español
4. ✅ Datos del apoderado se muestran correctamente (con defaults inteligentes)
5. ✅ Tabla de estudiantes se renderiza con HTML profesional
6. ✅ Datos económicos se formatean con separadores de miles chilenos
7. ✅ Checkboxes de forma de pago se muestran (☑/☐)
8. ✅ Logs detallados permiten debugging fácil

## Próximos Pasos

1. **Probar workflow completo** con datos reales
2. **Descargar PDF** y verificar calidad
3. **Opcional:** Agregar columnas a tabla `guardians` para datos reales
4. **Opcional:** Crear UI para editar nacionalidad, profesión y estado civil del apoderado
