/**
 * Cleanup script for categories A and C
 * A: Delete 30 test guardians (cascade related records)
 * C: Fix 10 absurd payment dates
 * 
 * Usage: node sql/run_cleanup_A_C.cjs
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT_REF = 'yeotpplgerfpxviqazrn';

function getAccessToken() {
  const result = execSync('powershell -NoProfile -File sql/get_token.ps1', {
    encoding: 'utf-8',
    cwd: path.resolve(__dirname, '..'),
    timeout: 15000
  }).trim();
  if (!result) throw new Error('Could not get Supabase access token');
  return result;
}

async function executeSQL(token, sql) {
  const resp = await fetch(
    'https://api.supabase.com/v1/projects/' + PROJECT_REF + '/database/query',
    {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: sql })
    }
  );
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error('API ' + resp.status + ': ' + text);
  }
  return resp.json();
}

// 30 test guardian IDs from Section A
const TEST_GUARDIAN_IDS = [
  '90d398c5-308b-470f-b8ee-86f63302c118',
  '58f28e9b-d4b7-4a06-b3c3-0d1164768933',
  'dd18851d-0603-49b2-8930-2739a9ac935a',
  'd9353be9-fedb-4fb4-b3aa-106f29b6ff89',
  'bc923b2d-8411-44ee-a932-c0e2791cb209',
  'ce62cfaf-cefe-4168-a230-8af8b7ef02b5',
  '1af61a51-9c86-4986-8b6f-b5fde62358b9',
  'cecf88c5-acf1-4204-b3b8-2abc848a2f14',
  'c962e039-0606-4306-9ef2-9e033bfb099f',
  'a7c6e18f-bd8c-4f71-a68e-90358dee07c8',
  'c6910368-e030-4f05-9ee2-cf5681d50391',
  '8f6f0840-b2e1-425d-8d94-15b61c906394',
  'bbe8b32b-535e-4ba7-a0f4-155a73a16c0e',
  '075c7fb6-0f33-43be-81ef-a7f605f277c7',
  'b50db3e9-9e65-483c-94f7-c92f30de1d32',
  'ebef4ac9-4dee-4bdf-971a-d201efe7d1d8',
  '83977c87-ef00-4a72-bb9f-0c783991c4e4',
  '36298d47-0781-4ade-abfc-6250e76fa2c6',
  '494dcfde-37d0-41d0-9b24-55c7da6affb7',
  'b777b865-4dde-43d7-8606-bcf484d7650c',
  '91388107-37cc-4159-8199-e21cda308fe7',
  '8d8fc182-29c0-468f-a5a4-ac5515239209',
  'd9b3a3c6-d747-4194-83a9-9377f2aedab2',
  'd8a8f4f4-66cc-4ba9-9168-dbb984636104',
  '97d3d04e-bd58-4b08-b626-e3f449d4ef6c',
  'f66a86a4-da01-48c3-9df6-bd67bfb61b39',
  'a855b5d1-9b7f-4b51-a03b-b93276ca91a0',
  '422cfe6a-9d52-42d1-b70b-d8a761c26117',
  'b82d95a1-0a47-4b8c-a996-d708a4b3bd1a',
  'fb7382ef-6731-45d3-8f1a-fc0670f0a71e'
];

// 10 fee payment date corrections from Section C
const FEE_DATE_FIXES = [
  // { id, wrong_date, corrected_date, alumno }
  { id: '55743c79-38f4-4e51-ac86-a740d8c27560', corrected: '2025-07-08',  alumno: 'CRISTÓBAL ALONSO DÍAZ (cuota 7, 1496→2025)' },
  { id: '6d7e4d41-3f2b-4090-adfe-eaf807fa95a1', corrected: '2025-10-29',  alumno: 'RENATA EMILIA IRARRÁZABAL (cuota 5, 20025→2025)' },
  { id: '8a5d1d18-3ff2-4f51-beed-e07676b83b10', corrected: '2025-12-14',  alumno: 'FRANCESCA LUANA CANALES (cuota 8, 0025→2025)' },
  { id: '1a458eaa-ecb7-46fd-a4c8-8a67d7947f31', corrected: '2025-12-21',  alumno: 'VICENTE MAXIMILIANO CARRASCO (cuota 8, 0025→2025)' },
  { id: '46c5aa17-e343-4ebb-b6ec-b21df1b6dcbf', corrected: '2025-12-21',  alumno: 'VICENTE MAXIMILIANO CARRASCO (cuota 10, 0025→2025)' },
  { id: '2ee5a0d0-a5b2-477c-9166-33d6253549b7', corrected: '2025-03-06',  alumno: 'JOSEFA ANTONIA CISTERNAS (cuota 4, 62025→2025)' },
  { id: '9de639c0-a8d2-4d01-9577-acf36b98e371', corrected: '2025-07-24',  alumno: 'AZKINTU ALEJANDRO BANDA (cuota 3, 242025→2025)' },
  { id: 'b7630a34-97db-4182-847f-1745c6d70c42', corrected: '2025-12-03',  alumno: 'CRISTÓBAL ALONSO DÍAZ (cuota 6, 0205→2025)' },
  { id: '8a26010f-4cc8-47ab-846d-e17cff7bc32b', corrected: '2025-05-28',  alumno: 'JULIAN ANTONIO OTTERMANN (cuota 3, 2028→2025)' },
  { id: '6fe4eea5-9e57-4679-b6ca-9fd14be3fc18', corrected: '2025-09-08',  alumno: 'CLEMENTE GABRIEL MOYA (cuota 2, 92025→2025)' }
];

async function main() {
  const token = getAccessToken();
  console.log('✅ Token obtenido');
  
  const backupDir = path.resolve(__dirname, '..', 'sql', 'backups_pre_limpieza_2026-03-06');
  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

  // ─── PASO 1: BACKUP de los 30 guardians ───
  console.log('\n📦 PASO 1: Backup de apoderados de prueba...');
  const idList = TEST_GUARDIAN_IDS.map(id => "'" + id + "'").join(',');
  
  const backupGuardians = await executeSQL(token,
    "SELECT * FROM guardians WHERE id IN (" + idList + ")"
  );
  fs.writeFileSync(
    path.join(backupDir, 'backup_guardians_test.json'),
    JSON.stringify(backupGuardians, null, 2)
  );
  console.log('  → ' + backupGuardians.length + ' guardians respaldados');

  // Backup related student_guardian links
  const backupSG = await executeSQL(token,
    "SELECT * FROM student_guardian WHERE guardian_id IN (" + idList + ")"
  );
  fs.writeFileSync(
    path.join(backupDir, 'backup_student_guardian_test.json'),
    JSON.stringify(backupSG, null, 2)
  );
  console.log('  → ' + backupSG.length + ' student_guardian links respaldados');

  // Backup related enrollments
  const backupEnrollments = await executeSQL(token,
    "SELECT * FROM enrollments WHERE guardian_id IN (" + idList + ")"
  );
  fs.writeFileSync(
    path.join(backupDir, 'backup_enrollments_test.json'),
    JSON.stringify(backupEnrollments, null, 2)
  );
  console.log('  → ' + backupEnrollments.length + ' enrollments respaldados');

  // ─── PASO 2: BACKUP de las 10 cuotas con fechas absurdas ───
  console.log('\n📦 PASO 2: Backup de cuotas con fechas absurdas...');
  const feeIds = FEE_DATE_FIXES.map(f => "'" + f.id + "'").join(',');
  const backupFees = await executeSQL(token,
    "SELECT * FROM fee WHERE id IN (" + feeIds + ")"
  );
  fs.writeFileSync(
    path.join(backupDir, 'backup_fees_absurd_dates.json'),
    JSON.stringify(backupFees, null, 2)
  );
  console.log('  → ' + backupFees.length + ' fees respaldados');

  // ─── PASO 3: DELETE cascada para guardians de prueba ───
  console.log('\n🗑️  PASO 3: Eliminando datos de prueba (cascada)...');
  
  // 3a: Delete enrollments linked to test guardians
  const delEnrollments = await executeSQL(token,
    "DELETE FROM enrollments WHERE guardian_id IN (" + idList + ") RETURNING id"
  );
  console.log('  → ' + delEnrollments.length + ' enrollments eliminados');

  // 3b: Delete student_guardian links
  const delSG = await executeSQL(token,
    "DELETE FROM student_guardian WHERE guardian_id IN (" + idList + ") RETURNING id"
  );
  console.log('  → ' + delSG.length + ' student_guardian links eliminados');

  // 3c: Delete guardians
  const delGuardians = await executeSQL(token,
    "DELETE FROM guardians WHERE id IN (" + idList + ") RETURNING id, first_name, last_name"
  );
  console.log('  → ' + delGuardians.length + ' guardians eliminados');

  // ─── PASO 4: UPDATE fechas de pago absurdas ───
  console.log('\n✏️  PASO 4: Corrigiendo fechas de pago absurdas...');
  
  for (const fix of FEE_DATE_FIXES) {
    const result = await executeSQL(token,
      "UPDATE fee SET payment_date = '" + fix.corrected + "' WHERE id = '" + fix.id + "' RETURNING id, payment_date"
    );
    if (result.length === 1) {
      console.log('  ✅ ' + fix.alumno + ' → ' + fix.corrected);
    } else {
      console.log('  ❌ FALLO: ' + fix.alumno);
    }
  }

  // ─── PASO 5: VERIFICACIÓN ───
  console.log('\n🔍 PASO 5: Verificación...');
  
  const remainingGuardians = await executeSQL(token,
    "SELECT count(*) as cnt FROM guardians WHERE id IN (" + idList + ")"
  );
  console.log('  Guardians de prueba restantes: ' + remainingGuardians[0].cnt);

  const remainingBadDates = await executeSQL(token,
    "SELECT count(*) as cnt FROM fee WHERE id IN (" + feeIds + ") AND (EXTRACT(YEAR FROM payment_date) < 2020 OR EXTRACT(YEAR FROM payment_date) > 2027)"
  );
  console.log('  Fees con fechas absurdas restantes: ' + remainingBadDates[0].cnt);

  console.log('\n✅ LIMPIEZA COMPLETADA');
  console.log('   Backups guardados en: sql/backups_pre_limpieza_2026-03-06/');
}

main().catch(err => { console.error('❌ ERROR FATAL:', err.message); process.exit(1); });
