/**
 * Run manual review queries and save output
 * Usage: node sql/run_manual_review.cjs
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

function printRows(rows, maxRows) {
  maxRows = maxRows || 200;
  if (!rows || rows.length === 0) return '';
  var lines = [];
  var keys = Object.keys(rows[0]);
  var colWidths = keys.map(function(k) {
    var maxVal = Math.max(k.length, Math.max.apply(null, rows.slice(0, maxRows).map(function(r) {
      var v = r[k];
      if (v === null || v === undefined) return 4;
      return Math.min(String(v).length, 50);
    })));
    return Math.min(maxVal, 50);
  });
  lines.push('  ' + keys.map(function(k, i) { return k.padEnd(colWidths[i]); }).join(' | '));
  lines.push('  ' + colWidths.map(function(w) { return '-'.repeat(w); }).join('-+-'));
  var display = rows.slice(0, maxRows);
  for (var j = 0; j < display.length; j++) {
    var row = display[j];
    var vals = keys.map(function(k, i) {
      var v = row[k];
      if (v === null || v === undefined) return 'NULL';
      var s = String(v);
      return s.length > 50 ? s.substring(0, 47) + '...' : s;
    });
    lines.push('  ' + vals.map(function(v, i) { return v.padEnd(colWidths[i]); }).join(' | '));
  }
  if (rows.length > maxRows) {
    lines.push('  ... y ' + (rows.length - maxRows) + ' mas');
  }
  return lines.join('\n');
}

async function main() {
  console.log('[*] Obteniendo access token...');
  const token = getAccessToken();
  console.log('[OK] Token obtenido');
  
  const sqlFile = fs.readFileSync(path.join(__dirname, 'manual_review_queries.sql'), 'utf-8');
  const statements = sqlFile.split(';').map(s => s.trim()).filter(s => s.length > 0 && !s.startsWith('--'));
  
  var output = [];
  output.push('='.repeat(70));
  output.push('REGISTROS PARA REVISIÓN MANUAL - ' + new Date().toISOString().split('T')[0]);
  output.push('='.repeat(70));
  output.push('');
  
  var currentSection = '';
  
  for (var i = 0; i < statements.length; i++) {
    var sql = statements[i];
    try {
      var rows = await executeSQL(token, sql);
      if (rows && rows.length === 1 && rows[0].seccion) {
        currentSection = rows[0].seccion;
        output.push('');
        output.push('-'.repeat(70));
        output.push(currentSection);
        output.push('-'.repeat(70));
        continue;
      }
      if (rows && rows.length > 0) {
        output.push('  ' + rows.length + ' registro(s):');
        output.push(printRows(rows));
        output.push('');
      } else {
        output.push('  ✅ 0 registros encontrados');
        output.push('');
      }
    } catch(e) {
      output.push('  [ERROR] ' + e.message);
      output.push('');
    }
  }
  
  var text = output.join('\n');
  console.log(text);
  
  var outPath = path.join(__dirname, '..', 'docs', 'MANUAL_REVIEW_RECORDS.txt');
  fs.writeFileSync(outPath, text, 'utf-8');
  console.log('\n[SAVED] ' + outPath);
}

main().catch(function(e) { console.error(e); process.exit(1); });
