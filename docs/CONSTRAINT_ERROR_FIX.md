# 🚨 FIX: Error de Constraint en Tabla Profiles

## ❌ **ERROR REPORTADO**
```
FAILED TO UPDATE ROW: new row for relation "profiles" violates check constraint "profile_role_check"
```

## 🔍 **CAUSA DEL PROBLEMA**
La tabla `profiles` tiene un constraint de validación muy estricto que solo permite ciertos valores específicos en la columna `role`, pero estás intentando usar un valor que no está permitido.

---

## ✅ **SOLUCIÓN RÁPIDA**

### **Paso 1: Eliminar Constraint Problemático**

Ve a **Supabase Dashboard → SQL Editor** y ejecuta:

```sql
-- Eliminar el constraint que causa problemas
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profile_role_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS check_role;
```

### **Paso 2: Verificar que se eliminó**

```sql
-- Verificar que no hay constraints problemáticos
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'profiles' AND constraint_type = 'CHECK';
```

**Resultado esperado:** Sin constraints CHECK o solo constraints que no mencionen "role"

### **Paso 3: Ahora actualizar roles**

```sql
-- Cambiar rol de un usuario específico
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'tu-email@ejemplo.com';

-- O cambiar varios usuarios
UPDATE profiles 
SET role = 'guardian' 
WHERE email IN (
  'usuario1@ejemplo.com',
  'usuario2@ejemplo.com'
);
```

---

## 🔍 **DIAGNÓSTICO ADICIONAL**

Si quieres investigar más, ejecuta estos comandos para ver qué está pasando:

### **Ver constraint actual:**
```sql
SELECT 
    constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass
  AND constraint_name LIKE '%role%';
```

### **Ver valores actuales:**
```sql
SELECT DISTINCT role, COUNT(*) 
FROM profiles 
GROUP BY role;
```

### **Ver estructura de tabla:**
```sql
\d profiles;
```

---

## 🛠 **SOLUCIÓN ALTERNATIVA**

Si el constraint es necesario para tu aplicación, puedes crear uno más flexible:

```sql
-- Crear constraint más permisivo
ALTER TABLE profiles 
ADD CONSTRAINT profiles_role_valid 
CHECK (
  role IS NULL OR 
  role IN ('admin', 'guardian', 'teacher', 'staff', 'readonly', 'ADMIN', 'ASIST') OR
  lower(role) IN ('admin', 'guardian', 'teacher', 'staff', 'readonly', 'asist')
);
```

---

## 🎯 **VALORES COMUNES DE ROLES**

Según tu sistema, probablemente quieras usar:

```sql
-- Para el sistema de cobros:
UPDATE profiles SET role = 'admin' WHERE email = 'admin@colegio.com';
UPDATE profiles SET role = 'guardian' WHERE email LIKE '%apoderado%';

-- Para el sistema de perfiles (separado):
-- Esto va en auth.users.profile, no en profiles.role
UPDATE auth.users SET profile = 'ADMIN' WHERE email = 'admin@colegio.com';
UPDATE auth.users SET profile = 'ASIST' WHERE email = 'asistente@colegio.com';
```

---

## ⚠️ **NOTA IMPORTANTE**

**Hay DOS sistemas de roles diferentes:**

1. **`profiles.role`** - Para el sistema general (admin, guardian, teacher)
2. **`auth.users.profile`** - Para el sistema de permisos (ADMIN, ASIST, READONLY)

**El error que tienes es en `profiles.role`, NO en `auth.users.profile`**

---

## 🚀 **PASOS RECOMENDADOS**

1. ✅ **Ejecutar:** `ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profile_role_check;`
2. ✅ **Actualizar roles** según necesites
3. ✅ **Si es necesario**, crear constraint más flexible
4. ✅ **Para permisos**, usar `auth.users.profile` (sistema separado)

---

## 📝 **EJEMPLO COMPLETO**

```sql
-- 1. Eliminar constraint problemático
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profile_role_check;

-- 2. Actualizar roles
UPDATE profiles SET role = 'admin' WHERE email = 'direccion@colegiowinterhill.cl';
UPDATE profiles SET role = 'staff' WHERE email = 'administracion@colegiowinterhill.cl';
UPDATE profiles SET role = 'guardian' WHERE email LIKE '%@gmail.com';

-- 3. Para el sistema de permisos (separado)
UPDATE auth.users SET profile = 'ADMIN' WHERE email = 'direccion@colegiowinterhill.cl';
UPDATE auth.users SET profile = 'ASIST' WHERE email = 'secretaria@colegiowinterhill.cl';

-- 4. Verificar cambios
SELECT email, role FROM profiles WHERE role IS NOT NULL;
SELECT email, profile FROM auth.users WHERE profile IS NOT NULL;
```

**Ejecuta el paso 1 primero y avísame si funciona** ✅