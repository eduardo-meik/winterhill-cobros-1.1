/**
 * Diagnostic script — run with:  node test-diagnostics.cjs
 * 
 * Tests Supabase queries as service-role to verify:
 *  1. Auth/session works
 *  2. students + curso:cursos join returns objects (not UUIDs)
 *  3. fee + student:students + curso:cursos nested join works
 *  4. RLS helper functions work
 *  5. cursos table is accessible
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Read .env manually
const envContent = fs.readFileSync('.env', 'utf-8');
const env = {};
envContent.split('\n').forEach(line => {
  const [key, ...rest] = line.split('=');
  if (key && rest.length) env[key.trim()] = rest.join('=').trim();
});

const SUPABASE_URL = env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = env.VITE_SUPABASE_ANON_KEY;
const SUPABASE_SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;

const key = SUPABASE_SERVICE_KEY || SUPABASE_ANON_KEY;
if (!key) {
  console.error('ERROR: No Supabase key found. Set VITE_SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, key);

async function run() {
  let passed = 0;
  let failed = 0;

  function ok(label) { console.log(`  ✅  ${label}`); passed++; }
  function fail(label, detail) { console.log(`  ❌  ${label}: ${detail}`); failed++; }

  // 1. Cursos table
  console.log('\n── 1. cursos table ──');
  {
    const { data, error } = await supabase.from('cursos').select('id, nom_curso, nivel').limit(3);
    if (error) fail('SELECT cursos', error.message);
    else if (!data?.length) fail('SELECT cursos', 'table is empty');
    else ok(`cursos: ${data.length} rows, first: ${data[0].nom_curso}`);
  }

  // 2. students + curso:cursos join
  console.log('\n── 2. students + curso:cursos join ──');
  {
    const { data, error } = await supabase
      .from('students')
      .select('id, whole_name, run, curso:cursos(id, nom_curso, nivel)')
      .limit(3);
    if (error) {
      fail('students join', error.message);
    } else if (!data?.length) {
      fail('students join', 'no students returned');
    } else {
      const s = data[0];
      if (typeof s.curso === 'string') {
        fail('students join', `curso is a UUID string "${s.curso}" instead of an object. The join alias is broken.`);
      } else if (s.curso && typeof s.curso === 'object') {
        ok(`students join OK. student="${s.whole_name}", curso.nom_curso="${s.curso.nom_curso}"`);
      } else {
        ok(`students join OK (curso is null for student "${s.whole_name}")`);
      }
    }
  }

  // 3. fee + student:students + curso:cursos nested join
  console.log('\n── 3. fee + student:students(curso:cursos) nested join ──');
  {
    const { data, error } = await supabase
      .from('fee')
      .select(`
        id, student_id, status,
        student:students(
          id, whole_name, run,
          curso:cursos(id, nom_curso)
        )
      `)
      .limit(3);
    if (error) {
      fail('fee nested join', error.message);
    } else if (!data?.length) {
      fail('fee nested join', 'no fees returned');
    } else {
      const f = data[0];
      const stu = f.student;
      if (!stu) {
        fail('fee nested join', 'student is null on fee');
      } else if (typeof stu.curso === 'string') {
        fail('fee nested join', `student.curso is UUID "${stu.curso}" not an object`);
      } else {
        ok(`fee join OK. student="${stu.whole_name}", curso="${stu.curso?.nom_curso || '(null)'}"`);
      }
    }
  }

  // 4. RLS functions
  console.log('\n── 4. RLS helper functions ──');
  {
    const { data, error } = await supabase.rpc('get_current_user_role');
    if (error) {
      // Expected for service-role (no auth.uid())
      ok(`get_current_user_role: ${error.message} (expected for service-role, OK)`);
    } else {
      ok(`get_current_user_role returned: "${data}"`);
    }
  }

  // 5. profiles sample
  console.log('\n── 5. profiles sample ──');
  {
    const { data, error } = await supabase.from('profiles').select('id, email, role').limit(5);
    if (error) {
      fail('profiles', error.message);
    } else {
      data.forEach(p => console.log(`     ${p.email} → role="${p.role}"`));
      ok(`${data.length} profiles listed`);
    }
  }

  // Summary
  console.log(`\n══════════════════════════════════════`);
  console.log(`  RESULTADO: ${passed} passed, ${failed} failed`);
  console.log(`══════════════════════════════════════\n`);
}

run().catch(err => { console.error('Fatal:', err); process.exit(1); });
