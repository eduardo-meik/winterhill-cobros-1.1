#!/usr/bin/env python3
"""
Paso 1: Respaldo de matrículas (enrollments) actuales desde Supabase.
Paso 2: Ajustes basados en cruce con sige_2026.csv.

Genera:
  - backup_matriculas_2026.csv   → copia fiel de las matrículas antes de cambios
  - ajustes_propuestos.csv       → lista de cambios a aplicar con detalle
"""
import os, csv, json, re, requests, datetime
from dotenv import load_dotenv
load_dotenv()

URL  = os.getenv('VITE_SUPABASE_URL')
KEY  = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
HDR  = {'apikey': KEY, 'Authorization': f'Bearer {KEY}'}

# ── Helpers ──────────────────────────────────────────────────────────────────

def api_get(endpoint, params=None):
    r = requests.get(f'{URL}/rest/v1/{endpoint}', headers=HDR, params=params or {})
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

def format_rut_display(rut_str):
    """Return RUT as-is for display."""
    if not rut_str:
        return ''
    return rut_str.replace('\xa0', ' ').strip()

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

def fmt(n):
    """Format number as $xxx,xxx"""
    if n is None or n == 0:
        return '$0'
    return f'${n:,.0f}'.replace(',', '.')

# ── 1. CARGAR DATOS ─────────────────────────────────────────────────────────

print('=' * 80)
print(' RESPALDO Y AJUSTES DE MATRÍCULAS 2026')
print(f' Fecha: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
print('=' * 80)

print('\n[1/4] Cargando datos desde Supabase...')
db_students    = api_get_all('students', 'id,run,run_numero,first_name,apellido_paterno,apellido_materno,whole_name,curso,estado_std')
db_cursos      = api_get_all('cursos', '*')
db_enrollments = api_get_all('enrollments', '*')
db_enroll_stu  = api_get_all('enrollment_students', '*')

print(f'    Students: {len(db_students)} | Cursos: {len(db_cursos)} | Enrollments: {len(db_enrollments)} | Enroll-Students: {len(db_enroll_stu)}')

# Índices
cursos_by_id    = {c['id']: c for c in db_cursos}
students_by_id  = {s['id']: s for s in db_students}
enrollments_by_id = {e['id']: e for e in db_enrollments}

db_by_rut = {}
for s in db_students:
    rn = normalize_rut(str(s.get('run_numero') or ''))
    if not rn:
        rn = normalize_rut(str(s.get('run') or ''))
    if rn:
        db_by_rut[rn] = s

enroll_by_student = {}
for es in db_enroll_stu:
    sid = es.get('student_id')
    eid = es.get('enrollment_id')
    if sid:
        enroll_by_student.setdefault(sid, []).append(eid)

# ── 2. GENERAR BACKUP CSV ───────────────────────────────────────────────────

BACKUP_FILE = 'backup_matriculas_2026.csv'
print(f'\n[2/4] Generando respaldo → {BACKUP_FILE}')

backup_rows = []
for enr in db_enrollments:
    meta = enr.get('meta') or {}
    enr_id = enr['id']

    # Buscar alumno(s) asociado(s)
    associated_students = []
    for es in db_enroll_stu:
        if es.get('enrollment_id') == enr_id:
            sid = es.get('student_id')
            st = students_by_id.get(sid, {})
            associated_students.append(st)

    curso_obj = cursos_by_id.get(enr.get('curso_id'), {})
    curso_nom = curso_obj.get('nom_curso', '')

    # Si no hay alumnos asociados, guardar fila con enrollment solo
    if not associated_students:
        associated_students = [{}]

    for st in associated_students:
        rut = st.get('run', st.get('run_numero', ''))
        rut_num = st.get('run_numero', '')
        whole_name = st.get('whole_name', '')

        backup_rows.append({
            'enrollment_id':    enr_id,
            'student_id':       st.get('id', ''),
            'rut':              rut,
            'rut_numero':       rut_num,
            'nombre_alumno':    whole_name,
            'curso_id':         enr.get('curso_id', ''),
            'curso_nombre':     curso_nom,
            'year':             enr.get('year', ''),
            'status':           enr.get('status', ''),
            'guardian_id':      enr.get('guardian_id', ''),
            'monto_cuota':      meta.get('monto_cuota', ''),
            'cantidad_cuotas':  meta.get('cantidad_cuotas', ''),
            'prioritario':      meta.get('prioritario', ''),
            'payment_method':   meta.get('payment_method', meta.get('forma_pago', '')),
            'folio':            meta.get('folio', ''),
            'meta_completa':    json.dumps(meta, ensure_ascii=False),
            'created_at':       enr.get('created_at', ''),
            'updated_at':       enr.get('updated_at', ''),
        })

# Ordenar por year desc, curso, nombre
backup_rows.sort(key=lambda r: (-(r['year'] or 0), r['curso_nombre'], r['nombre_alumno']))

with open(BACKUP_FILE, 'w', newline='', encoding='utf-8-sig') as f:
    writer = csv.DictWriter(f, fieldnames=list(backup_rows[0].keys()) if backup_rows else [])
    writer.writeheader()
    writer.writerows(backup_rows)

# Contar por año
year_counts = {}
for r in backup_rows:
    y = r['year'] or 'SIN AÑO'
    year_counts[y] = year_counts.get(y, 0) + 1

print(f'    Total filas respaldadas: {len(backup_rows)}')
for y in sorted(year_counts, reverse=True):
    print(f'      Año {y}: {year_counts[y]}')

# ── 3. CARGAR SIGE 2026 ─────────────────────────────────────────────────────

print(f'\n[3/4] Cargando SIGE 2026...')
sige_rows = list(csv.reader(open('sige_2026.csv', encoding='utf-8')))
sige_students = {}
for row in sige_rows[1:]:
    if len(row) < 12:
        row.extend([''] * (12 - len(row)))
    rut_num = normalize_rut(row[2])
    if not rut_num:
        continue
    sige_students[rut_num] = {
        'rut_raw':      row[2].strip(),
        'curso':        row[0].strip(),
        'nombre':       row[3].replace('\xa0', ' ').strip(),
        'forma_pago':   row[7].strip(),
        'monto_cuota':  parse_money(row[8]),
        'num_cuotas':   row[9].strip(),
        'ingreso_anual':parse_money(row[10]),
        'observacion':  row[11].strip(),
    }

print(f'    SIGE alumnos: {len(sige_students)}')

# ── 4. GENERAR PROPUESTAS DE AJUSTE ─────────────────────────────────────────

AJUSTES_FILE = 'ajustes_propuestos.csv'
print(f'\n[4/4] Analizando discrepancias y generando → {AJUSTES_FILE}')

ajustes = []

for rut, sige in sige_students.items():
    db_st = db_by_rut.get(rut)

    # ─── Cat 1: No existe en BD → CREAR ESTUDIANTE ───
    if not db_st:
        ajustes.append({
            'categoria':        '1-CREAR_ESTUDIANTE',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    '',
            'campo':            'students + enrollment',
            'valor_actual_bd':  'NO EXISTE',
            'valor_sige':       sige['nombre'],
            'accion':           f'Crear estudiante y matrícula 2026. Curso: {sige["curso"]}, Monto: {fmt(sige["monto_cuota"])}, F.Pago: {sige["forma_pago"]}',
        })
        continue

    # Buscar mejor enrollment 2026
    student_enroll_ids = enroll_by_student.get(db_st['id'], [])
    best = None
    for eid in student_enroll_ids:
        enr = enrollments_by_id.get(eid)
        if enr and enr.get('year') == 2026:
            best = enr
            break

    curso_obj = cursos_by_id.get(db_st.get('curso'), {})
    curso_bd = curso_obj.get('nom_curso', 'SIN CURSO')

    # ─── Cat 2: Sin matrícula 2026 → CREAR ENROLLMENT ───
    if not best:
        ajustes.append({
            'categoria':        '2-CREAR_MATRICULA',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    '',
            'campo':            'enrollment (year=2026)',
            'valor_actual_bd':  f'Sin matrícula 2026 (curso BD: {curso_bd})',
            'valor_sige':       f'Crear matrícula 2026',
            'accion':           f'Crear enrollment 2026. Monto: {fmt(sige["monto_cuota"])}, Cuotas: {sige["num_cuotas"]}, F.Pago: {sige["forma_pago"]}',
        })
        continue

    meta = best.get('meta') or {}
    mat_monto = int(float(meta.get('monto_cuota', 0) or 0))
    mat_prio  = meta.get('prioritario', False) is True
    mat_pago  = meta.get('payment_method', meta.get('forma_pago', ''))
    sige_prio = sige['forma_pago'].upper() in ('PRIORITARIO',)

    # ─── Cat 3: Matrícula en draft → COMPLETAR ───
    if best.get('status') != 'completed':
        ajustes.append({
            'categoria':        '3-COMPLETAR_MATRICULA',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'status',
            'valor_actual_bd':  best.get('status', ''),
            'valor_sige':       'completed',
            'accion':           f'Cambiar status de "{best.get("status","")}" a "completed"',
        })

    # ─── Cat 4: Monto cuota diferente → ACTUALIZAR MONTO ───
    if sige['monto_cuota'] > 0 and mat_monto != sige['monto_cuota']:
        ajustes.append({
            'categoria':        '4-ACTUALIZAR_MONTO',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'meta.monto_cuota',
            'valor_actual_bd':  fmt(mat_monto),
            'valor_sige':       fmt(sige['monto_cuota']),
            'accion':           f'Actualizar monto de {fmt(mat_monto)} → {fmt(sige["monto_cuota"])}',
        })

    # ─── Cat 4b: Ingreso anual diferente → ACTUALIZAR ───
    sige_anual = sige.get('ingreso_anual', 0)
    mat_anual = int(float(meta.get('ingreso_anual', 0) or 0))
    if sige_anual > 0 and mat_anual != sige_anual:
        ajustes.append({
            'categoria':        '4b-ACTUALIZAR_ANUAL',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'meta.ingreso_anual',
            'valor_actual_bd':  fmt(mat_anual),
            'valor_sige':       fmt(sige_anual),
            'accion':           f'Actualizar ingreso anual de {fmt(mat_anual)} → {fmt(sige_anual)}',
        })

    # ─── Cat 4c: Forma de pago vacía o diferente → ACTUALIZAR ───
    sige_fp = sige['forma_pago'].strip()
    if sige_fp and sige_fp.upper() != 'PRIORITARIO':
        mat_fp_norm = (mat_pago or '').strip().upper()
        sige_fp_norm = sige_fp.upper()
        if mat_fp_norm != sige_fp_norm and not mat_fp_norm:
            ajustes.append({
                'categoria':        '4c-ACTUALIZAR_FORMA_PAGO',
                'rut':              sige['rut_raw'],
                'nombre_sige':      sige['nombre'],
                'curso_sige':       sige['curso'],
                'enrollment_id':    best['id'],
                'campo':            'meta.payment_method',
                'valor_actual_bd':  mat_pago or '(vacío)',
                'valor_sige':       sige_fp,
                'accion':           f'Establecer forma de pago: {sige_fp}',
            })

    # ─── Cat 4d: Cantidad de cuotas → ACTUALIZAR ───
    sige_nc = sige.get('num_cuotas', '').strip()
    mat_nc = str(meta.get('cantidad_cuotas', '')).strip()
    if sige_nc and sige_nc != mat_nc and sige_nc != '0':
        ajustes.append({
            'categoria':        '4d-ACTUALIZAR_CUOTAS',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'meta.cantidad_cuotas',
            'valor_actual_bd':  mat_nc or '(vacío)',
            'valor_sige':       sige_nc,
            'accion':           f'Actualizar cuotas de {mat_nc or "(vacío)"} → {sige_nc}',
        })

    # ─── Cat 5: BD dice prioritario, SIGE no → QUITAR PRIORITARIO ───
    if mat_prio and not sige_prio:
        ajustes.append({
            'categoria':        '5-QUITAR_PRIORITARIO',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'meta.prioritario',
            'valor_actual_bd':  'true',
            'valor_sige':       'false',
            'accion':           f'Quitar prioritario. SIGE F.Pago: {sige_fp or "(vacío)"}',
        })

    # ─── Cat 6: SIGE dice prioritario, BD no → PONER PRIORITARIO ───
    if sige_prio and not mat_prio:
        ajustes.append({
            'categoria':        '6-PONER_PRIORITARIO',
            'rut':              sige['rut_raw'],
            'nombre_sige':      sige['nombre'],
            'curso_sige':       sige['curso'],
            'enrollment_id':    best['id'],
            'campo':            'meta.prioritario',
            'valor_actual_bd':  'false',
            'valor_sige':       'true',
            'accion':           'Marcar como prioritario según SIGE',
        })

# ─── Cat 7: Activos en BD sin presencia en SIGE ───
sige_ruts = set(sige_students.keys())
for rut, st in db_by_rut.items():
    if rut not in sige_ruts and st.get('estado_std') in ('CURSANDO', 'CONFIRMADO', 'ACTIVO'):
        curso_obj = cursos_by_id.get(st.get('curso'), {})
        curso_bd = curso_obj.get('nom_curso', 'SIN CURSO')
        ajustes.append({
            'categoria':        '7-EN_BD_NO_EN_SIGE',
            'rut':              st.get('run', st.get('run_numero', '')),
            'nombre_sige':      st.get('whole_name', ''),
            'curso_sige':       f'(BD: {curso_bd})',
            'enrollment_id':    '',
            'campo':            'estado_std',
            'valor_actual_bd':  st.get('estado_std', ''),
            'valor_sige':       'NO ESTÁ EN SIGE',
            'accion':           'Revisar si debe desactivarse o si falta en SIGE',
        })

# Escribir CSV de ajustes
ajustes.sort(key=lambda r: (r['categoria'], r['nombre_sige']))

with open(AJUSTES_FILE, 'w', newline='', encoding='utf-8-sig') as f:
    cols = ['categoria', 'rut', 'nombre_sige', 'curso_sige', 'enrollment_id', 'campo', 'valor_actual_bd', 'valor_sige', 'accion']
    writer = csv.DictWriter(f, fieldnames=cols)
    writer.writeheader()
    writer.writerows(ajustes)

# ── RESUMEN ──────────────────────────────────────────────────────────────────

cat_counts = {}
for a in ajustes:
    c = a['categoria']
    cat_counts[c] = cat_counts.get(c, 0) + 1

print(f'\n    Total ajustes propuestos: {len(ajustes)}')
print()
print(f'    {"Categoría":<35} {"Cantidad":>8}')
print(f'    {"-"*35} {"-"*8}')
for cat in sorted(cat_counts):
    print(f'    {cat:<35} {cat_counts[cat]:>8}')

print(f'\n{"="*80}')
print(f' Archivos generados:')
print(f'   ✓ {BACKUP_FILE}        (respaldo completo de enrollments)')
print(f'   ✓ {AJUSTES_FILE}       (ajustes propuestos por categoría)')
print(f'{"="*80}')
print(f'\n Revisa {AJUSTES_FILE} antes de aplicar cambios.')
print(f' El respaldo queda en {BACKUP_FILE} para restaurar si es necesario.')
