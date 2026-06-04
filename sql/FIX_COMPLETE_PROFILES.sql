-- =====================================================
-- FIX COMPLETO: Restaurar funcionalidad y agregar perfiles
-- Ejecutar en Supabase Dashboard → SQL Editor
-- =====================================================

-- PASO 1: Agregar columna profile a tabla profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS profile VARCHAR(20) DEFAULT 'ADMIN';

-- PASO 2: Asignar perfiles específicos a los usuarios
UPDATE profiles SET profile = 'ASIST' WHERE email = 'e.cisternas.g@gmail.com';
UPDATE profiles SET profile = 'ASIST' WHERE email = 'secretariaadministrativa@winterhillenlinea.cl';
UPDATE profiles SET profile = 'ASIST' WHERE email = 'secretariaacademica@winterhillenlinea.cl';

-- PASO 3: Verificar que los cambios se aplicaron
SELECT 
    email, 
    role, 
    profile,
    first_name,
    last_name
FROM profiles 
WHERE email IN (
    'e.cisternas.g@gmail.com',
    'secretariaadministrativa@winterhillenlinea.cl',
    'secretariaacademica@winterhillenlinea.cl'
)
ORDER BY email;

-- PASO 4: Ver resumen de perfiles
SELECT 
    profile, 
    COUNT(*) as cantidad_usuarios
FROM profiles 
WHERE profile IS NOT NULL
GROUP BY profile
ORDER BY profile;

-- PASO 5: (Opcional) Agregar constraint de validación
ALTER TABLE profiles 
ADD CONSTRAINT check_valid_profile 
CHECK (profile IN ('ADMIN', 'ASIST', 'READONLY'));

-- =====================================================
-- RESULTADO ESPERADO
-- =====================================================
/*
email                                          | role  | profile | first_name | last_name
----------------------------------------------|-------|---------|------------|----------
e.cisternas.g@gmail.com                       | ASIST | ASIST   | ED         | CISTERNAS
secretariaacademica@winterhillenlinea.cl      | ASIST | ASIST   | (nombre)   | (apellido)
secretariaadministrativa@winterhillenlinea.cl | ASIST | ASIST   | (nombre)   | (apellido)

profile | cantidad_usuarios
--------|------------------
ADMIN   | (número de admins)
ASIST   | 3
*/