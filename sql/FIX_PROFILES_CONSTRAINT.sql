-- =====================================================
-- DIAGNOSTICAR Y SOLUCIONAR ERROR DE CONSTRAINT
-- Error: "new row for relation 'profiles' violates check constraint 'profile_role_check'"
-- =====================================================

-- 1. DIAGNOSTICAR: Ver qué constraints existen en la tabla profiles
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass;

-- 2. Ver estructura actual de tabla profiles
\d profiles;

-- 3. Ver valores actuales en la columna role
SELECT DISTINCT role, COUNT(*) as count
FROM profiles 
GROUP BY role
ORDER BY role;

-- 4. Ver el constraint específico que está fallando
SELECT 
    constraint_name,
    constraint_type,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%role_check%' 
   OR constraint_name LIKE '%profile%';

-- =====================================================
-- SOLUCIÓN 1: ELIMINAR CONSTRAINT PROBLEMÁTICO
-- =====================================================

-- Eliminar el constraint que está causando problemas
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profile_role_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS check_role;

-- =====================================================
-- SOLUCIÓN 2: CREAR CONSTRAINT CORRECTO (SI ES NECESARIO)
-- =====================================================

-- Si necesitas un constraint para validar roles, crear uno más flexible
ALTER TABLE profiles 
ADD CONSTRAINT profiles_role_valid 
CHECK (
  role IS NULL OR 
  role IN ('admin', 'guardian', 'teacher', 'staff', 'readonly') OR
  lower(role) IN ('admin', 'guardian', 'teacher', 'staff', 'readonly')
);

-- =====================================================
-- SOLUCIÓN 3: ACTUALIZAR ROLES SIN PROBLEMAS
-- =====================================================

-- Ahora sí puedes actualizar roles sin error
-- Ejemplo para cambiar un usuario específico:
-- UPDATE profiles SET role = 'admin' WHERE id = 'user-id-here';

-- O para cambiar varios usuarios:
-- UPDATE profiles SET role = 'guardian' WHERE email LIKE '%@guardian.com';

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

-- Verificar que no hay constraints problemáticos
SELECT 
    constraint_name,
    constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass
  AND constraint_name LIKE '%role%';

-- Verificar que puedes actualizar roles
-- UPDATE profiles SET role = 'admin' WHERE id = (SELECT id FROM profiles LIMIT 1);
-- SELECT 'SUCCESS: Roles can be updated' as status;

-- =====================================================
-- COMANDOS PARA USAR EN SUPABASE DASHBOARD
-- =====================================================

/*
PASO 1: Ejecutar en SQL Editor de Supabase:

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profile_role_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

PASO 2: Verificar constraint eliminado:

SELECT constraint_name FROM information_schema.table_constraints 
WHERE table_name = 'profiles' AND constraint_type = 'CHECK';

PASO 3: Ahora intentar actualizar roles:

UPDATE profiles SET role = 'admin' WHERE email = 'tu-email@ejemplo.com';

PASO 4: Si necesitas constraint, agregar uno flexible:

ALTER TABLE profiles 
ADD CONSTRAINT profiles_role_valid 
CHECK (role IS NULL OR role IN ('admin', 'guardian', 'teacher', 'staff'));
*/

-- =====================================================
-- TROUBLESHOOTING ADICIONAL
-- =====================================================

-- Si aún tienes problemas, ver todos los constraints:
SELECT 
    tc.constraint_name, 
    tc.constraint_type,
    cc.check_clause,
    tc.table_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'profiles'
ORDER BY tc.constraint_type, tc.constraint_name;

-- Ver estructura completa de la tabla
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;