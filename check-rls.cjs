const https = require('https');
const fs = require('fs');
const envContent = fs.readFileSync('.env', 'utf-8');
const env = {};
envContent.split('\n').forEach(line => {
  const [key, ...rest] = line.split('=');
  if (key && rest.length) env[key.trim()] = rest.join('=').trim();
});
const SK = env.SUPABASE_SERVICE_ROLE_KEY;
const SUPABASE_URL = env.VITE_SUPABASE_URL;
if (!SK || !SUPABASE_URL) { console.error('Missing keys in .env'); process.exit(1); }

function httpRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(SUPABASE_URL + path);
    const headers = {
      'apikey': SK,
      'Authorization': 'Bearer ' + SK,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
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

(async () => {
  // Try the SQL approach
  console.log('=== Attempt to read pg_policies via RPC ===');
  const sql = "SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check FROM pg_policies WHERE tablename IN ('profiles','students','fee','cursos','guardians','enrollments','student_guardian') ORDER BY tablename, policyname";
  
  const r = await httpRequest('POST', '/rest/v1/rpc/exec_sql', { sql });
  if (r.status === 200) {
    console.log('Policies:', JSON.stringify(r.data, null, 2).substring(0, 5000));
    return;
  }
  console.log('exec_sql failed:', r.status, JSON.stringify(r.data).substring(0, 300));

  // Try alternate function name
  const r2 = await httpRequest('POST', '/rest/v1/rpc/run_sql', { query: sql });
  if (r2.status === 200) {
    console.log('Policies:', JSON.stringify(r2.data, null, 2).substring(0, 5000));
    return;
  }
  console.log('run_sql failed:', r2.status);

  // Just test the critical flow: can an authenticated user read their own profile?
  // We can simulate this by checking if the ANON key can read profiles (it shouldn't)
  const ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllb3RwcGxnZXJmcHh2aXFhenJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4OTc4MjYsImV4cCI6MjA2MDQ3MzgyNn0.qfjT0PLm3ff4m3jr7FGEAYCu0Gm97YEtZDUe-tS_urs';

  console.log('\n=== Test: anon key reading profiles ===');
  const headers3 = {
    'apikey': ANON,
    'Authorization': 'Bearer ' + ANON,
    'Content-Type': 'application/json',
  };
  const r3 = await new Promise((resolve, reject) => {
    const req = https.request({
      method: 'GET', hostname: 'yeotpplgerfpxviqazrn.supabase.co',
      path: '/rest/v1/profiles?select=id,role&limit=3', port: 443, headers: headers3
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => { try { resolve({ status: res.statusCode, data: JSON.parse(data) }); } catch { resolve({ status: res.statusCode, data }); } });
    });
    req.on('error', reject);
    req.end();
  });
  console.log(`  anon profiles: HTTP ${r3.status}, rows: ${Array.isArray(r3.data) ? r3.data.length : 'N/A'}, data: ${JSON.stringify(r3.data).substring(0, 200)}`);

  console.log('\nNeed user credentials to test authenticated RLS. Use: node test-auth-flow.cjs <email> <password>');
})();
