# ✅ COLUMNAS AGREGADAS: profesion y estado_civil

## 📋 **CAMBIOS REALIZADOS EN DB**

User agregó las siguientes columnas a la tabla `guardians`:

```sql
ALTER TABLE guardians 
ADD COLUMN profesion VARCHAR,
ADD COLUMN estado_civil VARCHAR;
```

## 🔧 **CÓDIGO YA CONFIGURADO**

### 1. Interface `GuardianRecord` (src/services/matricula.ts)
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
  // ... otros campos
  nacionalidad?: string;
  profesion?: string;      // ✅ Ya existe
  estado_civil?: string;   // ✅ Ya existe
}
```

### 2. Fetch de datos (fetchCurrentGuardian)
```typescript
const { data, error } = await supabase
  .from('guardians')
  .select('*')  // ✅ Trae TODAS las columnas incluyendo profesion y estado_civil
  .eq('owner_id', userId)
  .limit(1);
```

### 3. Mapeo en payload (buildPagarePayload)
```typescript
const payload = {
  fecha_actual,
  guardian_full_name: [...],
  guardian_run: guardian.run || '_______________',
  guardian_address: guardian.address || '_______________',
  guardian_email: guardian.email || '_______________',
  guardian_phone: guardian.phone || '_______________',
  guardian_nacionalidad: guardian.nacionalidad || 'Chilena',
  guardian_profesion: guardian.profesion || '_______________',      // ✅ Mapeado
  guardian_estado_civil: guardian.estado_civil || '_______________', // ✅ Mapeado
  year,
  students_table: studentsTable,
  // ...
};
```

### 4. Template actualizado (contratos/pagare.txt)
```
Don(a), {{guardian_full_name}}, {{guardian_nacionalidad}}, {{guardian_profesion}}, {{guardian_estado_civil}}
```

### 5. Archivo copiado a public/
```powershell
Copy-Item "contratos/pagare.txt" "public/contratos/pagare.txt" -Force
```

## 🎯 **RESULTADO ESPERADO**

Cuando generes el Pagaré, si el guardian tiene datos:

```json
{
  "first_name": "ESTER",
  "last_name": "ESTAY",
  "nacionalidad": "CHILENA",
  "profesion": "INGENIERO COMERCIAL",
  "estado_civil": "CASADO"
}
```

El HTML mostrará:
```
Don(a), ESTER ESTAY, CHILENA, INGENIERO COMERCIAL, CASADO
```

Si NO tiene datos en esos campos:
```
Don(a), ESTER ESTAY, Chilena, _______________, _______________
```

## 🧪 **CÓMO PROBAR**

### Paso 1: Actualizar datos del guardian
En Supabase SQL Editor:
```sql
UPDATE guardians 
SET 
  profesion = 'INGENIERO COMERCIAL',
  estado_civil = 'CASADO'
WHERE email = 'ester.estay@gmail.com';
```

### Paso 2: Verificar datos
```sql
SELECT 
  first_name, 
  last_name, 
  nacionalidad, 
  profesion, 
  estado_civil 
FROM guardians 
WHERE email = 'ester.estay@gmail.com';
```

### Paso 3: Generar Pagaré
1. **Ctrl+F5** - Hard refresh
2. Ir a **Matrícula**
3. Generar **Vista Previa**

### Logs esperados:
```javascript
👤 Guardian COMPLETO: {
  "first_name": "ESTER",
  "last_name": " ESTAY",
  "nacionalidad": "CHILENA",
  "profesion": "INGENIERO COMERCIAL",  // ← Nuevo dato
  "estado_civil": "CASADO",            // ← Nuevo dato
  ...
}

📦 Payload COMPLETO generated: {
  "guardian_full_name": "ESTER ESTAY",
  "guardian_nacionalidad": "CHILENA",
  "guardian_profesion": "INGENIERO COMERCIAL",  // ← Reemplazará {{guardian_profesion}}
  "guardian_estado_civil": "CASADO",            // ← Reemplazará {{guardian_estado_civil}}
  ...
}
```

### HTML generado:
```
Don(a), ESTER ESTAY, CHILENA, INGENIERO COMERCIAL, CASADO cédula de identidad N° 10.710.002-4
        ^^^^^^^^^^^  ^^^^^^^  ^^^^^^^^^^^^^^^^^^^^  ^^^^^^
        nombre       nac.     profesión            estado civil
```

## 📝 **FALLBACKS**

Si los campos están vacíos en la DB:
- `profesion = null` → `guardian_profesion = "_______________"`
- `estado_civil = null` → `guardian_estado_civil = "_______________"`
- `nacionalidad = null` → `guardian_nacionalidad = "Chilena"` (default)

## ✅ **RESUMEN**

**NO se necesitaron cambios de código** porque:
1. La interface `GuardianRecord` ya tenía `profesion` y `estado_civil` definidos
2. El fetch usa `.select('*')` que trae todas las columnas automáticamente
3. El payload ya estaba mapeando estos campos
4. Solo faltaba que existieran las columnas en la tabla (user las agregó)

**Único cambio:** Copiar template actualizado a `/public/contratos/pagare.txt` ✅

**TODO LISTO PARA USAR** 🎉
