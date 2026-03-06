-- ============================================================================
-- SCRIPT DE IMPORTACIÃ“N DE CUOTAS - GENERADO AUTOMÃTICAMENTE
-- ============================================================================
-- Generado: 2025-12-31 11:22:05
-- Registros a importar: 50
-- ============================================================================

DO $$
DECLARE
  v_owner_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_result RECORD;
  v_inserted_count integer := 0;
  v_updated_count integer := 0;
  v_error_count integer := 0;
BEGIN
  RAISE NOTICE 'Iniciando importacion de 50 cuotas...';
  RAISE NOTICE 'Fecha: %', now();
  RAISE NOTICE '';
  
  -- Validar que se cambio el owner_id
  IF v_owner_id = 'TU_USER_ID_AQUI'::uuid OR v_owner_id IS NULL THEN
    RAISE EXCEPTION 'ERROR: Debes cambiar TU_USER_ID_AQUI por tu UUID de usuario real';
  END IF;
    -- Linea 1: INARA SAYEN CATALÁN - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 1: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 2: INARA SAYEN CATALÁN - Cuota 2
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 2: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 3: INARA SAYEN CATALÁN - Cuota 3
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 3, 99324, '2025-05-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 3: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 4: INARA SAYEN CATALÁN - Cuota 4
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 4, 99324, '2025-06-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 4: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 5: INARA SAYEN CATALÁN - Cuota 5
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 5, 99324, '2025-07-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 5: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 6: INARA SAYEN CATALÁN - Cuota 6
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 6, 99324, '2025-08-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 6: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 7: INARA SAYEN CATALÁN - Cuota 7
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 7, 99324, '2025-09-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 7: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 8: INARA SAYEN CATALÁN - Cuota 8
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 8, 99324, '2025-10-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 8: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 9: INARA SAYEN CATALÁN - Cuota 9
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 9, 99324, '2025-11-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 9: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 10: INARA SAYEN CATALÁN - Cuota 10
  FOR v_result IN SELECT * FROM import_fee('25372029', '3° básico A', 10, 99324, '2025-12-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 10: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 11: IGNACIA EMILIA MORALES - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 11: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 12: IGNACIA EMILIA MORALES - Cuota 2
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 12: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 13: IGNACIA EMILIA MORALES - Cuota 3
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 3, 99324, '2025-05-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 13: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 14: IGNACIA EMILIA MORALES - Cuota 4
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 4, 99324, '2025-06-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 14: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 15: IGNACIA EMILIA MORALES - Cuota 5
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 5, 99324, '2025-07-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 15: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 16: IGNACIA EMILIA MORALES - Cuota 6
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 6, 99324, '2025-08-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 16: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 17: IGNACIA EMILIA MORALES - Cuota 7
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 7, 99324, '2025-09-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 17: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 18: IGNACIA EMILIA MORALES - Cuota 8
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 8, 99324, '2025-10-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 18: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 19: IGNACIA EMILIA MORALES - Cuota 9
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 9, 99324, '2025-11-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 19: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 20: IGNACIA EMILIA MORALES - Cuota 10
  FOR v_result IN SELECT * FROM import_fee('25412424', '3° básico A', 10, 99324, '2025-12-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 20: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 21: GIULIANO ANTONINO CANTARUTTI - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('25607211', '4° básico A', 1, 993240, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 21: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 22: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 22: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 23: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 2
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 23: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 24: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 3
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 3, 99324, '2025-05-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 24: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 25: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 4
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 4, 99324, '2025-06-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 25: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 26: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 5
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 5, 99324, '2025-07-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 26: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 27: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 6
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 6, 99324, '2025-08-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 27: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 28: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 7
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 7, 99324, '2025-09-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 28: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 29: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 8
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 8, 99324, '2025-10-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 29: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 30: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 9
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 9, 99324, '2025-11-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 30: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 31: CRISTÓBAL FACUNDO CÁRDENAS - Cuota 10
  FOR v_result IN SELECT * FROM import_fee('25420647', '3° básico A', 10, 99324, '2025-12-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 31: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 32: INARA TAPIA - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 32: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 33: INARA TAPIA - Cuota 2
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 33: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 34: INARA TAPIA - Cuota 3
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 3, 99324, '2025-05-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 34: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 35: INARA TAPIA - Cuota 4
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 4, 99324, '2025-06-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 35: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 36: INARA TAPIA - Cuota 5
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 5, 99324, '2025-07-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 36: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 37: INARA TAPIA - Cuota 6
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 6, 99324, '2025-08-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 37: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 38: INARA TAPIA - Cuota 7
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 7, 99324, '2025-09-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 38: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 39: INARA TAPIA - Cuota 8
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 8, 99324, '2025-10-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 39: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 40: INARA TAPIA - Cuota 9
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 9, 99324, '2025-11-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 40: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 41: INARA TAPIA - Cuota 10
  FOR v_result IN SELECT * FROM import_fee('25404838', '3° básico A', 10, 99324, '2025-12-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 41: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 42: SANTIAGO PAZ - Cuota 1
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 1, 99324, '2025-03-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 42: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 43: SANTIAGO PAZ - Cuota 2
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 2, 99324, '2025-04-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 43: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 44: SANTIAGO PAZ - Cuota 4
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 4, 99324, '2025-06-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 44: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 45: SANTIAGO PAZ - Cuota 5
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 5, 99324, '2025-07-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 45: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 46: SANTIAGO PAZ - Cuota 6
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 6, 99324, '2025-08-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 46: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 47: SANTIAGO PAZ - Cuota 7
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 7, 99324, '2025-09-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 47: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 48: SANTIAGO PAZ - Cuota 8
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 8, 99324, '2025-10-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 48: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 49: SANTIAGO PAZ - Cuota 9
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 9, 99324, '2025-11-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 49: %', v_result.message;
    END IF;
  END LOOP;
  -- Linea 50: SANTIAGO PAZ - Cuota 10
  FOR v_result IN SELECT * FROM import_fee('26211725', '1° básico', 10, 99324, '2025-12-05'::date, 'PAGADO', v_owner_id) LOOP
    IF v_result.action = 'INSERTED' THEN v_inserted_count := v_inserted_count + 1;
    ELSIF v_result.action = 'UPDATED' THEN v_updated_count := v_updated_count + 1;
    ELSIF v_result.action = 'ERROR' THEN 
      v_error_count := v_error_count + 1;
      RAISE WARNING 'ERROR Linea 50: %', v_result.message;
    END IF;
  END LOOP;
  
  -- ============================================================================
  -- RESUMEN DE IMPORTACIÃ“N
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTACION COMPLETADA';
  RAISE NOTICE '================================';
  RAISE NOTICE 'Cuotas insertadas: %', v_inserted_count;
  RAISE NOTICE 'Cuotas actualizadas: %', v_updated_count;
  RAISE NOTICE 'Errores: %', v_error_count;
  RAISE NOTICE 'Total procesado: %', v_inserted_count + v_updated_count + v_error_count;
END$$;
