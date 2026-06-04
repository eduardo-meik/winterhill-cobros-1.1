const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

function loadEnv() {
  const envPath = path.join(process.cwd(), '.env');
  const env = {};
  fs.readFileSync(envPath, 'utf8').replace(/\r/g, '').split('\n').forEach(line => {
    const match = line.match(/^([^#=]+)=(.*)$/);
    if (!match) return;
    env[match[1].trim()] = match[2].trim().replace(/^["']|["']$/g, '');
  });
  return env;
}

async function main() {
  const env = loadEnv();
  const supabaseUrl = env.VITE_SUPABASE_URL;
  const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceKey) {
    throw new Error('Faltan VITE_SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env');
  }

  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: e2eStudents, error: fetchStudentsError } = await adminClient
    .from('students')
    .select('id, whole_name, run')
    .ilike('whole_name', 'E2E Video %');
  if (fetchStudentsError) throw fetchStudentsError;

  const studentIds = (e2eStudents || []).map(s => s.id);

  if (studentIds.length > 0) {
    const { error: deleteStudentGuardianError } = await adminClient
      .from('student_guardian')
      .delete()
      .in('student_id', studentIds);
    if (deleteStudentGuardianError) throw deleteStudentGuardianError;

    const { error: deleteEnrollmentStudentsError } = await adminClient
      .from('enrollment_students')
      .delete()
      .in('student_id', studentIds);
    if (deleteEnrollmentStudentsError) throw deleteEnrollmentStudentsError;

    const { error: deleteFeeError } = await adminClient
      .from('fee')
      .delete()
      .in('student_id', studentIds);
    if (deleteFeeError) throw deleteFeeError;

    const { error: deleteStudentsError } = await adminClient
      .from('students')
      .delete()
      .in('id', studentIds);
    if (deleteStudentsError) throw deleteStudentsError;
  }

  const { data: e2eGuardians, error: fetchGuardiansError } = await adminClient
    .from('guardians')
    .select('id, first_name, last_name, run')
    .ilike('first_name', 'E2E Guardian %');
  if (fetchGuardiansError) throw fetchGuardiansError;

  const guardianIds = (e2eGuardians || []).map(g => g.id);
  if (guardianIds.length > 0) {
    const { data: enrollments, error: fetchEnrollmentsError } = await adminClient
      .from('enrollments')
      .select('id')
      .in('guardian_id', guardianIds);
    if (fetchEnrollmentsError) throw fetchEnrollmentsError;

    const enrollmentIds = (enrollments || []).map(e => e.id);
    if (enrollmentIds.length > 0) {
      const { error: deleteEnrollmentStudentsError } = await adminClient
        .from('enrollment_students')
        .delete()
        .in('enrollment_id', enrollmentIds);
      if (deleteEnrollmentStudentsError) throw deleteEnrollmentStudentsError;

      const { error: deleteEnrollmentDocumentsError } = await adminClient
        .from('enrollment_documents')
        .delete()
        .in('enrollment_id', enrollmentIds);
      if (deleteEnrollmentDocumentsError) throw deleteEnrollmentDocumentsError;

      const { error: deleteChequesError } = await adminClient
        .from('cheques')
        .delete()
        .in('enrollment_id', enrollmentIds);
      if (deleteChequesError) throw deleteChequesError;

      const { error: deleteFeeByEnrollmentError } = await adminClient
        .from('fee')
        .delete()
        .in('enrollment_id', enrollmentIds);
      if (deleteFeeByEnrollmentError) throw deleteFeeByEnrollmentError;

      const { error: deleteEnrollmentsError } = await adminClient
        .from('enrollments')
        .delete()
        .in('id', enrollmentIds);
      if (deleteEnrollmentsError) throw deleteEnrollmentsError;
    }

    const { error: deleteGuardiansError } = await adminClient
      .from('guardians')
      .delete()
      .in('id', guardianIds);
    if (deleteGuardiansError) throw deleteGuardiansError;
  }

  console.log(JSON.stringify({
    success: true,
    deletedStudents: studentIds.length,
    deletedGuardians: guardianIds.length,
    students: e2eStudents || [],
    guardians: e2eGuardians || [],
  }, null, 2));
}

main().catch(error => {
  console.error('[PLAYWRIGHT_CLEANUP_ERROR]', error?.stack || error?.message || error);
  process.exit(1);
});