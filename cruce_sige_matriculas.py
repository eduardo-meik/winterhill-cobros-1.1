#!/usr/bin/env python3
"""
Cruce de información: sige_2026.csv vs tabla enrollments (matrículas) en Supabase.
Compara cada alumno del SIGE con su matrícula registrada en la BD.
"""
import os, csv, json, re, requests
from dotenv import load_dotenv
load_dotenv()

URL = os.getenv('VITE_SUPABASE_URL')
KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
HEADERS = {'apikey': KEY, 'Authorization': f'Bearer {KEY}'}

def api_get(endpoint, params=None):
    r = requests.get(f'{URL}/rest/v1/{endpoint}', headers=HEADERS, params=params or {})
    r.raise_for_status()
    return r.json()

def api_get_all(endpoint, select='*', filters=None):
    all_data, offset, limit = [], 0, 1000
    while True:
        params = {'select': select, 'limit': str(limit), 'offset': str(offset)}
        if filters:
            params.update(filters)
        data = api_get(endpoint, params)
        all_data.extend(data)
        if len(data) < limit:
            break
        offset += limit
    return all_data

def normalize_rut(rut_str):
    """'25.372.029-8' -> '25372029'  (solo parte numérica sin verificador)"""
    if not rut_str:
        return ''
    clean = re.sub(r'[\.\s\xa0]', '', rut_str.strip())
    if '-' in clean:
        clean = clean.split('-')[0]
    return re.sub(r'[^0-9]', '', clean).lstrip('0')

def parse_money(val):
    if not val:
        return 0
    val = val.strip().replace('$', '').replace(' ', '').replace(',', '')
    if '.' in val:
        parts = val.split('.')
        if len(parts) == 2 and len(parts[1]) == 3:
            val = val.replace('.', '')
    try:
        return int(float(val))
    except ValueError:
        return 0

# ──────────────────────────────────────────────
# 1. Cargar SIGE 2026
# ──────────────────────────────────────────────
print('=' * 80)
print('CRUCE: SIGE 2026 vs TABLA DE MATRÍCULAS (enrollments)')
print('=' * 80)

sige_rows = list(csv.reader(open('sige_2026.csv', encoding='utf-8')))
sige_header = sige_rows[0]
# Cols: CURSO, '', RUT, NOMBRE, '', '', '', PAGO, CUOTA, N_CUOTAS, INGRESO_ANUAL, OBSERVACION
sige_students = {}
for row in sige_rows[1:]:
    if len(row) < 12:
        row.extend([''] * (12 - len(row)))
    rut_num = normalize_rut(row[2])
    if not rut_num:
        continue
    nombre = row[3].replace('\xa0', ' ').strip()
    sige_students[rut_num] = {
        'rut_raw': row[2].strip(),
        'curso_sige': row[0].strip(),
        'nombre': nombre,
        'detalle': row[4].strip(),
        'estado_sige': row[6].strip(),
        'forma_pago': row[7].strip(),
        'monto_cuota': parse_money(row[8]),
        'num_cuotas': row[9].strip(),
        'ingreso_anual': parse_money(row[10]),
        'observacion': row[11].strip(),
    }

print(f'\n📄 SIGE 2026: {len(sige_students)} alumnos cargados')

# ──────────────────────────────────────────────
# 2. Cargar BD: students, enrollments, cursos, enrollment_students
# ──────────────────────────────────────────────
print('🔍 Cargando datos de BD...')
db_students = api_get_all('students', 'id,run,run_numero,first_name,apellido_paterno,apellido_materno,whole_name,curso,estado_std')
db_cursos = api_get_all('cursos', '*')
db_enrollments = api_get_all('enrollments', '*')
db_enroll_students = api_get_all('enrollment_students', '*')
db_fees = api_get_all('fee', '*')

cursos_by_id = {c['id']: c for c in db_cursos}
students_by_id = {s['id']: s for s in db_students}

# Build student lookup by RUT number
db_by_rut = {}
for s in db_students:
    rn = normalize_rut(str(s.get('run_numero') or ''))
    if not rn:
        rn = normalize_rut(str(s.get('run') or ''))
    if rn:
        db_by_rut[rn] = s

# Map enrollment_students: student_id -> list of enrollment_ids
enroll_by_student = {}
for es in db_enroll_students:
    sid = es.get('student_id')
    eid = es.get('enrollment_id')
    if sid:
        enroll_by_student.setdefault(sid, []).append(eid)

# Enrollments by id
enrollments_by_id = {e['id']: e for e in db_enrollments}

# Fees by student
fees_by_student = {}
for f in db_fees:
    sid = f.get('student_id')
    if sid:
        fees_by_student.setdefault(sid, []).append(f)

print(f'📊 BD: {len(db_students)} students | {len(db_enrollments)} enrollments | {len(db_enroll_students)} enrollment_students | {len(db_fees)} fees')

# ──────────────────────────────────────────────
# 3. CRUCE
# ──────────────────────────────────────────────
print('\n' + '=' * 80)
print('RESULTADO DEL CRUCE')
print('=' * 80)

matched = 0
not_in_bd = 0
sin_matricula = 0
con_matricula = 0
discrepancies = []
results = []

for rut, sige in sorted(sige_students.items(), key=lambda x: x[1]['curso_sige']):
    db_st = db_by_rut.get(rut)

    row = {
        'rut': sige['rut_raw'],
        'nombre_sige': sige['nombre'],
        'curso_sige': sige['curso_sige'],
        'estado_sige': sige['estado_sige'],
        'forma_pago_sige': sige['forma_pago'],
        'cuota_sige': sige['monto_cuota'],
        'n_cuotas_sige': sige['num_cuotas'],
        'anual_sige': sige['ingreso_anual'],
        'obs_sige': sige['observacion'],
        # BD fields
        'encontrado_bd': False,
        'nombre_bd': '',
        'curso_bd': '',
        'estado_bd': '',
        'matricula_year': '',
        'matricula_status': '',
        'matricula_folio': '',
        'mat_monto_cuota': '',
        'mat_n_cuotas': '',
        'mat_prioritario': '',
        'mat_forma_pago': '',
        'n_fees': 0,
        'fees_total': 0,
        'fees_paid': 0,
        'discrepancias': [],
    }

    if not db_st:
        not_in_bd += 1
        row['discrepancias'].append('NO_EN_BD')
        results.append(row)
        continue

    matched += 1
    row['encontrado_bd'] = True
    row['nombre_bd'] = db_st.get('whole_name') or (db_st.get('first_name', '') + ' ' + db_st.get('apellido_paterno', ''))
    curso_obj = cursos_by_id.get(db_st.get('curso'), {})
    row['curso_bd'] = curso_obj.get('nom_curso', 'SIN CURSO')
    row['estado_bd'] = db_st.get('estado_std', '?')

    # Find enrollment for this student (prefer 2026)
    student_enroll_ids = enroll_by_student.get(db_st['id'], [])
    best_enrollment = None
    for eid in student_enroll_ids:
        enr = enrollments_by_id.get(eid)
        if enr:
            if enr.get('year') == 2026:
                best_enrollment = enr
                break
            if not best_enrollment or (enr.get('year') or 0) > (best_enrollment.get('year') or 0):
                best_enrollment = enr

    if best_enrollment:
        con_matricula += 1
        meta = best_enrollment.get('meta') or {}
        row['matricula_year'] = best_enrollment.get('year', '')
        row['matricula_status'] = best_enrollment.get('status', '')
        row['matricula_folio'] = meta.get('folio', '')
        row['mat_monto_cuota'] = meta.get('monto_cuota', '')
        row['mat_n_cuotas'] = meta.get('cantidad_cuotas', '')
        row['mat_prioritario'] = meta.get('prioritario', '')
        row['mat_forma_pago'] = meta.get('payment_method', meta.get('forma_pago', ''))
    else:
        sin_matricula += 1
        row['discrepancias'].append('SIN_MATRICULA_2026')

    # Fees
    student_fees = fees_by_student.get(db_st['id'], [])
    row['n_fees'] = len(student_fees)
    row['fees_total'] = sum(float(f.get('amount') or 0) for f in student_fees)
    row['fees_paid'] = sum(1 for f in student_fees if (f.get('status') or '').lower() == 'paid')

    # Discrepancies
    # Curso: SIGE says next year course, BD may still have current year
    # Prioritario mismatch
    sige_prio = sige['forma_pago'].upper() in ('PRIORITARIO',)
    mat_prio = row['mat_prioritario'] is True
    if sige_prio and not mat_prio and best_enrollment:
        row['discrepancias'].append('SIGE_PRIORITARIO_BD_NO')
    if not sige_prio and mat_prio:
        row['discrepancias'].append('BD_PRIORITARIO_SIGE_NO')

    # Monto cuota mismatch
    if best_enrollment and sige['monto_cuota'] > 0 and row['mat_monto_cuota'] not in ('', None):
        mat_mc = int(float(row['mat_monto_cuota']))
        if abs(sige['monto_cuota'] - mat_mc) > 1:
            row['discrepancias'].append(f"MONTO_CUOTA_DIFF(SIGE={sige['monto_cuota']:,} BD={mat_mc:,})")

    # Enrollment status
    if best_enrollment and best_enrollment.get('status') != 'completed':
        row['discrepancias'].append(f"MATRICULA_NO_COMPLETADA({best_enrollment.get('status')})")

    results.append(row)

# ──────────────────────────────────────────────
# 4. Imprimir tabla resumen
# ──────────────────────────────────────────────
print(f'\n{"="*80}')
print(f'TABLA CRUCE: SIGE 2026 vs MATRÍCULAS BD  ({len(results)} alumnos)')
print(f'{"="*80}\n')

# Group by curso SIGE
cursos_order = sorted(set(r['curso_sige'] for r in results))

for curso in cursos_order:
    curso_rows = [r for r in results if r['curso_sige'] == curso]
    print(f'\n┌─ {curso} ({len(curso_rows)} alumnos) ─────────────────────────────────────')

    for r in sorted(curso_rows, key=lambda x: x['nombre_sige']):
        status_icon = '✅' if r['encontrado_bd'] and not r['discrepancias'] else ('❌' if not r['encontrado_bd'] else '⚠️')
        mat_info = ''
        if r['encontrado_bd']:
            if r['matricula_year']:
                mat_info = f"Mat {r['matricula_year']} [{r['matricula_status']}]"
                if r['mat_forma_pago']:
                    mat_info += f" pago={r['mat_forma_pago']}"
                if r['mat_monto_cuota'] not in ('', None, 0):
                    mat_info += f" cuota=${int(float(r['mat_monto_cuota'])):,}"
                if r['mat_n_cuotas']:
                    mat_info += f" x{r['mat_n_cuotas']}"
                if r['mat_prioritario'] is True:
                    mat_info += ' [PRIO]'
            else:
                mat_info = 'SIN MATRÍCULA'

        sige_info = ''
        if r['forma_pago_sige']:
            sige_info = f"pago={r['forma_pago_sige']}"
        if r['cuota_sige']:
            sige_info += f" cuota=${r['cuota_sige']:,}"
        if r['n_cuotas_sige']:
            sige_info += f" x{r['n_cuotas_sige']}"
        if r['anual_sige']:
            sige_info += f" anual=${r['anual_sige']:,}"

        disc = ' | '.join(r['discrepancias']) if r['discrepancias'] else ''

        print(f'  {status_icon} {r["rut"]:<14} {r["nombre_sige"][:40]:<42}')
        print(f'     SIGE:  {sige_info}')
        print(f'     BD:    {mat_info}')
        if disc:
            print(f'     ⚠️  {disc}')

print(f'\n{"="*80}')
print(f'RESUMEN GENERAL')
print(f'{"="*80}')
print(f'  Alumnos en SIGE 2026:       {len(sige_students)}')
print(f'  Encontrados en BD:          {matched}')
print(f'  NO encontrados en BD:       {not_in_bd}')
print(f'  Con matrícula en BD:        {con_matricula}')
print(f'  Sin matrícula en BD:        {sin_matricula}')

# Count discrepancy types
all_disc = [d for r in results for d in r['discrepancias']]
disc_counts = {}
for d in all_disc:
    key = d.split('(')[0]
    disc_counts[key] = disc_counts.get(key, 0) + 1
if disc_counts:
    print(f'\n  Discrepancias:')
    for k, v in sorted(disc_counts.items()):
        print(f'    {k}: {v}')

# Students in BD but NOT in SIGE
bd_ruts = set(db_by_rut.keys())
sige_ruts = set(sige_students.keys())
only_bd = bd_ruts - sige_ruts
# Filter to active students
only_bd_active = [db_by_rut[r] for r in only_bd if db_by_rut[r].get('estado_std', '').upper() in ('ACTIVO', 'MATRICULADO', 'PRE-MATRICULADO', 'PRE_MATRICULADO')]
if only_bd_active:
    print(f'\n  ⚠️  {len(only_bd_active)} alumnos ACTIVOS en BD pero NO en SIGE 2026:')
    for s in sorted(only_bd_active, key=lambda x: x.get('whole_name') or '')[:15]:
        c = cursos_by_id.get(s.get('curso'), {}).get('nom_curso', '?')
        print(f'    RUN={s.get("run","?")} | {s.get("whole_name","?")} | {c} | estado={s.get("estado_std","?")}')
    if len(only_bd_active) > 15:
        print(f'    ... y {len(only_bd_active)-15} más')

print(f'\n{"="*80}')
