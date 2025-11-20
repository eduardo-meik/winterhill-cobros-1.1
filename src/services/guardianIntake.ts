import { supabase } from './supabase';

const CURRENT_YEAR = new Date().getFullYear();

// Simple in-memory cache & in-flight promise to avoid burst of identical requests
let _intakeCacheYear: number | null = null;
let _intakeCache: GuardianIntakeRecord | null | undefined = undefined;
let _intakeFetchPromise: Promise<GuardianIntakeRecord | null> | null = null;
let _intakeAutoCreateAttempted = false;

export function clearGuardianIntakeCache() {
  _intakeCacheYear = null;
  _intakeCache = undefined;
  _intakeFetchPromise = null;
}

function normalizeIntakeRecord(row: any): GuardianIntakeRecord | null {
  if (!row) return null;
  const record = { ...row } as GuardianIntakeRecord;
  if (typeof record.student_lives_with === 'string') {
    record.student_lives_with = record.student_lives_with
      ? record.student_lives_with.split('|').filter((s: string) => s.trim())
      : [];
  }
  if (typeof record.status === 'string') {
    record.status = record.status.toLowerCase() as GuardianIntakeRecord['status'];
  }
  return record;
}

export interface GuardianIntakeRecord {
  id: string;
  guardian_id: string;
  year: number;
  status: 'draft'|'submitted';
  guardian_first_name?: string;
  guardian_last_name_paterno?: string;
  guardian_last_name_materno?: string;
  guardian_relationship?: string;
  guardian_rut?: string;
  guardian_education_level?: string;
  guardian_address?: string;
  guardian_commune?: string;
  guardian_email?: string;
  guardian_phone?: string;
  student_first_names?: string;
  student_last_name_paterno?: string;
  student_last_name_materno?: string;
  student_run?: string;
  student_course?: string;
  student_course_id?: string | null;
  student_birth_date?: string;
  student_nationality?: string;
  student_gender?: string;
  student_social_name?: string;
  student_enrollment_date?: string;
  student_withdrawal_date?: string;
  student_withdrawal_reason?: string;
  student_repeat_current?: boolean;
  student_previous_institution?: string;
  student_address?: string;
  student_commune?: string;
  student_lives_with?: string[];
  alt_contact_name?: string;
  alt_contact_phone?: string;
  scholarship_percentage?: number;
  payment_form_prioritario?: boolean;
  payment_form_cheques?: boolean;
  payment_form_pagare?: boolean;
  payment_form_credit_card?: boolean;
  payment_form_transfer?: boolean;
  payment_form_planilla?: boolean;
  financial_institution?: string;
  submitted_at?: string;
  created_at?: string;
  updated_at?: string;
}

export async function fetchCurrentIntake(force = false): Promise<GuardianIntakeRecord | null> {
  // Return cached if valid and not forcing
  if (!force && _intakeCacheYear === CURRENT_YEAR && _intakeCache !== undefined) {
    return _intakeCache;
  }
  // If a request is already in-flight reuse it
  if (!force && _intakeFetchPromise) {
    return _intakeFetchPromise;
  }
  _intakeFetchPromise = (async (): Promise<GuardianIntakeRecord | null> => {
    try {
      const { data, error } = await supabase
        .from('guardian_intake_surveys')
        .select('*')
        .eq('year', CURRENT_YEAR)
        .limit(1)
        .maybeSingle();
      if (error && error.code !== 'PGRST116') throw error;

      let record = normalizeIntakeRecord(data || null);
      
      // If not found (404 / PGRST116) try auto-create a minimal draft once.
      if (!record && !_intakeAutoCreateAttempted) {
        _intakeAutoCreateAttempted = true;
        try {
          const minimalPayload = { year: CURRENT_YEAR, status: 'draft' } as any;
          const { data: created, error: createErr } = await supabase.rpc('upsert_guardian_intake_survey', { payload: minimalPayload });
          if (!createErr && created) {
            record = normalizeIntakeRecord(created);
          }
        } catch { /* ignore auto-create failure */ }
      }
      _intakeCacheYear = CURRENT_YEAR;
      _intakeCache = record;
      return record || null;
    } finally {
      // Clear in-flight marker regardless of outcome to allow future retries
      _intakeFetchPromise = null;
    }
  })();
  return _intakeFetchPromise;
}

export async function saveIntakeDraft(payload: Record<string, any>) {
  // Convert student_lives_with array to pipe-delimited string for SQL function
  const processedPayload = { ...payload };
  if (Array.isArray(processedPayload.student_lives_with)) {
    processedPayload.student_lives_with = processedPayload.student_lives_with.join('|');
  }
  if (!processedPayload.student_course_id) {
    processedPayload.student_course_id = null;
  }
  
  const full = { ...processedPayload, year: CURRENT_YEAR, status: 'draft' };
  const { data, error } = await supabase.rpc('upsert_guardian_intake_survey', { payload: full });
  if (error) throw error;
  return data as GuardianIntakeRecord;
}

export async function submitIntake() {
  const { data, error } = await supabase.rpc('submit_guardian_intake_survey');
  if (error) throw error;
  clearGuardianIntakeCache();
  return data;
}

export async function adminFetchGuardianIntake(guardianId: string, year?: number): Promise<GuardianIntakeRecord | null> {
  if (!guardianId) throw new Error('guardianId required');
  const targetYear = year ?? CURRENT_YEAR;
  const { data, error } = await supabase
    .from('guardian_intake_surveys')
    .select('*')
    .eq('guardian_id', guardianId)
    .eq('year', targetYear)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error && error.code !== 'PGRST116') throw error;
  return normalizeIntakeRecord(data || null);
}

export async function needsIntakeCheck(force = false): Promise<boolean> {
  try {
    const rec = await fetchCurrentIntake(force);
    if (!rec) return true; // none yet => should complete
    return rec.status?.toLowerCase() !== 'submitted';
  } catch (e) {
    // Conservative: require completion if error
    return true;
  }
}

// --------------------------------------------------
// STAFF HELPERS
// --------------------------------------------------

export async function adminUpsertGuardianIntake(
  guardianId: string,
  payload: Record<string, any>,
  year?: number
) {
  if (!guardianId) throw new Error('guardianId required');
  const processedPayload = { ...payload };
  if (Array.isArray(processedPayload.student_lives_with)) {
    processedPayload.student_lives_with = processedPayload.student_lives_with.join('|');
  }
  if (!processedPayload.student_course_id) {
    processedPayload.student_course_id = null;
  }
  const args: Record<string, any> = {
    p_guardian_id: guardianId,
    p_payload: processedPayload,
  };
  if (year) args.p_year = year;
  const { data, error } = await supabase.rpc('admin_upsert_guardian_intake', args);
  if (error) throw error;
  return data;
}

export async function adminSubmitGuardianIntake(guardianId: string, year?: number) {
  if (!guardianId) throw new Error('guardianId required');
  const args: Record<string, any> = { p_guardian_id: guardianId };
  if (year) args.p_year = year;
  const { data, error } = await supabase.rpc('admin_submit_guardian_intake', args);
  if (error) throw error;
  return data;
}
