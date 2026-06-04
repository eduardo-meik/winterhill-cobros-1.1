#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const value = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : 'true';
    args[key] = value;
    if (value !== 'true') i += 1;
  }
  return args;
}

function main() {
  const args = parseArgs(process.argv);
  const input = args.input || 'tmp_horarios_consolidados_import.sql';
  const outDir = args.outdir || 'tmp_horarios_batches';
  const batchSize = Number(args['batch-size'] || 350);

  const sql = fs.readFileSync(input, 'utf8');

  const splitToken = 'WITH horarios_seed(owner_id, nombre_normalizado, dia_semana, hora_inicio, hora_fin, actividad, es_lectivo) AS (\n  VALUES\n';
  const postToken = '\n), docentes_ref AS (';

  const splitIndex = sql.indexOf(splitToken);
  const postIndex = sql.indexOf(postToken);

  if (splitIndex < 0 || postIndex < 0) {
    throw new Error('No se pudo localizar el bloque horarios_seed en el SQL.');
  }

  const pre = sql.slice(0, splitIndex);
  const valuesBlock = sql.slice(splitIndex + splitToken.length, postIndex);
  const post = sql.slice(postIndex);

  const lines = valuesBlock
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => line.replace(/,$/, ''));

  fs.mkdirSync(outDir, { recursive: true });

  const chunks = [];
  for (let i = 0; i < lines.length; i += batchSize) {
    chunks.push(lines.slice(i, i + batchSize));
  }

  chunks.forEach((chunk, idx) => {
    const body = chunk.map((line, j) => `${line}${j < chunk.length - 1 ? ',' : ''}`).join('\n    ');
    const chunkSql = `${pre}${splitToken}    ${body}${post}`;
    const file = path.join(outDir, `batch_${String(idx + 1).padStart(2, '0')}.sql`);
    fs.writeFileSync(file, chunkSql, 'utf8');
  });

  console.log(`Batches: ${chunks.length}`);
  console.log(`Output dir: ${outDir}`);
}

main();
