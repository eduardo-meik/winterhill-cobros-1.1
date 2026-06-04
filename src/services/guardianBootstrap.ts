import { supabase } from './supabase';
import {
  fetchCurrentGuardian,
  GuardianLinkedStudent,
  GuardianRecord,
  EnrollmentDocumentRecord,
  EnrollmentRecord
} from './matricula';
import { GuardianIntakeRecord } from './guardianIntake';

const CURRENT_YEAR = new Date().getFullYear();

export type GuardianAlertType =
  | 'needs_intake'
  | 'needs_profile_update'
  | 'missing_students'
  | 'document_rejected'
  | 'fees_overdue'
  | 'missing_contact';

export interface GuardianAlert {
  type: GuardianAlertType;
  message: string;
  relatedIds?: string[];
}

export interface GuardianFeeRecord {
  id: string;
  student_id: string;
  amount: number | null;
  due_date: string | null;
  status: string | null;
  payment_method: string | null;
  year: number | null;
  year_academico?: number | null;
  numero_cuota?: number | null;
}

export interface GuardianEnrollmentBundle {
  enrollment: EnrollmentRecord | null;
  studentIds: string[];
  documents: EnrollmentDocumentRecord[];
  fees: GuardianFeeRecord[];
}

export interface GuardianBootstrapData {
  guardian: GuardianRecord | null;
  intake: GuardianIntakeRecord | null;
  students: GuardianLinkedStudent[];
  enrollment: EnrollmentRecord | null;
  enrollmentStudentIds: string[];
  enrollmentDocuments: EnrollmentDocumentRecord[];
  fees: GuardianFeeRecord[];
  enrollmentsByYear: Record<string, GuardianEnrollmentBundle>;
  availableEnrollmentYears: number[];
  currentEnrollmentYear: number | null;
  upcomingEnrollmentYear: number | null;
  alerts: GuardianAlert[];
  needsIntake: boolean;
  needsProfileUpdate: boolean;
  fetchedAt: string;
}

function normalizeRpcPayload(raw: any): GuardianBootstrapData {
  if (!raw || typeof raw !== 'object') {
    return finalizePayload({});
  }
  const payload = {
    guardian: raw.guardian ?? null,
    intake: raw.intake ?? null,
    students: Array.isArray(raw.students) ? raw.students : [],
    enrollment: raw.enrollment ?? null,
    enrollmentStudentIds: Array.isArray(raw.enrollment_student_ids) ? raw.enrollment_student_ids : [],
    enrollmentDocuments: Array.isArray(raw.enrollment_documents) ? raw.enrollment_documents : [],
    fees: Array.isArray(raw.fees) ? raw.fees : [],
    enrollmentsByYear: normalizeEnrollmentsByYear(raw.enrollments),
    availableEnrollmentYears: Array.isArray(raw.available_enrollment_years)
      ? raw.available_enrollment_years
          .map((value: unknown) => Number(value))
          .filter((value: number) => Number.isInteger(value))
      : [],
    currentEnrollmentYear: (() => {
      const value = Number(raw.current_enrollment_year);
      return Number.isInteger(value) ? value : null;
    })(),
    upcomingEnrollmentYear: (() => {
      const value = Number(raw.upcoming_enrollment_year);
      return Number.isInteger(value) ? value : null;
    })(),
  };
  return finalizePayload(payload);
}

function finalizePayload(partial: Partial<GuardianBootstrapData>): GuardianBootstrapData {
  const guardian = partial.guardian ?? null;
  const intake = partial.intake ?? null;
  const students = partial.students ?? [];
  const enrollment = partial.enrollment ?? null;
  const enrollmentStudentIds = partial.enrollmentStudentIds ?? [];
  const enrollmentDocuments = partial.enrollmentDocuments ?? [];
  const fees = partial.fees ?? [];
  const enrollmentsByYear = partial.enrollmentsByYear ?? {};
  const availableEnrollmentYears = partial.availableEnrollmentYears ?? [];
  const currentEnrollmentYear = partial.currentEnrollmentYear ?? null;
  const upcomingEnrollmentYear = partial.upcomingEnrollmentYear ?? null;

  const needsIntake = !intake || String(intake.status || '').toLowerCase() !== 'submitted';
  const needsProfileUpdate = Boolean((guardian as any)?.needs_update);

  const alerts = computeGuardianAlerts({
    guardian,
    intake,
    students,
    enrollment,
    enrollmentStudentIds,
    enrollmentDocuments,
    fees,
    needsIntake,
    needsProfileUpdate,
    alerts: [],
    fetchedAt: new Date().toISOString(),
  });

  return {
    guardian,
    intake,
    students,
    enrollment,
    enrollmentStudentIds,
    enrollmentDocuments,
    fees,
    enrollmentsByYear,
    availableEnrollmentYears,
    currentEnrollmentYear,
    upcomingEnrollmentYear,
    needsIntake,
    needsProfileUpdate,
    alerts,
    fetchedAt: new Date().toISOString(),
  };
}

function normalizeEnrollmentsByYear(raw: unknown): Record<string, GuardianEnrollmentBundle> {
  if (!raw || typeof raw !== 'object') {
    return {};
  }
  return Object.entries(raw as Record<string, unknown>).reduce<Record<string, GuardianEnrollmentBundle>>((acc, [year, value]) => {
    if (!value || typeof value !== 'object') {
      acc[year] = {
        enrollment: null,
        studentIds: [],
        documents: [],
        fees: [],
      };
      return acc;
    }
    const bundleValue = value as Record<string, unknown>;
    acc[year] = {
      enrollment: (bundleValue.enrollment ?? null) as EnrollmentRecord | null,
      studentIds: Array.isArray(bundleValue.student_ids) ? (bundleValue.student_ids as string[]) : [],
      documents: Array.isArray(bundleValue.documents) ? (bundleValue.documents as EnrollmentDocumentRecord[]) : [],
      fees: Array.isArray(bundleValue.fees) ? (bundleValue.fees as GuardianFeeRecord[]) : [],
    };
    return acc;
  }, {});
}

function computeGuardianAlerts(payload: GuardianBootstrapData): GuardianAlert[] {
  const alerts: GuardianAlert[] = [];
  if (payload.needsIntake) {
    alerts.push({ type: 'needs_intake', message: 'Completa la Encuesta de Ingreso antes de continuar.' });
  }
  if (payload.needsProfileUpdate) {
    alerts.push({ type: 'needs_profile_update', message: 'Actualiza tus datos personales para mantener la información al día.' });
  }
  if (!payload.students.length) {
    alerts.push({ type: 'missing_students', message: 'Aún no existen estudiantes vinculados a tu cuenta.' });
  }
  const rejectedDocs = payload.enrollmentDocuments.filter(doc => String(doc.status || '').toLowerCase() === 'rejected');
  if (rejectedDocs.length) {
    alerts.push({
      type: 'document_rejected',
      message: 'Algunos documentos de matrícula requieren correcciones.',
      relatedIds: rejectedDocs.map(doc => doc.id)
    });
  }
  const overdueFees = payload.fees.filter(fee => String(fee.status || '').toLowerCase() === 'overdue');
  if (overdueFees.length) {
    alerts.push({
      type: 'fees_overdue',
      message: 'Tienes cuotas con atraso en el portal de pagos.',
      relatedIds: overdueFees.map(fee => fee.id)
    });
  }
  const guardian = payload.guardian as any;
  const hasContact = Boolean(guardian?.email) && Boolean(guardian?.phone);
  if (!hasContact) {
    alerts.push({ type: 'missing_contact', message: 'Completa tu email y teléfono para recibir notificaciones.' });
  }
  return alerts;
}

async function fetchGuardianIntake(guardianId: string): Promise<GuardianIntakeRecord | null> {
  try {
    const { data, error } = await supabase
      .from('guardian_intake_surveys')
      .select('*')
      .eq('guardian_id', guardianId)
      .eq('year', CURRENT_YEAR)
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error && error.code !== 'PGRST116') {
      throw error;
    }
    if (!data) return null;
    const record: GuardianIntakeRecord = { ...data } as GuardianIntakeRecord;
    if (typeof record.student_lives_with === 'string') {
      record.student_lives_with = record.student_lives_with
        ? record.student_lives_with.split('|').filter((val: string) => val.trim())
        : [];
    }
    if (typeof record.status === 'string') {
      record.status = record.status.toLowerCase() as GuardianIntakeRecord['status'];
    }
    return record;
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] intake fetch failed', error);
    return null;
  }
}

async function fetchGuardianStudentsList(guardianId: string): Promise<GuardianLinkedStudent[]> {
  try {
    const { data, error } = await supabase
      .from('student_guardian')
      .select(`
        student_id,
        students (
          id,
          whole_name,
          first_name,
          apellido_paterno,
          apellido_materno,
          run,
          date_of_birth,
          genero,
          nombre_social,
          nacionalidad,
          direccion,
          comuna,
          institucion_procedencia,
          con_quien_vive,
          curso:cursos (
            id,
            nom_curso,
            nivel,
            letra_curso
          )
        )
      `)
      .eq('guardian_id', guardianId);
    if (error) throw error;
    const rows = (data || []) as Array<{ student_id: string; students: any | null }>;
    return rows
      .map((row) => {
        const student = row.students;
        if (!student) return null;
        const apellidoParts = [student.apellido_paterno, student.apellido_materno].filter(Boolean).join(' ').trim();
        const wholeName = student.whole_name || [student.first_name, apellidoParts].filter(Boolean).join(' ').trim();
        const course = student.curso || {};
        const courseLabel = course.nom_curso || null;
        const linked: GuardianLinkedStudent = {
          id: student.id,
          first_name: student.first_name,
          last_name: apellidoParts || null,
          whole_name: wholeName || null,
          run: student.run || null,
          date_of_birth: student.date_of_birth || null,
          grade: course?.nivel || null,
          curso_id: course?.id || student.curso || null,
          curso_label: courseLabel,
          nombre_social: student.nombre_social || null,
          genero: student.genero || null,
          nacionalidad: student.nacionalidad || null,
          direccion: student.direccion || null,
          comuna: student.comuna || null,
          convive_con: student.con_quien_vive ?? null,
        };
        return linked;
      })
      .filter(Boolean) as GuardianLinkedStudent[];
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] students fetch failed', error);
    return [];
  }
}

async function fetchGuardianEnrollment(guardianId: string): Promise<EnrollmentRecord | null> {
  try {
    const { data, error } = await supabase
      .from('enrollments')
      .select('*')
      .eq('guardian_id', guardianId)
      .eq('year', CURRENT_YEAR)
      .order('updated_at', { ascending: false })
      .limit(1);
    if (error) throw error;
    if (!data || !data.length) return null;
    return data[0] as EnrollmentRecord;
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] enrollment fetch failed', error);
    return null;
  }
}

async function fetchEnrollmentStudentIds(enrollmentId: string): Promise<string[]> {
  try {
    const { data, error } = await supabase
      .from('enrollment_students')
      .select('student_id')
      .eq('enrollment_id', enrollmentId);
    if (error) throw error;
    return (data || []).map((row: { student_id: string }) => row.student_id);
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] enrollment students fetch failed', error);
    return [];
  }
}

async function fetchEnrollmentDocuments(enrollmentId: string): Promise<EnrollmentDocumentRecord[]> {
  try {
    const { data, error } = await supabase
      .from('enrollment_documents')
      .select(`
        id,
        enrollment_id,
        type,
        template_version,
        status,
        pdf_url,
        storage_path,
        generated_payload,
        signed_at,
        final_content,
        content_hash,
        pdf_hash
      `)
      .eq('enrollment_id', enrollmentId);
    if (error) throw error;
    return (data || []) as EnrollmentDocumentRecord[];
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] enrollment documents fetch failed', error);
    return [];
  }
}

async function fetchGuardianFees(studentIds: string[]): Promise<GuardianFeeRecord[]> {
  if (!studentIds.length) return [];
  try {
    const { data, error } = await supabase
      .from('fee')
      .select('id, student_id, amount, due_date, status, payment_method, year_academico, numero_cuota')
      .in('student_id', studentIds)
      .order('due_date', { ascending: true });
    if (error) throw error;
    return (data || []).map((row: any) => ({
      id: row.id,
      student_id: row.student_id,
      amount: row.amount ?? null,
      due_date: row.due_date ?? null,
      status: row.status ?? null,
      payment_method: row.payment_method ?? null,
      year: row.year_academico ?? (row.due_date ? new Date(row.due_date).getFullYear() : null),
      year_academico: row.year_academico ?? (row.due_date ? new Date(row.due_date).getFullYear() : null),
      numero_cuota: row.numero_cuota ?? null,
    }));
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] fee fetch failed', error);
    return [];
  }
}

export async function fetchGuardianBootstrap(userId: string, userEmail?: string | null): Promise<GuardianBootstrapData | null> {
  if (!userId) return null;

  try {
    const { data, error } = await supabase.rpc('guardian_portal_bootstrap', { p_user_id: userId });
    if (!error && data) {
      return normalizeRpcPayload(data);
    }
    if (error && error.code !== 'PGRST202') {
      throw error;
    }
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] RPC guardian_portal_bootstrap failed, using fallback', error);
  }

  const guardian = await fetchCurrentGuardian(userId, userEmail ?? undefined);
  if (!guardian?.id) {
    return finalizePayload({ guardian, students: [], enrollmentDocuments: [], enrollmentStudentIds: [], fees: [], enrollment: null, intake: null });
  }

  const [intake, students] = await Promise.all([
    fetchGuardianIntake(guardian.id),
    fetchGuardianStudentsList(guardian.id)
  ]);

  const enrollment = await fetchGuardianEnrollment(guardian.id);
  const enrollmentStudentIds = enrollment ? await fetchEnrollmentStudentIds(enrollment.id) : [];
  const enrollmentDocuments = enrollment ? await fetchEnrollmentDocuments(enrollment.id) : [];
  const fees = await fetchGuardianFees(students.map((s) => s.id).filter(Boolean));

  const enrollmentsByYear: Record<string, GuardianEnrollmentBundle> = {};
  const availableEnrollmentYears: number[] = [];
  if (enrollment) {
    const yearValue = enrollment.year ?? CURRENT_YEAR;
    const yearKey = String(yearValue);
    enrollmentsByYear[yearKey] = {
      enrollment,
      studentIds: enrollmentStudentIds,
      documents: enrollmentDocuments,
      fees,
    };
    if (Number.isInteger(enrollment.year)) {
      availableEnrollmentYears.push(enrollment.year as number);
    }
  }

  return finalizePayload({
    guardian,
    intake,
    students,
    enrollment,
    enrollmentStudentIds,
    enrollmentDocuments,
    fees,
    enrollmentsByYear,
    availableEnrollmentYears,
    currentEnrollmentYear: enrollment?.year ?? null,
    upcomingEnrollmentYear: null,
  });
}

export async function fetchGuardianBootstrapForStaff(guardianId: string): Promise<GuardianBootstrapData | null> {
  if (!guardianId) return null;
  try {
    const { data: guardian, error } = await supabase
      .from('guardians')
      .select('*')
      .eq('id', guardianId)
      .maybeSingle();
    if (error) throw error;
    if (!guardian) {
      return null;
    }

    const [intake, students] = await Promise.all([
      fetchGuardianIntake(guardianId),
      fetchGuardianStudentsList(guardianId)
    ]);

    const enrollment = await fetchGuardianEnrollment(guardianId);
    const enrollmentStudentIds = enrollment ? await fetchEnrollmentStudentIds(enrollment.id) : [];
    const enrollmentDocuments = enrollment ? await fetchEnrollmentDocuments(enrollment.id) : [];
    const fees = await fetchGuardianFees(students.map((s) => s.id).filter(Boolean));

    const enrollmentsByYear: Record<string, GuardianEnrollmentBundle> = {};
    const availableEnrollmentYears: number[] = [];
    if (enrollment) {
      const yearValue = enrollment.year ?? CURRENT_YEAR;
      const yearKey = String(yearValue);
      enrollmentsByYear[yearKey] = {
        enrollment,
        studentIds: enrollmentStudentIds,
        documents: enrollmentDocuments,
        fees,
      };
      if (Number.isInteger(enrollment.year)) {
        availableEnrollmentYears.push(enrollment.year as number);
      }
    }

    return finalizePayload({
      guardian,
      intake,
      students,
      enrollment,
      enrollmentStudentIds,
      enrollmentDocuments,
      fees,
      enrollmentsByYear,
      availableEnrollmentYears,
      currentEnrollmentYear: enrollment?.year ?? null,
      upcomingEnrollmentYear: null,
    });
  } catch (error) {
    if (import.meta.env.DEV) console.warn('[guardianBootstrap] staff fetch failed', error);
    return null;
  }
}
