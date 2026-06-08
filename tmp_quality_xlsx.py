import pandas as pd
import re
from pathlib import Path

path = Path(r"C:/Meik_Apps/winterhill-cobros-1.1/Libro Matrícula Año Escolar 2026 (3).xlsx")
df = pd.read_excel(path, sheet_name='Hoja 4')

C = {
    'student_run': 'RUN ESTUDIANTE',
    'student_address': 'DIRECCIÓN ESTUDIANTE',
    'course_2026': 'CURSO ',
    'guardian_name': '¿CUÁL ES EL NOMBRE DEL APODERADO? ',
    'guardian_last1': '  ¿CUÁL ES EL APELLIDO PATERNO DEL APODERADO?  ',
    'guardian_last2': '  ¿CUÁL ES EL APELLIDO MATERNO DEL APODERADO?  ',
    'guardian_rut': '  ¿CUÁL ES EL RUT DEL APODERADO?  ',
    'guardian_email': '  ¿CUÁL ES EL EMAIL DE CONTACTO DEL APODERADO?  ',
    'guardian_phone': '¿CUÁL ES SU TELÉFONO?',
    'withdraw_date': 'FECHA DE RETIRO',
}

for k,v in list(C.items()):
    if v not in df.columns:
        C[k] = None

def norm_text(x):
    if pd.isna(x):
        return None
    s = str(x).strip()
    return s if s else None

def norm_rut(x):
    s = norm_text(x)
    if not s:
        return None
    return s.upper().replace('.', '').replace(' ', '')

def valid_rut(s):
    if s is None or (isinstance(s, float) and pd.isna(s)):
        return False
    s = str(s).strip().upper()
    return bool(re.fullmatch(r'\d{7,8}-[\dK]', s))

def norm_email(x):
    s = norm_text(x)
    return s.lower() if s else None

def valid_email(s):
    if not s:
        return False
    s = str(s).strip()
    return bool(re.fullmatch(r'[^@\s]+@[^@\s]+\.[^@\s]+', s))

def norm_phone(x):
    s = norm_text(x)
    if not s:
        return None
    d = re.sub(r'\D', '', s)
    return d if d else None

def valid_cl_phone(d):
    if not d:
        return False
    d = str(d)
    return len(d) in (9,11)

sr = df[C['student_run']].map(norm_rut) if C['student_run'] else pd.Series([None]*len(df))
gr = df[C['guardian_rut']].map(norm_rut) if C['guardian_rut'] else pd.Series([None]*len(df))
ge = df[C['guardian_email']].map(norm_email) if C['guardian_email'] else pd.Series([None]*len(df))
gp = df[C['guardian_phone']].map(norm_phone) if C['guardian_phone'] else pd.Series([None]*len(df))
wr = df[C['withdraw_date']] if C['withdraw_date'] else pd.Series([pd.NaT]*len(df))

ready_student = sr.map(valid_rut)
ready_guardian = gr.map(valid_rut)
valid_guard_email = ge.map(valid_email)
valid_guard_phone = gp.map(valid_cl_phone)

student_dup_runs = sr[sr.notna()].value_counts()
student_dup_runs = student_dup_runs[student_dup_runs > 1]

guard_multi = gr[gr.notna()].value_counts()
guard_multi = guard_multi[guard_multi > 1]

conflicts = []
tmp = df.copy()
tmp['_gr'] = gr
tmp['_ge'] = ge
tmp['_gp'] = gp
if C['guardian_name']:
    n = tmp[C['guardian_name']].map(norm_text).fillna('')
    a1 = tmp[C['guardian_last1']].map(norm_text).fillna('') if C['guardian_last1'] else ''
    a2 = tmp[C['guardian_last2']].map(norm_text).fillna('') if C['guardian_last2'] else ''
    tmp['_gn'] = (n + ' ' + a1 + ' ' + a2).str.replace(r'\s+', ' ', regex=True).str.strip().replace('', pd.NA)
else:
    tmp['_gn'] = pd.NA

for rut, g in tmp[tmp['_gr'].notna()].groupby('_gr'):
    email_u = g['_ge'].dropna().nunique()
    phone_u = g['_gp'].dropna().nunique()
    name_u = g['_gn'].dropna().nunique()
    if email_u > 1 or phone_u > 1 or name_u > 1:
        conflicts.append((rut, len(g), int(name_u), int(email_u), int(phone_u)))

withdrawn = int(wr.notna().sum())

print('=== RESUMEN GENERAL ===')
print('Filas totales:', len(df))
print('RUN estudiante no nulo:', int(sr.notna().sum()))
print('RUN estudiante válido:', int(ready_student.sum()))
print('RUT apoderado no nulo:', int(gr.notna().sum()))
print('RUT apoderado válido:', int(ready_guardian.sum()))
print('Email apoderado válido:', int(valid_guard_email.sum()))
print('Teléfono apoderado válido:', int(valid_guard_phone.sum()))
print('Filas retiro (fecha retiro no nula):', withdrawn)

print('\n=== DUPLICADOS ESTUDIANTE (RUN) ===')
print('Cantidad RUN repetidos:', len(student_dup_runs))
if len(student_dup_runs):
    print(student_dup_runs.head(15).to_string())

print('\n=== APODERADOS CON MULTI-ESTUDIANTES (RUT repetido) ===')
print('Cantidad RUT apoderado repetidos:', len(guard_multi))
if len(guard_multi):
    print(guard_multi.head(20).to_string())

print('\n=== CONFLICTOS EN DATOS DE APODERADO POR RUT ===')
print('Cantidad RUT con conflicto:', len(conflicts))
for r in conflicts[:25]:
    print(f'RUT {r[0]} | filas={r[1]} | nombres={r[2]} | emails={r[3]} | telefonos={r[4]}')

missing_student_address = df[sr.notna() & df[C['student_address']].isna()] if C['student_address'] else df.iloc[0:0]
missing_guard_contact = df[gr.notna() & (~valid_guard_email | ~valid_guard_phone)]

print('\n=== CANDIDATOS DE ACTUALIZACION / LIMPIEZA ===')
print('Listos estudiante+apoderado por RUT/RUN válido:', int((ready_student & ready_guardian).sum()))
print('Estudiantes con RUN pero sin dirección:', len(missing_student_address))
print('Apoderados con RUT pero contacto incompleto/invalidado:', len(missing_guard_contact))

cols_show = [c for c in [C['student_run'], C['course_2026'], C['guardian_rut'], C['guardian_name'], C['guardian_last1'], C['guardian_email'], C['guardian_phone']] if c]
print('\nMuestra apoderados con contacto a revisar (max 12):')
if len(missing_guard_contact) > 0:
    print(missing_guard_contact[cols_show].head(12).to_string(index=False))

out_dir = Path('tmp_excel_analysis')
out_dir.mkdir(exist_ok=True)

ready = df[ready_student & ready_guardian].copy()
ready['_student_run'] = sr[ready.index]
ready['_guardian_rut'] = gr[ready.index]
ready.to_csv(out_dir / 'ready_updates_students_guardians.csv', index=False, encoding='utf-8-sig')

if conflicts:
    conflict_ruts = {r[0] for r in conflicts}
    cdf = df[gr.isin(conflict_ruts)].copy()
    cdf['_guardian_rut'] = gr[cdf.index]
    cdf['_guardian_email_norm'] = ge[cdf.index]
    cdf['_guardian_phone_norm'] = gp[cdf.index]
    cdf.to_csv(out_dir / 'guardian_conflicts_by_rut.csv', index=False, encoding='utf-8-sig')

missing_guard_contact.to_csv(out_dir / 'guardian_contact_cleanup.csv', index=False, encoding='utf-8-sig')

print('\nArchivos generados:')
for p in out_dir.glob('*.csv'):
    print('-', p.as_posix())
