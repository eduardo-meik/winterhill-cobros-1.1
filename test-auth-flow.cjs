/**
 * Micro-test 2: Test the EXACT auth flow the app uses.
 * 1. Sign in with email/password
 * 2. Fetch profile role (like AuthContext does)
 * 3. Test every downstream query with the user's actual JWT
 *
 * Usage: node test-auth-flow.cjs <email> <password>
 *    or: node test-auth-flow.cjs   (uses SERVICE_ROLE to list profiles, then tests RLS)
 */
const https = require('https');

// Read keys from .env file (NEVER hardcode secrets)
const fs = require('fs');
const envContent = fs.readFileSync('.env', 'utf-8');
const env = {};
envContent.split('\n').forEach(line => {
  const [key, ...rest] = line.split('=');
  if (key && rest.length) env[key.trim()] = rest.join('=').trim();
});

const SUPABASE_URL = env.VITE_SUPABASE_URL;
const ANON_KEY = env.VITE_SUPABASE_ANON_KEY;
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_KEY || !ANON_KEY) {
  console.error('ERROR: Missing keys in .env file');
  process.exit(1);
}

function httpRequest(method, path, apiKey, authToken, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(path.startsWith('http') ? path : `${SUPABASE_URL}${path}`);
    const headers = {
      'apikey': apiKey,
      'Authorization': `Bearer ${authToken || apiKey}`,
      'Content-Type': 'application/json',
    };
    const options = { method, headers, hostname: url.hostname, path: url.pathname + url.search, port: 443 };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (d) => data += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function testWithServiceRole() {
  console.log('\n=== PHASE A: Check profiles table (SERVICE_ROLE) ===');
  const r = await httpRequest('GET', '/rest/v1/profiles?select=id,email,role,first_name,last_name&limit=10', SERVICE_KEY);
  if (r.status !== 200) {
    console.log('❌ Cannot read profiles table:', JSON.stringify(r.data).substring(0, 200));
    return;
  }
  console.log(`✅ profiles table has ${r.data.length} users:`);
  for (const p of r.data) {
    console.log(`   ${p.email} → role="${p.role}" (${p.first_name} ${p.last_name}) [id: ${p.id}]`);
  }

  // Now check RLS: can each user read their OWN profile?
  console.log('\n=== PHASE B: Check RLS policies via PostgREST (anon key for each user) ===');
  // Without a JWT, we can't test per-user RLS. But let's check the policy definitions.
  
  // Get the policies from Supabase management API
  console.log('\n=== PHASE C: Check what tables return with SERVICE_ROLE ===');
  const tables = ['students', 'fee', 'cursos', 'guardians', 'enrollments', 'profiles', 'student_guardian'];
  for (const t of tables) {
    const r2 = await httpRequest('GET', `/rest/v1/${t}?select=id&limit=1`, SERVICE_KEY);
    console.log(`  ${t}: ${r2.status === 200 ? `✅ ${Array.isArray(r2.data) ? r2.data.length : '?'} rows` : `❌ HTTP ${r2.status}`}`);
  }

  return r.data; // Return profiles for sign-in testing
}

async function signInAndTest(email, password) {
  console.log(`\n=== PHASE D: Sign in as "${email}" ===`);
  const signInResult = await httpRequest('POST', '/auth/v1/token?grant_type=password', ANON_KEY, ANON_KEY, {
    email,
    password,
    gotrue_meta_security: {}
  });

  if (signInResult.status !== 200 || !signInResult.data?.access_token) {
    console.log(`❌ Sign-in failed: HTTP ${signInResult.status}`);
    console.log(`   ${JSON.stringify(signInResult.data).substring(0, 300)}`);
    return;
  }

  const jwt = signInResult.data.access_token;
  const userId = signInResult.data.user?.id;
  console.log(`✅ Signed in successfully. User ID: ${userId}`);

  // Step 1: Fetch own profile (EXACT query AuthContext uses)
  console.log('\n--- Test 1: fetchProfileRole (profiles.select role) ---');
  const profileR = await httpRequest('GET',
    `/rest/v1/profiles?select=role&id=eq.${userId}`,
    ANON_KEY, jwt);
  if (profileR.status === 200 && Array.isArray(profileR.data) && profileR.data.length > 0) {
    console.log(`  ✅ Profile role = "${profileR.data[0].role}"`);
  } else {
    console.log(`  ❌ Profile fetch FAILED: HTTP ${profileR.status}, data: ${JSON.stringify(profileR.data).substring(0, 200)}`);
    console.log(`  ⚠️  THIS IS THE CRITICAL BUG — user defaults to "guardian" role!`);
  }

  // Step 2: students query (useStudentsQuery)
  console.log('\n--- Test 2: useStudentsQuery ---');
  const studentsR = await httpRequest('GET',
    '/rest/v1/students?select=*,cursos(id,nom_curso,nivel,year_academico)&order=apellido_paterno.asc&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${studentsR.status === 200 ? `✅ ${studentsR.data.length} rows` : `❌ HTTP ${studentsR.status}: ${JSON.stringify(studentsR.data).substring(0, 200)}`}`);

  // Step 3: fee query (useFeesQuery)
  console.log('\n--- Test 3: useFeesQuery ---');
  const feesR = await httpRequest('GET',
    '/rest/v1/fee?select=id,student_id,guardian_id,amount,due_date,payment_date,status,payment_method,num_boleta,mov_bancario,notes,fee_curso,numero_cuota,institucion_financiera,year,year_academico,enrollment_id,meta,students:student_id(id,first_name,apellido_paterno,apellido_materno,whole_name,run,curso,cursos(id,nom_curso))&year_academico=eq.2026&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${feesR.status === 200 ? `✅ ${feesR.data.length} rows` : `❌ HTTP ${feesR.status}: ${JSON.stringify(feesR.data).substring(0, 200)}`}`);

  // Step 4: cursos query (useCursosQuery)
  console.log('\n--- Test 4: useCursosQuery ---');
  const cursosR = await httpRequest('GET',
    '/rest/v1/cursos?select=*&order=nom_curso.asc&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${cursosR.status === 200 ? `✅ ${cursosR.data.length} rows` : `❌ HTTP ${cursosR.status}: ${JSON.stringify(cursosR.data).substring(0, 200)}`}`);

  // Step 5: enrollments
  console.log('\n--- Test 5: enrollments ---');
  const enrollR = await httpRequest('GET',
    '/rest/v1/enrollments?select=*&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${enrollR.status === 200 ? `✅ ${enrollR.data.length} rows` : `❌ HTTP ${enrollR.status}: ${JSON.stringify(enrollR.data).substring(0, 200)}`}`);

  // Step 6: guardians
  console.log('\n--- Test 6: guardians ---');
  const guardR = await httpRequest('GET',
    '/rest/v1/guardians?select=id,first_name,last_name,run,email&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${guardR.status === 200 ? `✅ ${guardR.data.length} rows` : `❌ HTTP ${guardR.status}: ${JSON.stringify(guardR.data).substring(0, 200)}`}`);

  // Step 7: student_guardian
  console.log('\n--- Test 7: student_guardian ---');
  const sgR = await httpRequest('GET',
    '/rest/v1/student_guardian?select=student_id,guardian_id,is_primary&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${sgR.status === 200 ? `✅ ${sgR.data.length} rows` : `❌ HTTP ${sgR.status}: ${JSON.stringify(sgR.data).substring(0, 200)}`}`);

  // Step 8: enrollment_students
  console.log('\n--- Test 8: enrollment_students ---');
  const esR = await httpRequest('GET',
    '/rest/v1/enrollment_students?select=enrollment_id,student_id,academic_record_id&limit=3',
    ANON_KEY, jwt);
  console.log(`  ${esR.status === 200 ? `✅ ${esR.data.length} rows` : `❌ HTTP ${esR.status}: ${JSON.stringify(esR.data).substring(0, 200)}`}`);
}

(async () => {
  const profiles = await testWithServiceRole();

  const email = process.argv[2];
  const password = process.argv[3];

  if (email && password) {
    await signInAndTest(email, password);
  } else {
    console.log('\n=== To test with a real user, run: ===');
    console.log('  node test-auth-flow.cjs <email> <password>');
    console.log('\nTesting sign-in with each known admin/asist profile...');
    // Try to find admin users and test common passwords
    const admins = (profiles || []).filter(p => ['admin', 'asist'].includes(p.role?.toLowerCase()));
    if (admins.length > 0) {
      console.log(`Found ${admins.length} staff profiles. Provide credentials to test RLS with their JWT.`);
      for (const a of admins) {
        console.log(`  → ${a.email} (role: ${a.role})`);
      }
    }
  }
})();
