#!/usr/bin/env python3
"""
Cruce de información: cuotas_importacion.csv vs Base de Datos Supabase.
Compara estudiantes y cuotas del CSV contra los registros en la BD.
"""
import os, csv, json, re, requests
from datetime import datetime
from dotenv import load_dotenv
load_dotenv()

URL = os.getenv('VITE_SUPABASE_URL')
KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
HEADERS = {'apikey': KEY, 'Authorization': f'Bearer {KEY}'}

def supabase_get(endpoint, params=None):
    """GET request to Supabase REST API."""
    r = requests.get(f'{URL}/rest/v1/{endpoint}', headers=HEADERS, params=params or {})
    r.raise_for_status()
    return r.json()

def supabase_get_all(endpoint, select='*', filters=None):
    """GET all rows (handles pagination)."""
    all_data = []
    offset = 0
    limit = 1000
    while True:
        params = {'select': select, 'limit': str(limit), 'offset': str(offset)}
        if filters:
            params.update(filters)
        data = supabase_get(endpoint, params)
        all_data.extend(data)
        if len(data) < limit:
            break
        offset += limit
    return all_data

def parse_money(val):
    """Parse '$99.324' -> 99324"""
    if not val:
        return 0
    val = val.strip().replace('$', '').replace(' ', '')
    # Handle dot as thousands separator (99.324 -> 99324)
    if '.' in val:
        parts = val.split('.')
        if len(parts) == 2 and len(parts[1]) == 3:
            val = val.replace('.', '')
    val = val.replace(',', '')
    try:
        return int(float(val))
    except ValueError:
        return 0

def normalize_run(run_str):
    """Normalize RUN: remove dots, dashes, leading zeros -> '25372029'"""
    if not run_str:
        return ''
    return re.sub(r'[.\-\s]', '', run_str).strip().lstrip('0')

def normalize_curso_csv(curso):
    """Normalize CSV curso name: '3° básico A' -> '3° BASICO A'"""
    return curso.strip().upper().replace('Á','A').replace('É','E').replace('Í','I').replace('Ó','O').replace('Ú','U')

def normalize_curso_db(nom_curso):
    """Normalize DB curso name: '3° BASICO A' -> '3° BASICO A'"""
    if not nom_curso:
        return ''
    return nom_curso.strip().upper().replace('Á','A').replace('É','E').replace('Í','I').replace('Ó','O').replace('Ú','U')

# ──────────────────────────────────────────────
# 1. Load CSV
# ──────────────────────────────────────────────
print('=' * 70)
print('CRUCE DE INFORMACIÓN: CSV vs BASE DE DATOS')
print('=' * 70)

csv_rows = list(csv.DictReader(open('cuotas_importacion.csv', encoding='utf-8-sig')))
print(f'\n📄 CSV: {len(csv_rows)} filas cargadas')

# Group CSV by student (RUN)
csv_students = {}
for row in csv_rows:
    run = row['RUN'].strip()
    if run not in csv_students:
        csv_students[run] = {
            'run': run,
            'nombre': row['NOMBRES'].strip(),
            'apellido_paterno': row['APELLIDO PATERNO'].strip(),
            'apellido_materno': row['APELLIDO MATERNO'].strip(),
            'full_name': row['APELLIDO PATERNO'].strip() + ' ' + row['APELLIDO MATERNO'].strip() + ' ' + row['NOMBRES'].strip(),
            'curso': row['CURSO'].strip(),
            'cuotas': []
        }
    csv_students[run]['cuotas'].append({
        'numero': int(row['CUOTA'].strip()),
        'monto': parse_money(row[' MONTO ']),
        'fecha': row['FECHA'].strip(),
        'estado': row['ESTADO'].strip()
    })

print(f'📄 CSV: {len(csv_students)} estudiantes únicos')
for run, st in csv_students.items():
    total = sum(c['monto'] for c in st['cuotas'])
    print(f"   RUN {run} | {st['full_name']} | {st['curso']} | {len(st['cuotas'])} cuotas | Total: ${total:,.0f}")

# ──────────────────────────────────────────────
# 2. Load DB Students
# ──────────────────────────────────────────────
print(f'\n🔍 Cargando estudiantes desde BD...')
db_students = supabase_get_all('students', 'id,run,run_numero,first_name,apellido_paterno,apellido_materno,whole_name,curso,estado_std')
print(f'📊 BD: {len(db_students)} estudiantes en total')

# Build lookup by normalized RUN number
db_by_run = {}
for s in db_students:
    run_num = normalize_run(str(s.get('run_numero') or ''))
    if not run_num:
        # Try extracting from formatted RUN (e.g., '25.372.029-K')
        run_num = normalize_run(str(s.get('run') or ''))
        # Remove verificador digit if present
        if run_num and '-' not in str(s.get('run') or ''):
            pass  # Already clean
        else:
            run_num = run_num.split('-')[0] if run_num else ''
            run_num = re.sub(r'[^0-9]', '', run_num)
    if run_num:
        db_by_run[run_num] = s

# ──────────────────────────────────────────────
# 3. Load DB Cursos
# ──────────────────────────────────────────────
db_cursos = supabase_get_all('cursos', '*')
cursos_by_id = {c['id']: c for c in db_cursos}
print(f'📊 BD: {len(db_cursos)} cursos')

# ──────────────────────────────────────────────
# 4. Load DB Fees
# ──────────────────────────────────────────────
print(f'🔍 Cargando fees desde BD...')
db_fees = supabase_get_all('fee', '*')
print(f'📊 BD: {len(db_fees)} fees en total')

# Group fees by student_id
fees_by_student = {}
for fee in db_fees:
    sid = fee.get('student_id')
    if sid:
        if sid not in fees_by_student:
            fees_by_student[sid] = []
        fees_by_student[sid].append(fee)

# ──────────────────────────────────────────────
# 5. CRUCE - Match CSV students to DB
# ──────────────────────────────────────────────
print('\n' + '=' * 70)
print('RESULTADO DEL CRUCE')
print('=' * 70)

matched = 0
not_found = 0
discrepancies = []
matches_detail = []

for csv_run, csv_st in csv_students.items():
    run_clean = normalize_run(csv_run)
    db_st = db_by_run.get(run_clean)
    
    if not db_st:
        not_found += 1
        print(f'\n❌ NO ENCONTRADO EN BD: RUN {csv_run} | {csv_st["full_name"]}')
        discrepancies.append({
            'tipo': 'ESTUDIANTE_NO_ENCONTRADO',
            'csv_run': csv_run,
            'csv_nombre': csv_st['full_name'],
            'csv_curso': csv_st['curso']
        })
        continue
    
    matched += 1
    db_curso = cursos_by_id.get(db_st.get('curso'), {})
    db_curso_name = db_curso.get('nom_curso', 'SIN CURSO')
    
    print(f'\n✅ MATCH: RUN {csv_run}')
    print(f'   CSV: {csv_st["full_name"]} | {csv_st["curso"]}')
    print(f'   BD:  {db_st.get("whole_name") or (db_st.get("first_name","") + " " + db_st.get("apellido_paterno",""))} | {db_curso_name} | Estado: {db_st.get("estado_std", "?")}')
    
    # Check curso mismatch
    csv_curso_norm = normalize_curso_csv(csv_st['curso'])
    db_curso_norm = normalize_curso_db(db_curso_name)
    if csv_curso_norm != db_curso_norm:
        # Try partial match (ignoring letter)
        csv_base = re.sub(r'\s+[A-Z]$', '', csv_curso_norm)
        db_base = re.sub(r'\s+[A-Z]$', '', db_curso_norm)
        if csv_base != db_base:
            print(f'   ⚠️  CURSO DIFERENTE: CSV="{csv_st["curso"]}" vs BD="{db_curso_name}"')
            discrepancies.append({
                'tipo': 'CURSO_DIFERENTE',
                'run': csv_run,
                'nombre': csv_st['full_name'],
                'csv_curso': csv_st['curso'],
                'bd_curso': db_curso_name
            })
    
    # Compare cuotas
    student_fees = fees_by_student.get(db_st['id'], [])
    
    if not student_fees:
        print(f'   ⚠️  SIN FEES EN BD para este estudiante')
        discrepancies.append({
            'tipo': 'SIN_FEES_EN_BD',
            'run': csv_run,
            'nombre': csv_st['full_name'],
            'csv_cuotas': len(csv_st['cuotas'])
        })
    else:
        print(f'   📊 Fees en BD: {len(student_fees)} | Cuotas en CSV: {len(csv_st["cuotas"])}')
        
        # Build fee lookup by numero_cuota
        db_fee_by_cuota = {}
        for f in student_fees:
            nc = f.get('numero_cuota')
            if nc is not None:
                nc = int(nc)
                if nc not in db_fee_by_cuota:
                    db_fee_by_cuota[nc] = f
        
        for csv_cuota in csv_st['cuotas']:
            num = csv_cuota['numero']
            db_fee = db_fee_by_cuota.get(num)
            
            if not db_fee:
                print(f'   ⚠️  Cuota {num}: en CSV pero NO en BD')
                discrepancies.append({
                    'tipo': 'CUOTA_NO_EN_BD',
                    'run': csv_run,
                    'nombre': csv_st['full_name'],
                    'cuota': num,
                    'csv_monto': csv_cuota['monto'],
                    'csv_estado': csv_cuota['estado']
                })
                continue
            
            # Compare amounts
            db_amount = int(float(db_fee.get('amount', 0)))
            csv_amount = csv_cuota['monto']
            
            if abs(db_amount - csv_amount) > 1:  # Allow $1 rounding
                print(f'   ⚠️  Cuota {num}: MONTO DIFERENTE CSV=${csv_amount:,.0f} vs BD=${db_amount:,.0f} (diff=${abs(db_amount-csv_amount):,.0f})')
                discrepancies.append({
                    'tipo': 'MONTO_DIFERENTE',
                    'run': csv_run,
                    'nombre': csv_st['full_name'],
                    'cuota': num,
                    'csv_monto': csv_amount,
                    'bd_monto': db_amount,
                    'diferencia': abs(db_amount - csv_amount)
                })
            
            # Compare status
            csv_estado = csv_cuota['estado'].upper()
            db_status = (db_fee.get('status') or '').upper()
            
            # Map statuses
            status_map = {
                'PAGADO': 'PAID',
                'PENDIENTE': 'PENDING',
                'VENCIDO': 'OVERDUE',
                'OVERDUE': 'OVERDUE',
                'PAID': 'PAID',
                'PENDING': 'PENDING'
            }
            csv_status_norm = status_map.get(csv_estado, csv_estado)
            db_status_norm = status_map.get(db_status, db_status)
            
            if csv_status_norm != db_status_norm:
                print(f'   ⚠️  Cuota {num}: ESTADO DIFERENTE CSV="{csv_cuota["estado"]}" vs BD="{db_fee.get("status")}"')
                discrepancies.append({
                    'tipo': 'ESTADO_DIFERENTE',
                    'run': csv_run,
                    'nombre': csv_st['full_name'],
                    'cuota': num,
                    'csv_estado': csv_cuota['estado'],
                    'bd_estado': db_fee.get('status')
                })
            
            # Match detail
            match_info = {
                'run': csv_run,
                'nombre': csv_st['full_name'],
                'cuota': num,
                'csv_monto': csv_amount,
                'bd_monto': db_amount,
                'csv_estado': csv_cuota['estado'],
                'bd_estado': db_fee.get('status'),
                'bd_due_date': db_fee.get('due_date'),
                'bd_payment_date': db_fee.get('payment_date'),
                'monto_ok': abs(db_amount - csv_amount) <= 1,
                'estado_ok': csv_status_norm == db_status_norm
            }
            matches_detail.append(match_info)
        
        # Check for fees in DB not in CSV
        csv_cuota_nums = set(c['numero'] for c in csv_st['cuotas'])
        for db_num, db_fee in db_fee_by_cuota.items():
            if db_num not in csv_cuota_nums:
                print(f'   ℹ️  Cuota {db_num}: en BD pero NO en CSV (monto=${int(float(db_fee.get("amount",0))):,} estado={db_fee.get("status")})')

# ──────────────────────────────────────────────
# 6. RESUMEN
# ──────────────────────────────────────────────
print('\n' + '=' * 70)
print('RESUMEN DEL CRUCE')
print('=' * 70)

print(f'\nEstudiantes en CSV: {len(csv_students)}')
print(f'  ✅ Encontrados en BD: {matched}')
print(f'  ❌ No encontrados en BD: {not_found}')

total_cuotas_csv = sum(len(st['cuotas']) for st in csv_students.values())
cuotas_ok = sum(1 for m in matches_detail if m['monto_ok'] and m['estado_ok'])
cuotas_monto_diff = sum(1 for m in matches_detail if not m['monto_ok'])
cuotas_estado_diff = sum(1 for m in matches_detail if not m['estado_ok'])

print(f'\nCuotas en CSV: {total_cuotas_csv}')
print(f'  ✅ Coinciden completamente: {cuotas_ok}')
print(f'  ⚠️  Monto diferente: {cuotas_monto_diff}')
print(f'  ⚠️  Estado diferente: {cuotas_estado_diff}')

# Money totals
total_csv = sum(c['monto'] for st in csv_students.values() for c in st['cuotas'])
total_bd_matched = sum(m['bd_monto'] for m in matches_detail)
print(f'\nMontos totales:')
print(f'  CSV: ${total_csv:,.0f}')
print(f'  BD (cuotas cruzadas): ${total_bd_matched:,.0f}')
print(f'  Diferencia: ${abs(total_csv - total_bd_matched):,.0f}')

if discrepancies:
    print(f'\n⚠️  TOTAL DISCREPANCIAS: {len(discrepancies)}')
    by_type = {}
    for d in discrepancies:
        t = d['tipo']
        by_type[t] = by_type.get(t, 0) + 1
    for t, c in sorted(by_type.items()):
        print(f'   {t}: {c}')
else:
    print(f'\n✅ SIN DISCREPANCIAS - Todos los datos coinciden')

print('\n' + '=' * 70)
