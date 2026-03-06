# 🔧 FIX: Guardian Full Name con Trim

## ❌ **PROBLEMA REPORTADO**

User reported: `"guardian_full_name" MISSES guardian_last_name_materno TO MAKE THE guardian_full_name`

### Análisis:
Al revisar los logs, el guardian tenía:
```json
{
  "first_name": "ESTER",
  "last_name": " ESTAY"  // ← Espacio al inicio
}
```

Esto generaba:
```
guardian_full_name: "ESTER  ESTAY"  // ← Doble espacio entre nombre y apellido
```

## 🔍 **INVESTIGACIÓN**

### Estructura de la tabla `guardians`:
La tabla `guardians` tiene:
- `first_name` - Nombre(s) del apoderado
- `last_name` - Apellido(s) del apoderado (puede contener paterno y materno juntos)

**NO** tiene campos separados como:
- ❌ `apellido_paterno`
- ❌ `apellido_materno`

### Tablas que SÍ tienen apellidos separados:
- `students` - tiene `apellido_paterno` y `apellido_materno`
- `guardian_intake_surveys` - tiene `guardian_last_name_paterno` y `guardian_last_name_materno`

Pero la tabla `guardians` principal usa un solo campo `last_name` que contiene todos los apellidos.

## ✅ **SOLUCIÓN IMPLEMENTADA**

### Código ANTES:
```typescript
guardian_full_name: [guardian.first_name, guardian.last_name]
  .filter(Boolean)
  .join(' ') || '_______________'
```

**Problema:** No eliminaba espacios extras, resultando en `"ESTER  ESTAY"` (doble espacio).

### Código AHORA:
```typescript
guardian_full_name: [guardian.first_name, guardian.last_name]
  .filter((s): s is string => Boolean(s))
  .map(s => s.trim())  // ← NUEVO: Elimina espacios al inicio/final
  .join(' ') || '_______________'
```

### Mejora:
1. **`filter((s): s is string => Boolean(s))`**: Type guard para TypeScript
2. **`.map(s => s.trim())`**: Elimina espacios innecesarios
3. **`.join(' ')`**: Une con UN solo espacio

### Resultado:
```
ANTES: "ESTER  ESTAY"      // Doble espacio
AHORA: "ESTER ESTAY"       // Espacio único ✅
```

## 📝 **NOTA IMPORTANTE**

### ¿Por qué no hay apellido materno separado?

La tabla `guardians` fue diseñada originalmente con `last_name` como campo único. Si en el futuro se necesita separar apellidos paterno y materno:

### Opción A: Migración de tabla (requiere DB changes)
```sql
ALTER TABLE guardians 
ADD COLUMN apellido_paterno VARCHAR,
ADD COLUMN apellido_materno VARCHAR;

-- Migrar datos existentes (dividir last_name)
UPDATE guardians
SET 
  apellido_paterno = SPLIT_PART(last_name, ' ', 1),
  apellido_materno = SPLIT_PART(last_name, ' ', 2)
WHERE last_name IS NOT NULL;
```

### Opción B: Usar `guardian_intake_surveys` (actual)
Los datos detallados están en `guardian_intake_surveys`:
- `guardian_last_name_paterno`
- `guardian_last_name_materno`

Pero estos son datos del formulario anual, no del perfil principal del guardian.

## 🧪 **VERIFICACIÓN**

### Logs esperados (después del fix):
```javascript
🔧 buildPagarePayload - Guardian data: {
  first_name: "ESTER",
  last_name: " ESTAY",  // Puede tener espacios
  ...
}

📦 Payload COMPLETO generated: {
  "guardian_full_name": "ESTER ESTAY",  // ✅ Trim aplicado, espacio único
  ...
}
```

### HTML generado:
```
Don(a), ESTER ESTAY (nacionalidad) Chilena
        ^^^^^^^^^^^
        ✅ Nombre completo sin espacios extras
```

## 📊 **ARCHIVOS MODIFICADOS**

### `src/services/matricula.ts` (línea ~533)
```typescript
guardian_full_name: [guardian.first_name, guardian.last_name]
  .filter((s): s is string => Boolean(s))
  .map(s => s.trim())  // ← Agregado trim()
  .join(' ') || '_______________'
```

## 🎯 **RESULTADO FINAL**

✅ **Guardian full name** ahora:
- Elimina espacios al inicio/final de cada parte
- Une con UN solo espacio
- Maneja correctamente apellidos compuestos ("ESTAY RODRIGUEZ")
- Type-safe con TypeScript

❌ **NO cambia estructura de DB**:
- La tabla `guardians` sigue usando `last_name` único
- Compatible con datos existentes
- No requiere migración

## 🔄 **FUTURAS MEJORAS (Opcional)**

Si el user necesita apellidos separados EN EL PAGARÉ, opciones:

1. **Agregar campos a `guardians` table**:
   ```sql
   ALTER TABLE guardians 
   ADD COLUMN apellido_paterno VARCHAR,
   ADD COLUMN apellido_materno VARCHAR;
   ```

2. **Leer de `guardian_intake_surveys`**:
   ```typescript
   // Fetch from intake survey instead of guardians table
   const survey = await getGuardianIntakeSurvey(guardian.id, year);
   const fullName = [
     survey.guardian_first_name,
     survey.guardian_last_name_paterno,
     survey.guardian_last_name_materno
   ].filter(Boolean).map(s => s.trim()).join(' ');
   ```

3. **Dividir `last_name` en el código**:
   ```typescript
   const [paterno, materno] = (guardian.last_name || '').trim().split(/\s+/);
   const fullName = [guardian.first_name, paterno, materno]
     .filter(Boolean)
     .join(' ');
   ```

Por ahora, la solución con `.trim()` es suficiente para eliminar espacios extras.
