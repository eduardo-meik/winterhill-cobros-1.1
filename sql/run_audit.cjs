/**
 * Database Audit Script
 * Executes audit SQL files against the remote Supabase database
 * via Supabase Management API
 * Usage: node sql/run_audit.cjs
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
  maxRows = maxRows || 25;
  if (!rows || rows.length === 0) return;
  var keys = Object.keys(rows[0]);
  var colWidths = keys.map(function(k) {
    var maxVal = Math.max(k.length, Math.max.apply(null, rows.slice(0, maxRows).map(function(r) {
      var v = r[k];
      if (v === null || v === undefined) return 4;
      return Math.min(String(v).length, 40);
    })));
    return Math.min(maxVal, 40);
  });
  console.log('  ' + keys.map(function(k, i) { return k.padEnd(colWidths[i]); }).join(' | '));
  console.log('  ' + colWidths.map(function(w) { return '-'.repeat(w); }).join('-+-'));
  var display = rows.slice(0, maxRows);
  for (var j = 0; j < display.length; j++) {
    var row = display[j];
    var vals = keys.map(function(k, i) {
      var v = row[k];
      if (v === null || v === undefined) return 'NULL';
      var s = String(v);
      return s.length > 40 ? s.substring(0, 37) + '...' : s;
    });
    console.log('  ' + vals.map(function(v, i) { return v.padEnd(colWidths[i]); }).join(' | '));
  }
  if (rows.length > maxRows) {
    console.log('  ... y ' + (rows.length - maxRows) + ' mas');
  }
}

async function runAuditFile(token, filePath) {
  var rawSql = fs.readFileSync(filePath, 'utf-8');
  var statements = rawSql.split(/;\s*\n/).map(function(s) { return s.trim(); }).filter(function(s) { return s && !s.startsWith('--'); });
  var results = [];
  var currentSection = null;

  for (var i = 0; i < statements.length; i++) {
    var stmt = statements[i];
    try {
      var data = await executeSQL(token, stmt + ';');
      var rows = Array.isArray(data) ? data : [];

      if (rows.length === 1 && rows[0].seccion && String(rows[0].seccion).includes('===')) {
        currentSection = rows[0].seccion;
        continue;
      }
      if (rows.length === 0 && !currentSection) continue;

      var section = currentSection || 'Query';
      results.push({ section: section, rows: rows, rowCount: rows.length });

      console.log('\n' + '-'.repeat(70));
      console.log(section);
      console.log('-'.repeat(70));

      if (rows.length === 0) {
        console.log('  [OK] Sin problemas encontrados');
      } else {
        var isCountTable = rows[0] && ('tabla' in rows[0]) && ('total' in rows[0]);
        if (isCountTable) {
          console.log('  [INFO] ' + rows.length + ' tabla(s):');
        } else {
          console.log('  [WARN] ' + rows.length + ' registro(s) encontrado(s):');
        }
        printRows(rows);
      }
      currentSection = null;
    } catch (err) {
      console.log('\n  [ERROR] ' + err.message.substring(0, 200));
      results.push({ section: currentSection || 'ERROR', error: err.message, rowCount: 0 });
      currentSection = null;
    }
  }
  return results;
}

async function main() {
  console.log('[*] Obteniendo access token de Supabase...');
  var token = getAccessToken();
  console.log('[OK] Token obtenido (' + token.length + ' chars)');
  console.log('[*] Conectando al proyecto ' + PROJECT_REF + '...\n');

  var auditFiles = [
    'database_audit.sql',
    'database_audit_part2.sql',
    'database_audit_part3.sql',
    'database_audit_part4.sql',
    'database_audit_part5.sql'
  ];

  var allResults = {};
  var totalIssues = 0;

  for (var f = 0; f < auditFiles.length; f++) {
    var file = auditFiles[f];
    var filePath = path.join(__dirname, file);
    if (!fs.existsSync(filePath)) {
      console.log('[SKIP] Archivo ' + file + ' no encontrado');
      continue;
    }
    console.log('\n' + '='.repeat(70));
    console.log('[RUN] Ejecutando: ' + file);
    console.log('='.repeat(70));

    var results = await runAuditFile(token, filePath);
    allResults[file] = results;

    for (var r = 0; r < results.length; r++) {
      if (results[r].rowCount > 0 && !results[r].error) {
        var isCount = results[r].rows && results[r].rows[0] && ('tabla' in results[r].rows[0]) && ('total' in results[r].rows[0]);
        if (!isCount) totalIssues += results[r].rowCount;
      }
    }
  }

  console.log('\n' + '='.repeat(70));
  console.log('[SUMMARY] ' + totalIssues + ' hallazgo(s) total(es) encontrados');
  console.log('='.repeat(70));

  var files = Object.keys(allResults);
  for (var fi = 0; fi < files.length; fi++) {
    var fname = files[fi];
    var issues = allResults[fname].filter(function(r) { return r.rowCount > 0 && !r.error; });
    if (issues.length > 0) {
      console.log('\n[FILE] ' + fname + ':');
      for (var ri = 0; ri < issues.length; ri++) {
        console.log('   [WARN] ' + issues[ri].section.replace(/=== /g, '').replace(/ ===/g, '') + ': ' + issues[ri].rowCount + ' registro(s)');
      }
    }
  }

  console.log('\n[DONE] Auditoria completada.');
}

main().catch(function(err) {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
