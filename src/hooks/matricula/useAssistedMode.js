import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '../../services/supabase';

/**
 * Handles assisted-mode guardian search + selection for ADMIN/ASIST staff.
 *
 * @param {Object} deps
 * @param {boolean} deps.assistedMode - whether user is ADMIN or ASIST
 * @param {string|null} deps.navigationGuardianId - guardian ID from route state
 * @param {Object|null} deps.navigationGuardianSnapshot - guardian object from route state
 * @param {Function} deps.setGuardian - setter for the active guardian in parent
 * @param {Function} deps.setEnrollment - setter for enrollment in parent
 */
export function useAssistedMode({
  assistedMode,
  navigationGuardianId,
  navigationGuardianSnapshot,
  setGuardian,
  setEnrollment,
}) {
  const [assistedGuardian, setAssistedGuardian] = useState(null);
  const [guardianSearch, setGuardianSearch] = useState('');
  const [guardianResults, setGuardianResults] = useState([]);
  const [guardianSearchLoading, setGuardianSearchLoading] = useState(false);
  const [guardianModalOpen, setGuardianModalOpen] = useState(false);
  const [studentModalOpen, setStudentModalOpen] = useState(false);

  // Auto-load guardian from navigation state
  useEffect(() => {
    if (!assistedMode) return;
    const targetId = navigationGuardianSnapshot?.id || navigationGuardianId;
    if (!targetId || assistedGuardian?.id === targetId) return;

    if (navigationGuardianSnapshot) {
      setAssistedGuardian(prev =>
        prev?.id === navigationGuardianSnapshot.id ? prev : navigationGuardianSnapshot
      );
      return;
    }

    let cancelled = false;
    (async () => {
      try {
        const { data, error } = await supabase
          .from('guardians')
          .select('id, first_name, last_name, run, email, address, phone, profesion, estado_civil, comuna')
          .eq('id', targetId)
          .maybeSingle();
        if (error) throw error;
        if (!cancelled && data) {
          setAssistedGuardian(prev => (prev?.id === data.id ? prev : data));
        }
      } catch (e) {
        console.error('Prefetch guardian for MatriculaWizard:', e?.message || e);
      }
    })();

    return () => { cancelled = true; };
  }, [assistedMode, navigationGuardianId, navigationGuardianSnapshot, assistedGuardian?.id]);

  // Search guardians by name/run/email
  const searchGuardians = useCallback(async (q) => {
    if (!q || q.trim().length < 2) {
      setGuardianResults([]);
      return;
    }
    try {
      setGuardianSearchLoading(true);
      const orFilter = `first_name.ilike.%${q}%,last_name.ilike.%${q}%,run.ilike.%${q}%,email.ilike.%${q}%`;
      const { data, error } = await supabase
        .from('guardians')
        .select('id, first_name, last_name, run, email')
        .or(orFilter)
        .limit(10);
      if (error) throw error;
      setGuardianResults(data || []);
    } catch (e) {
      console.error('Guardian search error:', e?.message || e);
    } finally {
      setGuardianSearchLoading(false);
    }
  }, []);

  // Debounced wrapper – clears previous timer on each call (300ms)
  const searchTimerRef = useRef(null);
  const debouncedSearchGuardians = useCallback((q) => {
    if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    searchTimerRef.current = setTimeout(() => searchGuardians(q), 300);
  }, [searchGuardians]);

  const handleGuardianModalSuccess = useCallback(() => {
    setGuardianModalOpen(false);
    if (guardianSearch.trim().length >= 2) {
      searchGuardians(guardianSearch);
    }
  }, [guardianSearch, searchGuardians]);

  // Clear finalize alerts when guardian changes
  const clearGuardian = useCallback(() => {
    setAssistedGuardian(null);
    setGuardian(null);
    setEnrollment(null);
  }, [setGuardian, setEnrollment]);

  return {
    assistedGuardian,
    setAssistedGuardian,
    guardianSearch,
    setGuardianSearch,
    guardianResults,
    guardianSearchLoading,
    searchGuardians,
    debouncedSearchGuardians,
    guardianModalOpen,
    setGuardianModalOpen,
    handleGuardianModalSuccess,
    studentModalOpen,
    setStudentModalOpen,
    clearGuardian,
  };
}
