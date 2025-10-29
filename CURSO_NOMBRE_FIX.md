# 🎓 FIX: Mostrar Nombre de Curso en Pagaré

## ❌ **PROBLEMA**

En la tabla de estudiantes del Pagaré, la columna "Curso año 2025" mostraba el UUID del curso:
```
0d85085b-7955-4be1-a957-f965f84246e7
```

En lugar del nombre real:
```
4° MEDIO A
```

## ✅ **SOLUCIÓN IMPLEMENTADA**

### 1. JOIN con tabla `cursos`

Actualizado `listEnrollmentStudents()` en `src/services/matricula.ts` para hacer JOIN con la tabla `cursos`:

**ANTES:**
```typescript
.select(`
  student_id, 
  students:student_id(
    id, 
    whole_name, 
    run,
    curso  // Solo UUID
  )
`)
```

**AHORA:**
```typescript
.select(`
  student_id, 
  students:student_id(
    id, 
    whole_name, 
    run,
    curso,
    cursos:curso(
      id,
      nom_curso,      // ← "4° MEDIO A"
      nivel,          // ← 4
      letra_curso     // ← "A"
    )
  )
`)
```

### 2. Nueva propiedad `curso_nombre`

Agregado campo `curso_nombre` a la interface `StudentRecord`:

```typescript
export interface StudentRecord {
  id: string;
  whole_name?: string;
  run?: string;
  curso?: string;           // UUID (mantiene compatibilidad)
  curso_nombre?: string;    // ← NUEVO: "4° MEDIO A"
  first_name?: string;
  // ...
}
```

### 3. Prioridad de curso en tabla

Actualizado `buildPagarePayload()` para priorizar `curso_nombre`:

```typescript
const tableRows = students.map((s, idx) => {
  // Prioriza: curso_nombre > grade > nivel > curso UUID
  const cursoDisplay = s.curso_nombre || s.grade || s.nivel || s.curso || 'Sin curso asignado';
  return `<tr>
    <td>${idx + 1}</td>
    <td>${s.whole_name}</td>
    <td>${s.run}</td>
    <td>${cursoDisplay}</td>  // ← Ahora muestra "4° MEDIO A"
  </tr>`;
});
```

## 📊 **ESTRUCTURA DE DATOS**

### Tabla `cursos`
```sql
CREATE TABLE cursos (
  id uuid PRIMARY KEY,
  year_academico integer,      -- 2025
  nom_curso varchar,            -- "4° MEDIO A"
  nivel integer,                -- 4
  letra_curso varchar,          -- "A"
  descripcion_curso varchar,    -- "Cuarto Medio A"
  cod_curso integer
);
```

### Relación
```
students.curso (UUID) → cursos.id
                         ↓
                    cursos.nom_curso = "4° MEDIO A"
```

## 🧪 **CÓMO PROBAR**

1. **Ctrl+F5** - Hard refresh
2. Ir a **Matrícula**
3. Agregar estudiante
4. Generar **Vista Previa**

### Logs esperados:
```javascript
👥 Students COMPLETO: [
  {
    "id": "5a85933a-...",
    "whole_name": "VIOLETA ABRIL CONTRERAS ESTAY",
    "run": "22.585.803-9",
    "curso": "0d85085b-7955-4be1-a957-f965f84246e7",  // UUID original
    "curso_nombre": "4° MEDIO A"  // ← NUEVO campo
  }
]
```

### HTML esperado en tabla:
```html
<table>
  <thead>
    <tr>
      <th>Número</th>
      <th>Nombre</th>
      <th>RUT</th>
      <th>Curso año 2025</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>VIOLETA ABRIL CONTRERAS ESTAY</td>
      <td>22.585.803-9</td>
      <td>4° MEDIO A</td>  <!-- ✅ Nombre legible -->
    </tr>
  </tbody>
</table>
```

## 📝 **ARCHIVOS MODIFICADOS**

### `src/services/matricula.ts`
1. **Interface StudentRecord** (línea ~25):
   - Agregado: `curso_nombre?: string;`

2. **listEnrollmentStudents()** (línea ~195):
   - Agregado JOIN con `cursos:curso(id, nom_curso, nivel, letra_curso)`
   - Agregado mapeo: `curso_nombre: cursoNombre`

3. **buildPagarePayload()** (línea ~505):
   - Cambiado: `s.curso_nombre || s.grade || s.nivel || s.curso || 'Sin curso asignado'`

## 🎯 **RESULTADO FINAL**

✅ **Columna "Curso año 2025"** ahora muestra:
- `4° MEDIO A` ✅
- `1° BÁSICO B` ✅
- `3° MEDIO C` ✅

En lugar de:
- `0d85085b-7955-4be1-a957-f965f84246e7` ❌

## 🔄 **FALLBACKS**

Si `cursos.nom_curso` no existe (curso eliminado o NULL), el sistema usa en orden:
1. `curso_nombre` (de JOIN) ← Preferido
2. `grade` (compatibilidad legacy)
3. `nivel` (compatibilidad legacy)
4. `curso` (UUID como último recurso)
5. `"Sin curso asignado"` (si todo es NULL)

Esto asegura que SIEMPRE se muestre algo legible.
