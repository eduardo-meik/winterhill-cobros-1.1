-- =====================================================
-- AÑADIR PERFILES DE USUARIO PARA CONTROL DE PERMISOS
-- VERSIÓN CORREGIDA: Usar tabla 'profiles' en lugar de 'auth.users'
-- =====================================================

-- 1. Agregar columna 'profile' a tabla profiles (accesible vía REST API)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS profile VARCHAR(20) DEFAULT 'ADMIN';

-- 2. Crear enum para los tipos de perfil (opcional pero recomendado)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_profile_enum') THEN
    CREATE TYPE user_profile_enum AS ENUM ('ADMIN', 'ASIST', 'READONLY');
  END IF;
END $$;

-- 3. Actualizar la columna para usar el enum
ALTER TABLE profiles 
ALTER COLUMN profile TYPE user_profile_enum USING profile::user_profile_enum;

-- 4. Agregar constraint para validar valores
ALTER TABLE profiles 
ADD CONSTRAINT check_valid_profile 
CHECK (profile IN ('ADMIN', 'ASIST', 'READONLY'));

-- 5. Crear índice para mejorar performance en consultas por perfil
CREATE INDEX IF NOT EXISTS idx_profiles_profile ON profiles(profile);

-- 6. Actualizar todos los usuarios existentes a ADMIN (sin cambios en funcionalidad)
UPDATE profiles 
SET profile = 'ADMIN' 
WHERE profile IS NULL;

-- =====================================================
-- TABLA PARA LOGS DE ACCIONES RESTRINGIDAS (OPCIONAL)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_action_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  action_attempted VARCHAR(100) NOT NULL,
  user_profile user_profile_enum NOT NULL,
  allowed BOOLEAN NOT NULL,
  ip_address INET,
  user_agent TEXT,
  attempted_at TIMESTAMPTZ DEFAULT NOW(),
  details JSONB
);

-- Índices para tabla de logs
CREATE INDEX IF NOT EXISTS idx_action_logs_user_id ON user_action_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_action_logs_attempted_at ON user_action_logs(attempted_at);
CREATE INDEX IF NOT EXISTS idx_action_logs_action ON user_action_logs(action_attempted);

-- =====================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- =====================================================

COMMENT ON COLUMN auth.users.profile IS 'Perfil del usuario: ADMIN (acceso completo), ASIST (sin pago libre/editar/eliminar), READONLY (solo consulta)';
COMMENT ON TABLE user_action_logs IS 'Log de acciones intentadas por usuarios para auditoría de permisos';

-- =====================================================
-- VERIFICACIÓN DEL CAMBIO
-- =====================================================

-- Verificar que la columna se agregó correctamente
SELECT 
  column_name, 
  data_type, 
  column_default, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users' 
  AND column_name = 'profile';

-- Verificar que el enum se creó
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (
  SELECT oid 
  FROM pg_type 
  WHERE typname = 'user_profile_enum'
);

-- Mostrar distribución de perfiles (debería ser todos ADMIN inicialmente)
SELECT 
  profile, 
  COUNT(*) as cantidad_usuarios
FROM auth.users 
GROUP BY profile;