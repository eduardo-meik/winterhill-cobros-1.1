#!/usr/bin/env python3
"""
Detalle de discrepancias: SIGE 2026 vs Matrículas (enrollments) en Supabase.
Muestra los registros específicos de cada tipo de discrepancia.
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

# ── Cargar datos ──
print('Cargando datos...')
sige_rows = list(csv.reader(open('sige_2026.csv', encoding='utf-8')))
sige_students = {}
for row in sige_rows[1:]:
    if len(row) < 12:
        row.extend([''] * (12 - len(row)))
    rut_num = normalize_rut(row[2])
    if not rut_num:
        continue
    sige_students[rut_num] = {
        'rut_raw': row[2].strip(),
        'curso': row[0].strip(),
        'nombre': row[3].replace('\xa0', ' ').strip(),
        'detalle': row[4].strip(),
        'estado': row[6].strip(),
        'forma_pago': row[7].strip(),
        'monto_cuota': parse_money(row[8]),
        'num_cuotas': row[9].strip(),
        'ingreso_anual': parse_money(row[10]),
        'observacion': row[11].strip(),
    }

db_students = api_get_all('students', 'id,run,run_numero,first_name,apellido_paterno,apellido_materno,whole_name,curso,estado_std')
db_cursos = api_get_all('cursos', '*')
db_enrollments = api_get_all('enrollments', '*')
db_enroll_students = api_get_all('enrollment_students', '*')

cursos_by_id = {c['id']: c for c in db_cursos}
students_by_id = {s['id']: s for s in db_students}

db_by_rut = {}
for s in db_students:
    rn = normalize_rut(str(s.get('run_numero') or ''))
    if not rn:
        rn = normalize_rut(str(s.get('run') or ''))
    if rn:
        db_by_rut[rn] = s

enroll_by_student = {}
for es in db_enroll_students:
    sid = es.get('student_id')
    eid = es.get('enrollment_id')
    if sid:
        enroll_by_student.setdefault(sid, []).append(eid)

enrollments_by_id = {e['id']: e for e in db_enrollments}

print(f'SIGE: {len(sige_students)} | BD students: {len(db_students)} | Enrollments: {len(db_enrollments)}')

# ── Clasificar discrepancias ──
cat_no_en_bd = []          # 1. NO_EN_BD
cat_sin_matricula = []     # 2. SIN_MATRICULA_2026
cat_mat_no_completada = [] # 3. MATRICULA_NO_COMPLETADA
cat_monto_diff = []        # 4. MONTO_CUOTA_DIFF
cat_bd_prio_sige_no = []   # 5. BD_PRIORITARIO_SIGE_NO
cat_sige_prio_bd_no = []   # 6. SIGE_PRIORITARIO_BD_NO
cat_bd_no_en_sige = []     # 7. Activos en BD no en SIGE

for rut, sige in sige_students.items():
    db_st = db_by_rut.get(rut)

    if not db_st:
        cat_no_en_bd.append(sige)
        continue

    curso_obj = cursos_by_id.get(db_st.get('curso'), {})
    curso_bd = curso_obj.get('nom_curso', 'SIN CURSO')

    # Find best enrollment
    student_enroll_ids = enroll_by_student.get(db_st['id'], [])
    best = None
    for eid in student_enroll_ids:
        enr = enrollments_by_id.get(eid)
        if enr:
            if enr.get('year') == 2026:
                best = enr
                break
            if not best or (enr.get('year') or 0) > (best.get('year') or 0):
                best = enr

    if not best or best.get('year') != 2026:
        cat_sin_matricula.append({**sige, 'bd_nombre': db_st.get('whole_name',''), 'curso_bd': curso_bd, 'estado_bd': db_st.get('estado_std','')})
        continue

    meta = best.get('meta') or {}
    mat_monto = meta.get('monto_cuota', 0)
    mat_n_cuotas = meta.get('cantidad_cuotas', '')
    mat_prio = meta.get('prioritario', False) is True
    mat_pago = meta.get('payment_method', meta.get('forma_pago', ''))
    sige_prio = sige['forma_pago'].upper() in ('PRIORITARIO',)

    rec = {
        **sige,
        'bd_nombre': db_st.get('whole_name',''),
        'curso_bd': curso_bd,
        'estado_bd': db_st.get('estado_std',''),
        'mat_status': best.get('status',''),
        'mat_folio': meta.get('folio',''),
        'mat_monto': int(float(mat_monto)) if mat_monto else 0,
        'mat_n_cuotas': mat_n_cuotas,
        'mat_prio': mat_prio,
        'mat_pago': mat_pago,
    }

    if best.get('status') != 'completed':
        cat_mat_no_completada.append(rec)

    if sige['monto_cuota'] > 0 and mat_monto not in ('', None):
        mat_mc = int(float(mat_monto))
        if abs(sige['monto_cuota'] - mat_mc) > 1:
            rec['diff'] = sige['monto_cuota'] - mat_mc
            cat_monto_diff.append(rec)

    if sige_prio and not mat_prio:
        cat_sige_prio_bd_no.append(rec)
    if not sige_prio and mat_prio:
        cat_bd_prio_sige_no.append(rec)

# Activos en BD no en SIGE
bd_ruts = set(db_by_rut.keys())
sige_ruts = set(sige_students.keys())
for rut in sorted(bd_ruts - sige_ruts):
    s = db_by_rut[rut]
    if s.get('estado_std', '').upper() in ('ACTIVO', 'MATRICULADO', 'PRE-MATRICULADO', 'PRE_MATRICULADO'):
        c = cursos_by_id.get(s.get('curso'), {}).get('nom_curso', '?')
        cat_bd_no_en_sige.append({'rut': s.get('run',''), 'nombre': s.get('whole_name',''), 'curso_bd': c, 'estado_bd': s.get('estado_std','')})

# ── Imprimir detalle por categoría ──
def hdr(title, count):
    print(f'\n{"="*80}')
    print(f' {title} ({count} registros)')
    print(f'{"="*80}')

# ─────────────────────────────────────────
hdr('1. NO ENCONTRADOS EN BD', len(cat_no_en_bd))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<45} {"Curso SIGE":<18} {"F.Pago":<15} {"Cuota":<12} {"Anual":<12}')
print('-'*120)
for i, r in enumerate(sorted(cat_no_en_bd, key=lambda x: x['curso']), 1):
    mc = f"${r['monto_cuota']:,}" if r['monto_cuota'] else '-'
    an = f"${r['ingreso_anual']:,}" if r['ingreso_anual'] else '-'
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:44]:<45} {r["curso"]:<18} {r["forma_pago"]:<15} {mc:<12} {an:<12}')

# ─────────────────────────────────────────
hdr('2. SIN MATRÍCULA 2026 EN BD (existen en BD pero sin enrollment 2026)', len(cat_sin_matricula))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<40} {"Curso SIGE":<16} {"Curso BD":<16} {"Estado BD":<12} {"F.Pago SIGE":<15} {"Cuota SIGE":<12}')
print('-'*130)
for i, r in enumerate(sorted(cat_sin_matricula, key=lambda x: x['curso']), 1):
    mc = f"${r['monto_cuota']:,}" if r['monto_cuota'] else '-'
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:39]:<40} {r["curso"]:<16} {r["curso_bd"]:<16} {r["estado_bd"]:<12} {r["forma_pago"]:<15} {mc:<12}')

# ─────────────────────────────────────────
hdr('3. MATRÍCULA NO COMPLETADA (estado draft u otro != completed)', len(cat_mat_no_completada))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<40} {"Curso SIGE":<16} {"Estado Mat":<12} {"Folio":<20} {"F.Pago SIGE":<15} {"Prio?":<6}')
print('-'*130)
for i, r in enumerate(sorted(cat_mat_no_completada, key=lambda x: x['curso']), 1):
    prio = 'SÍ' if r.get('mat_prio') else 'NO'
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:39]:<40} {r["curso"]:<16} {r["mat_status"]:<12} {r["mat_folio"]:<20} {r["forma_pago"]:<15} {prio:<6}')

# ─────────────────────────────────────────
hdr('4. MONTO CUOTA DIFERENTE (SIGE vs BD)', len(cat_monto_diff))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<40} {"Curso SIGE":<16} {"Cuota SIGE":<14} {"Cuota BD":<14} {"Diferencia":<14} {"Anual SIGE":<14} {"F.Pago":<12}')
print('-'*145)
for i, r in enumerate(sorted(cat_monto_diff, key=lambda x: x['curso']), 1):
    cs = f"${r['monto_cuota']:,}"
    cb = f"${r['mat_monto']:,}"
    df = f"${r['diff']:,}"
    an = f"${r['ingreso_anual']:,}" if r['ingreso_anual'] else '-'
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:39]:<40} {r["curso"]:<16} {cs:<14} {cb:<14} {df:<14} {an:<14} {r["forma_pago"]:<12}')

# ─────────────────────────────────────────
hdr('5. BD DICE PRIORITARIO, SIGE NO', len(cat_bd_prio_sige_no))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<40} {"Curso SIGE":<16} {"F.Pago SIGE":<15} {"Cuota SIGE":<14} {"Mat Prio BD":<12}')
print('-'*120)
for i, r in enumerate(sorted(cat_bd_prio_sige_no, key=lambda x: x['curso']), 1):
    mc = f"${r['monto_cuota']:,}" if r['monto_cuota'] else '-'
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:39]:<40} {r["curso"]:<16} {r["forma_pago"]:<15} {mc:<14} {"SÍ":<12}')

# ─────────────────────────────────────────
hdr('6. SIGE DICE PRIORITARIO, BD NO', len(cat_sige_prio_bd_no))
print(f'{"N°":<4} {"RUT":<16} {"Nombre SIGE":<40} {"Curso SIGE":<16} {"F.Pago SIGE":<15} {"Mat Prio BD":<12} {"Mat F.Pago BD":<15}')
print('-'*120)
for i, r in enumerate(sorted(cat_sige_prio_bd_no, key=lambda x: x['curso']), 1):
    print(f'{i:<4} {r["rut_raw"]:<16} {r["nombre"][:39]:<40} {r["curso"]:<16} {r["forma_pago"]:<15} {"NO":<12} {r["mat_pago"]:<15}')

# ─────────────────────────────────────────
hdr('7. ALUMNOS ACTIVOS EN BD QUE NO ESTÁN EN SIGE 2026', len(cat_bd_no_en_sige))
print(f'{"N°":<4} {"RUT":<18} {"Nombre BD":<45} {"Curso BD":<18} {"Estado BD":<12}')
print('-'*100)
for i, r in enumerate(sorted(cat_bd_no_en_sige, key=lambda x: x['curso_bd']), 1):
    print(f'{i:<4} {r["rut"]:<18} {r["nombre"][:44]:<45} {r["curso_bd"]:<18} {r["estado_bd"]:<12}')

# ── Resumen final ──
print(f'\n{"="*80}')
print('RESUMEN DE DISCREPANCIAS')
print(f'{"="*80}')
print(f'  1. No encontrados en BD:           {len(cat_no_en_bd):>4}')
print(f'  2. Sin matrícula 2026:             {len(cat_sin_matricula):>4}')
print(f'  3. Matrícula no completada:        {len(cat_mat_no_completada):>4}')
print(f'  4. Monto cuota diferente:          {len(cat_monto_diff):>4}')
print(f'  5. BD prioritario, SIGE no:        {len(cat_bd_prio_sige_no):>4}')
print(f'  6. SIGE prioritario, BD no:        {len(cat_sige_prio_bd_no):>4}')
print(f'  7. Activos en BD no en SIGE:       {len(cat_bd_no_en_sige):>4}')
print(f'{"="*80}')
