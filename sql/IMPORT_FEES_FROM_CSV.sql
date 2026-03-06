-- ============================================================================
-- SCRIPT DE IMPORTACIÓN DE CUOTAS (FEES) DESDE CSV
-- ============================================================================
-- Descripción: Importa cuotas de pago desde datos CSV
-- Autor: Sistema de importación
-- Fecha: 2025-12-29
--
-- INSTRUCCIONES DE USO:
-- 1. Obtener tu owner_id ejecutando: SELECT auth.uid();
-- 2. Reemplazar 'TU_USER_ID_AQUI' con tu UUID
-- 3. Ejecutar este script en Supabase SQL Editor
-- 4. Verificar resultados con las queries de validación al final
-- ============================================================================

-- Función auxiliar para normalizar RUN (quitar puntos, guiones, mayúsculas)
CREATE OR REPLACE FUNCTION normalize_run(p_run text)
RETURNS text AS $$
BEGIN
  IF p_run IS NULL OR p_run = '' THEN
    RETURN NULL;
  END IF;
  RETURN UPPER(TRIM(REPLACE(REPLACE(p_run, '.', ''), '-', '')));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Función para buscar estudiante por RUN normalizado
CREATE OR REPLACE FUNCTION find_student_by_run(p_run text)
RETURNS uuid AS $$
DECLARE
  v_student_id uuid;
  v_normalized_run text;
BEGIN
  v_normalized_run := normalize_run(p_run);
  
  IF v_normalized_run IS NULL THEN
    RETURN NULL;
  END IF;
  
  SELECT id INTO v_student_id
  FROM students
  WHERE normalize_run(run) = v_normalized_run
  LIMIT 1;
  
  RETURN v_student_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Función para buscar curso por nombre (aproximado)
CREATE OR REPLACE FUNCTION find_curso_by_name(p_curso_name text)
RETURNS uuid AS $$
DECLARE
  v_curso_id uuid;
BEGIN
  IF p_curso_name IS NULL OR p_curso_name = '' THEN
    RETURN NULL;
  END IF;
  
  -- Buscar curso por nombre exacto o similar
  SELECT id INTO v_curso_id
  FROM cursos
  WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(p_curso_name))
     OR LOWER(TRIM(nombre)) LIKE '%' || LOWER(TRIM(p_curso_name)) || '%'
  ORDER BY 
    CASE WHEN LOWER(TRIM(nombre)) = LOWER(TRIM(p_curso_name)) THEN 1 ELSE 2 END,
    year_academico DESC
  LIMIT 1;
  
  RETURN v_curso_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Función principal de importación (UPSERT)
CREATE OR REPLACE FUNCTION import_fee(
  p_run text,                    -- RUN del estudiante
  p_curso_nombre text,           -- Nombre del curso (ej: "3° básico A")
  p_numero_cuota integer,        -- Número de cuota (1-10)
  p_monto numeric,               -- Monto en pesos (sin símbolos)
  p_fecha_vencimiento date,      -- Fecha de vencimiento
  p_estado text,                 -- "PAGADO" o "PENDIENTE"
  p_owner_id uuid                -- ID del usuario que crea el registro
)
RETURNS TABLE (
  action text,
  fee_id uuid,
  student_name text,
  message text
) AS $$
DECLARE
  v_student_id uuid;
  v_curso_id uuid;
  v_status text;
  v_payment_date date;
  v_year_academico integer;
  v_fee_id uuid;
  v_student_name text;
  v_existing_fee_id uuid;
BEGIN
  -- 1. Buscar estudiante por RUN
  v_student_id := find_student_by_run(p_run);
  
  IF v_student_id IS NULL THEN
    RETURN QUERY SELECT 
      'ERROR'::text,
      NULL::uuid,
      p_run::text,
      'Estudiante no encontrado con RUN: ' || COALESCE(p_run, 'NULL');
    RETURN;
  END IF;
  
  -- Obtener nombre del estudiante para logging
  SELECT CONCAT(nombres, ' ', apellido_paterno, ' ', apellido_materno)
  INTO v_student_name
  FROM students
  WHERE id = v_student_id;
  
  -- 2. Buscar curso (opcional, puede ser NULL)
  v_curso_id := find_curso_by_name(p_curso_nombre);
  
  -- 3. Convertir estado
  v_status := CASE 
    WHEN UPPER(TRIM(p_estado)) = 'PAGADO' THEN 'paid'
    WHEN UPPER(TRIM(p_estado)) = 'PENDIENTE' THEN 'pending'
    ELSE 'pending'
  END;
  
  -- 4. Fecha de pago (solo si está pagado)
  v_payment_date := CASE 
    WHEN v_status = 'paid' THEN p_fecha_vencimiento
    ELSE NULL
  END;
  
  -- 5. Año académico (extraer de fecha de vencimiento)
  v_year_academico := EXTRACT(YEAR FROM p_fecha_vencimiento)::integer;
  
  -- 6. Verificar si ya existe la cuota
  SELECT id INTO v_existing_fee_id
  FROM fee
  WHERE student_id = v_student_id
    AND year_academico = v_year_academico
    AND numero_cuota = p_numero_cuota;
  
  IF v_existing_fee_id IS NOT NULL THEN
    -- ACTUALIZAR cuota existente
    UPDATE fee
    SET 
      amount = p_monto,
      due_date = p_fecha_vencimiento,
      payment_date = v_payment_date,
      status = v_status,
      fee_curso = v_curso_id,
      updated_at = now(),
      notes = 'Cuota ' || p_numero_cuota || ' - Actualizada desde CSV'
    WHERE id = v_existing_fee_id;
    
    RETURN QUERY SELECT 
      'UPDATED'::text,
      v_existing_fee_id,
      v_student_name,
      'Cuota actualizada: ' || v_student_name || ' - Cuota #' || p_numero_cuota;
  ELSE
    -- INSERTAR nueva cuota
    INSERT INTO fee (
      student_id,
      amount,
      due_date,
      payment_date,
      status,
      year_academico,
      numero_cuota,
      fee_curso,
      notes,
      owner_id,
      meta
    ) VALUES (
      v_student_id,
      p_monto,
      p_fecha_vencimiento,
      v_payment_date,
      v_status,
      v_year_academico,
      p_numero_cuota,
      v_curso_id,
      'Cuota ' || p_numero_cuota || ' - Importada desde CSV',
      p_owner_id,
      '{}'::jsonb
    )
    RETURNING id INTO v_fee_id;
    
    RETURN QUERY SELECT 
      'INSERTED'::text,
      v_fee_id,
      v_student_name,
      'Cuota creada: ' || v_student_name || ' - Cuota #' || p_numero_cuota;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- EJECUCIÓN DE IMPORTACIÓN
-- ============================================================================
-- ⚠️ IMPORTANTE: Reemplazar 'TU_USER_ID_AQUI' con tu UUID de usuario
-- Para obtenerlo, ejecuta: SELECT auth.uid();
-- ============================================================================

DO $$
DECLARE
  v_owner_id uuid := 'TU_USER_ID_AQUI'::uuid; -- 🔴 CAMBIAR ESTO
  v_result RECORD;
  v_inserted_count integer := 0;
  v_updated_count integer := 0;
  v_error_count integer := 0;
BEGIN
  RAISE NOTICE '🚀 Iniciando importación de cuotas...';
  RAISE NOTICE '📅 Fecha: %', now();
  RAISE NOTICE '';
  
  -- Validar que se cambió el owner_id
  IF v_owner_id = 'TU_USER_ID_AQUI'::uuid OR v_owner_id IS NULL THEN
    RAISE EXCEPTION '❌ ERROR: Debes cambiar TU_USER_ID_AQUI por tu UUID de usuario real';
  END IF;
  
  -- ============================================================================
  -- DATOS A IMPORTAR (Reemplazar con tus datos reales)
  -- ============================================================================
  -- Formato: import_fee(RUN, CURSO, CUOTA_NUM, MONTO, FECHA, ESTADO, OWNER_ID)
  
  -- CATALÁN VÁSQUEZ, INARA SAYEN - RUN: 25372029
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING '❌ %', v_result.message;
    END IF;
  END LOOP;
  
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING '❌ %', v_result.message;
    END IF;
  END LOOP;
  
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 3, 99324, '2025-05-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING '❌ %', v_result.message;
    END IF;
  END LOOP;
  
  -- Continuar con el resto de los datos...
  -- (Aquí irían todas las demás llamadas a import_fee con tus datos CSV)
  
  -- ============================================================================
  -- RESUMEN DE IMPORTACIÓN
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE '✅ IMPORTACIÓN COMPLETADA';
  RAISE NOTICE '================================';
  RAISE NOTICE '📝 Cuotas insertadas: %', v_inserted_count;
  RAISE NOTICE '🔄 Cuotas actualizadas: %', v_updated_count;
  RAISE NOTICE '❌ Errores: %', v_error_count;
  RAISE NOTICE '📊 Total procesado: %', v_inserted_count + v_updated_count + v_error_count;
END$$;

-- ============================================================================
-- QUERIES DE VALIDACIÓN POST-IMPORTACIÓN
-- ============================================================================

-- Ver cuotas importadas recientemente (últimas 50)
SELECT 
  s.run,
  s.nombres,
  s.apellido_paterno,
  f.numero_cuota,
  f.amount,
  f.due_date,
  f.status,
  f.payment_date,
  c.nombre as curso,
  f.created_at
FROM fee f
JOIN students s ON f.student_id = s.id
LEFT JOIN cursos c ON f.fee_curso = c.id
ORDER BY f.created_at DESC
LIMIT 50;

-- Resumen por estudiante
SELECT 
  s.run,
  s.nombres,
  s.apellido_paterno,
  COUNT(*) as total_cuotas,
  SUM(CASE WHEN f.status = 'paid' THEN 1 ELSE 0 END) as cuotas_pagadas,
  SUM(CASE WHEN f.status = 'pending' THEN 1 ELSE 0 END) as cuotas_pendientes,
  SUM(f.amount) as monto_total,
  SUM(CASE WHEN f.status = 'paid' THEN f.amount ELSE 0 END) as monto_pagado
FROM students s
JOIN fee f ON s.id = f.student_id
WHERE f.year_academico = 2025
GROUP BY s.id, s.run, s.nombres, s.apellido_paterno
ORDER BY s.apellido_paterno, s.nombres;

-- Detectar estudiantes del CSV que no se encontraron
-- (Ejecutar manualmente con los RUNs de tu CSV)
WITH csv_runs AS (
  SELECT unnest(ARRAY['25372029', '25412424', '25607211']) as run
)
SELECT 
  cr.run,
  s.id IS NULL as no_encontrado
FROM csv_runs cr
LEFT JOIN students s ON normalize_run(s.run) = normalize_run(cr.run)
WHERE s.id IS NULL;

-- Ver duplicados (no debería haber ninguno)
SELECT 
  student_id,
  year_academico,
  numero_cuota,
  COUNT(*) as duplicados
FROM fee
GROUP BY student_id, year_academico, numero_cuota
HAVING COUNT(*) > 1;
