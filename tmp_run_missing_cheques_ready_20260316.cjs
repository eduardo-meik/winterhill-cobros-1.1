const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT_REF = 'yeotpplgerfpxviqazrn';

function readEnv(filePath) {
  const env = {};
  const raw = fs.readFileSync(filePath, 'utf8');
  for (const line of raw.split(/\r?\n/)) {
    if (!line || /^\s*#/.test(line) || /^\s*$/.test(line)) continue;
    const idx = line.indexOf('=');
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim().replace(/^"|"$/g, '');
    env[key] = value;
  }
  return env;
}

function splitSections(sql) {
  const lines = sql.split(/\r?\n/);
  const sections = [];
  let current = [];

  for (const line of lines) {
    if (line.startsWith('-- enrollment_id:')) {
      if (current.length) sections.push(current.join('\n'));
      current = [line];
      continue;
    }
    if (current.length) current.push(line);
  }

  if (current.length) sections.push(current.join('\n'));
  return sections;
}

function getAccessToken(root) {
  const token = execSync('powershell -NoProfile -File sql/get_token.ps1', {
    cwd: root,
    encoding: 'utf8',
    timeout: 15000
  }).trim();

  if (!token) {
    throw new Error('No se pudo obtener el access token de Supabase CLI');
  }

  return token;
}

async function execSql(accessToken, query) {
  const response = await fetch(`https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ query })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`HTTP ${response.status}: ${text}`);
  }

  return response.text();
}

async function main() {
  const root = process.cwd();
  const env = readEnv(path.join(root, '.env'));
  const baseUrl = env.VITE_SUPABASE_URL;

  if (!baseUrl) {
    throw new Error('Falta VITE_SUPABASE_URL en .env');
  }

  const accessToken = getAccessToken(root);

  const sqlPath = path.join(root, 'tmp_insert_missing_cheques_20260316_ready.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');
  const sections = splitSections(sql);

  console.log(`[*] Secciones detectadas: ${sections.length}`);

  for (let index = 0; index < sections.length; index += 1) {
    const section = sections[index]
      .replace(/^\s*commit;\s*$/gim, '')
      .replace(/^\s*begin;\s*$/gim, '')
      .trim();

    const header = section.split(/\r?\n/, 1)[0];
    const query = `begin;\n${section}\ncommit;`;

    console.log(`[*] ${index + 1}/${sections.length} ${header}`);
    await execSql(accessToken, query);
  }

  console.log('[OK] Carga completa finalizada');
}

main().catch((error) => {
  console.error('[ERROR]', error.message);
  process.exitCode = 1;
});