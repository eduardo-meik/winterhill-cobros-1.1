/**
 * Micro-test: hit every critical Supabase query the app uses.
 * Uses SERVICE_ROLE (bypasses RLS) first, then ANON key (applies RLS).
 * Run: node test-queries.cjs
 */
const https = require('https');

const SUPABASE_URL = 'https://yeotpplgerfpxviqazrn.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllb3RwcGxnZXJmcHh2aXFhenJuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDg5NzgyNiwiZXhwIjoyMDYwNDczODI2fQ.RcnqnfYDq7dmUuKD2c6tUQJ9ArA0PJ448lTWwEQtb9M';
const ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllb3RwcGxnZXJmcHh2aXFhenJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4OTc4MjYsImV4cCI6MjA2MDQ3MzgyNn0.qfjT0PLm3ff4m3jr7FGEAYCu0Gm97YEtZDUe-tS_urs';

function supabaseGet(path, apiKey, authToken) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/${path}`);
    const headers = {
      'apikey': apiKey,
      'Authorization': `Bearer ${authToken || apiKey}`,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    https.get(url, { headers }, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve({ status: res.statusCode, data: json, count: Array.isArray(json) ? json.length : null });
        } catch {
          resolve({ status: res.statusCode, data: body, count: null });
        }
      });
    }).on('error', reject);
  });
}

// Each test: [label, postgrest_path]
const TESTS = [
  // === useStudentsQuery ===
  ['useStudentsQuery: students + cursos join',
   'students?select=*,cursos(id,nom_curso,nivel,year_academico)&order=apellido_paterno.asc&limit=5'],

  // === useFeesQuery ===
  ['useFeesQuery: fee + students + cursos join',
   'fee?select=id,student_id,guardian_id,amount,due_date,payment_date,status,payment_method,num_boleta,mov_bancario,notes,fee_curso,numero_cuota,institucion_financiera,year,year_academico,enrollment_id,meta,students:student_id(id,first_name,apellido_paterno,apellido_materno,whole_name,run,curso,cursos(id,nom_curso))&year_academico=eq.2026&limit=5'],

  // === useCursosQuery ===
  ['useCursosQuery: cursos direct',
   'cursos?select=*&order=nom_curso.asc&limit=5'],

  // === guardianBootstrap: student_guardian + students + cursos ===
  ['guardianBootstrap: student_guardian join',
   'student_guardian?select=student_id,students:student_id(id,whole_name,run,first_name,apellido_paterno,apellido_materno,date_of_birth,genero,nombre_social,nacionalidad,direccion,comuna,institucion_procedencia,con_quien_vive,cursos(id,nom_curso,nivel,letra_curso))&limit=3'],

  // === feeService: fee + students + cursos (via nom_curso) ===
  ['feeService: fee + students + cursos(nom_curso)',
   'fee?select=id,student_id,guardian_id,amount,due_date,payment_date,status,payment_method,num_boleta,mov_bancario,notes,fee_curso,numero_cuota,institucion_financiera,year,year_academico,students:student_id(id,first_name,apellido_paterno,apellido_materno,whole_name,run,curso,cursos(nom_curso))&year_academico=eq.2026&limit=5'],

  // === useEnrollmentData: student_guardian + students + cursos ===
  ['useEnrollmentData: student_guardian join students+cursos',
   'student_guardian?select=student_id,students:student_id(id,whole_name,run,curso,cursos(nom_curso,nivel,letra_curso))&limit=3'],

  // === useReportData: fee + students + cursos ===
  ['useReportData: fee + student + cursos',
   'fee?select=*,students:student_id(id,first_name,apellido_paterno,apellido_materno,whole_name,run,curso,cursos(id,nom_curso,nivel))&year_academico=eq.2026&limit=5'],

  // === matricula.ts: enrollment_students + students + cursos + academic_record ===
  ['matricula: enrollment_students join',
   'enrollment_students?select=student_id,enrollment_id,students:student_id(id,whole_name,run,curso,first_name,apellido_paterno,apellido_materno,date_of_birth,cursos(id,nom_curso,nivel,letra_curso)),academic_record:student_academic_records(curso_id,curso:cursos(id,nom_curso,nivel,letra_curso))&limit=3'],

  // === enrollments direct ===
  ['enrollments: direct query',
   'enrollments?select=*&limit=3'],

  // === profiles ===
  ['profiles: direct query',
   'profiles?select=id,email,role,first_name,last_name&limit=3'],

  // === guardians ===
  ['guardians: direct query',
   'guardians?select=id,first_name,last_name,run,email,phone&limit=3'],

  // === enrollment_documents ===
  ['enrollment_documents: with enrollment join',
   'enrollment_documents?select=*,enrollments:enrollment_id(id,guardian_id,year,status)&limit=3'],

  // === cheques ===
  ['cheques: with enrollment join',
   'cheques?select=*,enrollments:enrollment_id(id,guardian_id,year)&limit=3'],
];

async function runTests(label, apiKey, authToken) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  ${label}`);
  console.log(`${'='.repeat(60)}`);
  let pass = 0, fail = 0;
  for (const [name, path] of TESTS) {
    try {
      const r = await supabaseGet(path, apiKey, authToken);
      if (r.status === 200) {
        console.log(`  ✅ ${name}  [${r.count} rows]`);
        pass++;
      } else {
        console.log(`  ❌ ${name}  [HTTP ${r.status}]`);
        // Show error detail
        const msg = typeof r.data === 'object' ? JSON.stringify(r.data).substring(0, 200) : String(r.data).substring(0, 200);
        console.log(`     → ${msg}`);
        fail++;
      }
    } catch (e) {
      console.log(`  ❌ ${name}  [EXCEPTION: ${e.message}]`);
      fail++;
    }
  }
  console.log(`\n  RESULT: ${pass} passed, ${fail} failed\n`);
  return fail;
}

(async () => {
  // Phase 1: Service Role (bypasses RLS) — tests query syntax
  const syntaxFails = await runTests('PHASE 1: SERVICE_ROLE (syntax check, no RLS)', SERVICE_KEY);

  // Phase 2: Anon key (applies RLS) — tests permissions
  const rlsFails = await runTests('PHASE 2: ANON KEY (RLS / permissions check)', ANON_KEY);

  console.log('='.repeat(60));
  if (syntaxFails > 0) {
    console.log('⚠️  SYNTAX ERRORS detected — queries themselves are broken');
  } else if (rlsFails > 0) {
    console.log('⚠️  RLS / PERMISSION ERRORS — queries work but RLS blocks them');
  } else {
    console.log('✅ All queries pass both syntax and RLS checks');
  }
  console.log('='.repeat(60));
})();
