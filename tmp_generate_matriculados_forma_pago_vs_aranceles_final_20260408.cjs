const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT_REF = 'yeotpplgerfpxviqazrn';
const ENV_PATH = path.join(__dirname, '.env');
const OUTPUT_PATH = path.join(
  __dirname,
  'reporte_matriculados_forma_pago_vs_aranceles_2026_20260408.csv'
);

function loadEnv(filePath) {
  const env = {};
  const content = fs.readFileSync(filePath, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#')) continue;
    const eqIndex = line.indexOf('=');
    if (eqIndex === -1) continue;
    const key = line.slice(0, eqIndex).trim();
    const value = line.slice(eqIndex + 1).trim();
    env[key] = value;
  }
  return env;
}

async function executeSQL(token, sql) {
  const response = await fetch(
    `https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query: sql }),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`API ${response.status}: ${text}`);
  }

  return response.json();
}

function getAccessToken() {
  const token = execSync('powershell -NoProfile -File sql/get_token.ps1', {
    encoding: 'utf8',
    cwd: __dirname,
    timeout: 15000,
  }).trim();

  if (!token) {
    throw new Error('No se pudo obtener un access token valido');
  }

  return token;
}

function csvEscape(value) {
  if (value === null || value === undefined) return '""';
  const text = String(value).replace(/"/g, '""');
  return `"${text}"`;
}

function buildCsv(rows) {
  if (!rows.length) return '';
  const headers = Object.keys(rows[0]);
  const lines = [headers.map(csvEscape).join(',')];

  for (const row of rows) {
    lines.push(headers.map((header) => csvEscape(row[header])).join(','));
  }

  return lines.join('\n');
}

const sql = String.raw`
with enrollment_students_2026 as (
  select
    e.id as enrollment_id,
    e.year,
    e.status as enrollment_status,
    e.meta,
    es.student_id,
    s.whole_name,
    s.run,
    c.nom_curso
  from public.enrollments e
  join public.enrollment_students es on es.enrollment_id = e.id
  join public.students s on s.id = es.student_id
  left join public.cursos c on c.id = s.curso
  where e.year = 2026
    and e.status = 'completed'
), normalized_enrollment as (
  select
    base.*,
    case
      when lower(coalesce((base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'prioritario'), base.meta ->> 'prioritario', 'false')) = 'true' then 'PRIORITARIO'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%PAGARE%' then 'PAGARE'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%CHEQ%' then 'CHEQUE'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%TARJ%' then 'TARJETA'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%TRANS%' then 'TRANSFERENCIA'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%PLANILL%' then 'PLANILLA'
      when upper(coalesce(nullif(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'payment_method', ''), nullif(base.meta ->> 'payment_method', ''))) like '%EFECT%' then 'EFECTIVO'
      when lower(coalesce(base.meta ->> 'forma_pago_pagare', 'false')) = 'true' then 'PAGARE'
      when lower(coalesce(base.meta ->> 'forma_pago_cheques', 'false')) = 'true' then 'CHEQUE'
      when lower(coalesce(base.meta ->> 'forma_pago_tarjeta', 'false')) = 'true' then 'TARJETA'
      when lower(coalesce(base.meta ->> 'forma_pago_transferencia', 'false')) = 'true' then 'TRANSFERENCIA'
      when lower(coalesce(base.meta ->> 'forma_pago_descuento_planilla', 'false')) = 'true' then 'PLANILLA'
      when lower(coalesce(base.meta ->> 'forma_pago_efectivo', 'false')) = 'true' then 'EFECTIVO'
      else 'SIN_DATO'
    end as "Matrícula: Forma de Pago",
    lower(coalesce((base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'prioritario'), base.meta ->> 'prioritario', 'false')) = 'true' as "Matrícula: Prioritario",
    case
      when regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'cantidad_cuotas', base.meta ->> 'cantidad_cuotas', base.meta #>> '{payment_plan,n_cuotas}', ''), '[^0-9-]', '', 'g') <> ''
      then regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'cantidad_cuotas', base.meta ->> 'cantidad_cuotas', base.meta #>> '{payment_plan,n_cuotas}', ''), '[^0-9-]', '', 'g')::int
      else null end as "Matrícula: N° Cuotas",
    case
      when regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'monto_cuota', base.meta ->> 'monto_cuota', base.meta #>> '{payment_plan,monto_por_cuota}', ''), '[^0-9.-]', '', 'g') <> ''
      then regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'monto_cuota', base.meta ->> 'monto_cuota', base.meta #>> '{payment_plan,monto_por_cuota}', ''), '[^0-9.-]', '', 'g')::numeric
      else null end as "Matrícula: Monto por Cuota",
    case
      when regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'colegiatura_anual', base.meta ->> 'colegiatura_anual', base.meta #>> '{payment_plan,monto_total}', ''), '[^0-9.-]', '', 'g') <> ''
      then regexp_replace(coalesce(base.meta -> 'per_student_economic' -> (base.student_id::text) ->> 'colegiatura_anual', base.meta ->> 'colegiatura_anual', base.meta #>> '{payment_plan,monto_total}', ''), '[^0-9.-]', '', 'g')::numeric
      else null end as "Matrícula: Total Anual"
  from enrollment_students_2026 base
), fee_agg as (
  select
    f.student_id,
    count(*) as "Aranceles: N° Cuotas",
    string_agg(distinct case
      when upper(coalesce(f.payment_method, '')) like '%PAGARE%' then 'PAGARE'
      when upper(coalesce(f.payment_method, '')) like '%CHEQ%' then 'CHEQUE'
      when upper(coalesce(f.payment_method, '')) like '%TARJ%' then 'TARJETA'
      when upper(coalesce(f.payment_method, '')) like '%TRANS%' then 'TRANSFERENCIA'
      when upper(coalesce(f.payment_method, '')) like '%PLANILL%' then 'PLANILLA'
      when upper(coalesce(f.payment_method, '')) like '%EFECT%' then 'EFECTIVO'
      when coalesce(f.payment_method, '') = '' then 'SIN_DATO'
      else upper(f.payment_method)
    end, '|' order by case
      when upper(coalesce(f.payment_method, '')) like '%PAGARE%' then 'PAGARE'
      when upper(coalesce(f.payment_method, '')) like '%CHEQ%' then 'CHEQUE'
      when upper(coalesce(f.payment_method, '')) like '%TARJ%' then 'TARJETA'
      when upper(coalesce(f.payment_method, '')) like '%TRANS%' then 'TRANSFERENCIA'
      when upper(coalesce(f.payment_method, '')) like '%PLANILL%' then 'PLANILLA'
      when upper(coalesce(f.payment_method, '')) like '%EFECT%' then 'EFECTIVO'
      when coalesce(f.payment_method, '') = '' then 'SIN_DATO'
      else upper(f.payment_method)
    end) as "Aranceles: Forma de Pago",
    min(f.amount) as "Aranceles: Monto Cuota Mínimo",
    max(f.amount) as "Aranceles: Monto Cuota Máximo",
    sum(f.amount) as "Aranceles: Total",
    min(f.numero_cuota) as "Aranceles: N° Cuota Mínima",
    max(f.numero_cuota) as "Aranceles: N° Cuota Máxima"
  from public.fee f
  where f.year_academico = 2026
  group by f.student_id
)
select
  ne.enrollment_id as "ID Matrícula",
  ne.student_id as "ID Estudiante",
  ne.run as "RUT",
  ne.whole_name as "Estudiante",
  ne.nom_curso as "Curso",
  ne.enrollment_status as "Estado Matrícula",
  ne."Matrícula: Forma de Pago",
  ne."Matrícula: Prioritario",
  ne."Matrícula: N° Cuotas",
  ne."Matrícula: Monto por Cuota",
  ne."Matrícula: Total Anual",
  coalesce(fa."Aranceles: N° Cuotas", 0) as "Aranceles: N° Cuotas",
  coalesce(fa."Aranceles: Forma de Pago", 'SIN_FEE') as "Aranceles: Forma de Pago",
  fa."Aranceles: Monto Cuota Mínimo",
  fa."Aranceles: Monto Cuota Máximo",
  fa."Aranceles: Total",
  fa."Aranceles: N° Cuota Mínima",
  fa."Aranceles: N° Cuota Máxima",
  case
    when ne."Matrícula: Forma de Pago" = 'PRIORITARIO' and coalesce(fa."Aranceles: N° Cuotas", 0) = 0 then 'OK'
    when ne."Matrícula: Forma de Pago" = 'PRIORITARIO' and coalesce(fa."Aranceles: N° Cuotas", 0) > 0 then 'PRIORITARIO_CON_FEE'
    when ne."Matrícula: Forma de Pago" <> 'PRIORITARIO' and coalesce(fa."Aranceles: N° Cuotas", 0) = 0 and coalesce(ne."Matrícula: N° Cuotas", 0) > 0 then 'FEE_FALTANTE'
    when ne."Matrícula: Forma de Pago" <> 'PRIORITARIO' and position(ne."Matrícula: Forma de Pago" in coalesce(fa."Aranceles: Forma de Pago", '')) > 0 then 'OK'
    when ne."Matrícula: Forma de Pago" <> 'PRIORITARIO' and coalesce(fa."Aranceles: Forma de Pago", '') = 'SIN_FEE' then 'FEE_FALTANTE'
    else 'FORMA_PAGO_DISTINTA'
  end as "Comparación Forma de Pago",
  case
    when coalesce(ne."Matrícula: N° Cuotas", 0) = coalesce(fa."Aranceles: N° Cuotas", 0) then 'OK'
    else 'CUOTAS_DISTINTAS'
  end as "Comparación Cuotas",
  case
    when coalesce(ne."Matrícula: Monto por Cuota", -1) = coalesce(fa."Aranceles: Monto Cuota Mínimo", -1)
     and coalesce(ne."Matrícula: Monto por Cuota", -1) = coalesce(fa."Aranceles: Monto Cuota Máximo", -1) then 'OK'
    else 'MONTO_DISTINTO'
  end as "Comparación Monto",
  case
    when coalesce(ne."Matrícula: Total Anual", -1) = coalesce(fa."Aranceles: Total", -1) then 'OK'
    else 'TOTAL_DISTINTO'
  end as "Comparación Total"
from normalized_enrollment ne
left join fee_agg fa on fa.student_id = ne.student_id
order by ne.nom_curso, ne.whole_name;
`;

async function main() {
  const env = loadEnv(ENV_PATH);
  const token = getAccessToken() || env.SUPABASE_ACCESS_TOKEN;

  const rows = await executeSQL(token, sql);
  const csv = buildCsv(rows);
  fs.writeFileSync(OUTPUT_PATH, '\uFEFF' + csv, 'utf8');

  console.log(`Registros exportados: ${rows.length}`);
  console.log(`Archivo generado: ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});