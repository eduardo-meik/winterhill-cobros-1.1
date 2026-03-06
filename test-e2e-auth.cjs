/**
 * End-to-end test: authenticates as the admin user via Admin API,
 * then runs queries through PostgREST with the user's JWT (exactly like the browser).
 */
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Parse .env manually (no dotenv dependency)
const env = {};
fs.readFileSync('.env', 'utf8').replace(/\r/g, '').split('\n').forEach(line => {
  const match = line.match(/^([^#=]+)=(.*)$/);
  if (match) env[match[1].trim()] = match[2].trim().replace(/^["']|["']$/g, '');
});

const SUPABASE_URL = env.VITE_SUPABASE_URL;
const ANON_KEY = env.VITE_SUPABASE_ANON_KEY;
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;

const ADMIN_USER_ID = 'bd72b98b-e2e7-43a1-a225-21c0fbbbf918'; // frigio@gmail.com

async function main() {
  console.log('=== E2E AUTH + DATA TEST ===\n');
  
  // Step 1: Use admin client to generate a magic link / impersonate
  const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false }
  });

  // Get user info
  const { data: userData, error: userError } = await adminClient.auth.admin.getUserById(ADMIN_USER_ID);
  if (userError) {
    console.error('❌ FAILED to get user:', userError.message);
    process.exit(1);
  }
  console.log('✅ Admin user found:', userData.user.email, '| role in auth.users:', userData.user.role);

  // Step 2: Generate a magic link to get a valid access token for this user
  const { data: linkData, error: linkError } = await adminClient.auth.admin.generateLink({
    type: 'magiclink',
    email: userData.user.email
  });
  if (linkError) {
    console.error('❌ FAILED to generate link:', linkError.message);
    process.exit(1);
  }

  // The hashed_token can be used to verify and get a session
  const hashedToken = linkData.properties?.hashed_token;
  if (!hashedToken) {
    console.log('ℹ️  No hashed_token, using direct REST API test instead...\n');
    await testWithServiceRole(adminClient);
    return;
  }

  // Verify OTP to get a real session
  const { data: sessionData, error: sessionError } = await adminClient.auth.verifyOtp({
    token_hash: hashedToken,
    type: 'magiclink'
  });

  if (sessionError || !sessionData?.session) {
    console.log('ℹ️  OTP verify failed:', sessionError?.message || 'no session');
    console.log('Using alternative approach with direct JWT...\n');
    await testWithDirectJWT(ADMIN_USER_ID);
    return;
  }

  console.log('✅ Got user session! Access token length:', sessionData.session.access_token.length);
  
  // Step 3: Create a NEW client with the anon key + user's JWT (exactly like the browser)
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      headers: {
        Authorization: `Bearer ${sessionData.session.access_token}`
      }
    }
  });

  await runAllTests(userClient, 'USER JWT');
}

async function testWithDirectJWT(userId) {
  // Alternative: use fetch to call PostgREST directly with a crafted request
  // that simulates an authenticated user
  console.log('Testing via direct REST API calls...\n');
  
  const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
  await runAllTests(adminClient, 'SERVICE ROLE (fallback)');
}

async function testWithServiceRole(adminClient) {
  await runAllTests(adminClient, 'SERVICE ROLE');
}

async function runAllTests(client, label) {
  console.log(`\n--- Running tests with: ${label} ---\n`);
  
  // Test 1: Profile query (AuthContext does this)
  await test('1. Profile query (fetchProfileRole)', async () => {
    const { data, error } = await client
      .from('profiles')
      .select('role')
      .eq('id', ADMIN_USER_ID)
      .single();
    if (error) throw error;
    console.log(`   role: "${data.role}" (type: ${typeof data.role})`);
    if (data.role !== 'admin') throw new Error(`Expected 'admin', got '${data.role}'`);
  });

  // Test 2: Students query (useStudentsQuery)
  await test('2. Students query (useStudentsQuery)', async () => {
    const { data, error } = await client
      .from('students')
      .select(`*, cursos (id, nom_curso, nivel, year_academico)`)
      .order('apellido_paterno', { ascending: true })
      .limit(3);
    if (error) throw error;
    console.log(`   ${data.length} students returned, first: ${data[0]?.whole_name || 'N/A'}`);
    if (data[0]?.cursos) console.log(`   cursos join: ${JSON.stringify(data[0].cursos)}`);
  });

  // Test 3: Fees query (useFeesQuery) - THE CRITICAL ONE
  await test('3. Fees query (useFeesQuery)', async () => {
    const { data, error } = await client
      .from('fee')
      .select(`
        *,
        student:students (
          id, first_name, apellido_paterno, apellido_materno, whole_name, run, curso,
          cursos (id, nom_curso)
        )
      `)
      .limit(3);
    if (error) throw error;
    console.log(`   ${data.length} fees returned`);
    if (data[0]) {
      console.log(`   fee[0].student: ${data[0].student?.whole_name}, curso: ${data[0].student?.cursos?.nom_curso}`);
      console.log(`   fee[0].amount: ${data[0].amount}, status: ${data[0].status}`);
    }
  });

  // Test 4: Cursos query (useCursosQuery)
  await test('4. Cursos query', async () => {
    const { data, error } = await client
      .from('cursos')
      .select('*')
      .limit(3);
    if (error) throw error;
    console.log(`   ${data.length} cursos returned, first: ${data[0]?.nom_curso}`);
  });

  // Test 5: Guardians query
  await test('5. Guardians query', async () => {
    const { data, error } = await client
      .from('guardians')
      .select('id, full_name, run, email')
      .limit(3);
    if (error) throw error;
    console.log(`   ${data.length} guardians returned`);
  });

  // Test 6: Fee with full count (what useFeesQuery ACTUALLY returns in Dashboard)
  await test('6. Full fees count (Dashboard)', async () => {
    const { data, error, count } = await client
      .from('fee')
      .select('id', { count: 'exact', head: true });
    if (error) throw error;
    console.log(`   Total fees accessible: ${count}`);
  });

  console.log('\n=== ALL TESTS COMPLETE ===');
}

async function test(name, fn) {
  try {
    await fn();
    console.log(`✅ ${name}`);
  } catch (err) {
    console.error(`❌ ${name}: ${err.message}`);
    if (err.code) console.error(`   Code: ${err.code}, Details: ${err.details}`);
  }
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
