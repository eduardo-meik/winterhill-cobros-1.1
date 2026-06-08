import pandas as pd
import re
from pathlib import Path

xlsx_path = Path('Libro Matrícula Año Escolar 2026 (3).xlsx')
out_dir = Path('tmp_excel_analysis/lote1_actualizacion')
out_dir.mkdir(parents=True, exist_ok=True)

df = pd.read_excel(xlsx_path, sheet_name='Hoja 4')

COL = {
    'run_student': 'RUN ESTUDIANTE',
    'student_birth': 'FECHA NAC ESTUD',
    'student_gender': 'GÉNERO ESTUDIANTE',
    'student_live_with': '  ¿CON QUIÉN VIVE EL ESTUDIANTE?',
    'student_address': 'DIRECCIÓN ESTUDIANTE',
    'student_comuna': 'COMUNA',
    'student_repeat': '  ¿EL ESTUDIANTE REPITE EL CURSO ACTUAL?  ',
    'student_origin': '  ¿CUÁL ES LA INSTITUCIÓN DE PROCEDENCIA DEL ESTUDIANTE?  ',
    'student_course': 'CURSO ',
    'withdraw_date': 'FECHA DE RETIRO',
    'withdraw_reason': '  MOTIVO DEL RETIRO DEL ESTUDIANTE ',
    'run_guardian': '  ¿CUÁL ES EL RUT DEL APODERADO?  ',
    'guardian_name': '¿CUÁL ES EL NOMBRE DEL APODERADO? ',
    'guardian_last1': '  ¿CUÁL ES EL APELLIDO PATERNO DEL APODERADO?  ',
    'guardian_last2': '  ¿CUÁL ES EL APELLIDO MATERNO DEL APODERADO?  ',
    'guardian_relation': '¿CUÁL ES SU RELACIÓN CON EL ESTUDIANTE?',
    'guardian_birth': 'FECHA NAC APODERADO',
    'guardian_edu': '  ¿CUÁL ES EL NIVEL EDUCACIONAL DEL APODERADO?  ',
    'guardian_address': '  ¿CUÁL ES LA DIRECCIÓN DE RESIDENCIA DEL APODERADO?  ',
    'guardian_comuna': '  ¿CUÁL ES LA COMUNA DE RESIDENCIA DEL APODERADO? ',
    'guardian_email': '  ¿CUÁL ES EL EMAIL DE CONTACTO DEL APODERADO?  ',
    'guardian_phone': '¿CUÁL ES SU TELÉFONO?'
}

for v in COL.values():
    if v not in df.columns:
        raise KeyError(f'No existe columna requerida: {v}')


def norm_text(v):
    if pd.isna(v):
        return None
    s = str(v).strip()
    if not s:
        return None
    return re.sub(r'\s+', ' ', s)


def norm_rut(v):
    s = norm_text(v)
    if not s:
        return None
    raw = re.sub(r'[^0-9kK]', '', s).upper()
    if len(raw) < 8:
        return None
    body, dv = raw[:-1], raw[-1]
    body = body.lstrip('0') or '0'
    return f'{body}-{dv}'


def valid_rut(r):
    if r is None or (isinstance(r, float) and pd.isna(r)):
        return False
    r = str(r).strip().upper()
    return bool(re.fullmatch(r'\d{7,8}-[\dK]', r))


def norm_email(v):
    s = norm_text(v)
    if not s:
        return None
    s = s.replace(' ', '').replace(';', ',').lower()
    for p in [x for x in s.split(',') if x]:
        if re.fullmatch(r'[^@\s]+@[^@\s]+\.[^@\s]+', p):
            return p
    return None


def norm_phone(v):
    s = norm_text(v)
    if not s:
        return None
    d = re.sub(r'\D', '', s)
    if not d:
        return None
    if len(d) == 9 and d.startswith('9'):
        return '+56' + d
    if len(d) == 11 and d.startswith('56'):
        return '+' + d
    if len(d) < 9:
        return None
    return '+' + d


def yes_no_to_bool(v):
    s = (norm_text(v) or '').upper()
    if s in ('SI', 'SÍ', 'YES', 'TRUE'):
        return True
    if s in ('NO', 'FALSE'):
        return False
    return None

w = df.copy()
w['_row'] = range(2, len(w) + 2)
w['_run_student'] = w[COL['run_student']].map(norm_rut)
w['_run_guardian'] = w[COL['run_guardian']].map(norm_rut)
w['_email_guardian'] = w[COL['guardian_email']].map(norm_email)
w['_phone_guardian'] = w[COL['guardian_phone']].map(norm_phone)

conflict_ruts = set()
for rut, g in w[w['_run_guardian'].map(valid_rut)].groupby('_run_guardian'):
    names = (
        g[COL['guardian_name']].map(norm_text).fillna('') + ' ' +
        g[COL['guardian_last1']].map(norm_text).fillna('') + ' ' +
        g[COL['guardian_last2']].map(norm_text).fillna('')
    ).str.strip().str.upper().replace('', pd.NA)
    n_name = names.dropna().nunique()
    n_email = g['_email_guardian'].dropna().nunique()
    n_phone = g['_phone_guardian'].dropna().nunique()
    if n_name > 1 or n_email > 1 or n_phone > 1:
        conflict_ruts.add(rut)

w['_reason_excluded'] = ''
mask_ok = pd.Series(True, index=w.index)

m = w['_run_student'].map(valid_rut)
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|RUN_ESTUDIANTE_INVALIDO'

m = w['_run_guardian'].map(valid_rut)
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|RUT_APODERADO_INVALIDO'

m = w[COL['withdraw_date']].isna()
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|RETIRO'

m = w['_run_guardian'].map(lambda x: x not in conflict_ruts)
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|RUT_APODERADO_CONFLICTIVO'

m = w['_email_guardian'].notna()
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|EMAIL_APODERADO_INVALIDO'

m = w['_phone_guardian'].notna()
mask_ok &= m
w.loc[~m, '_reason_excluded'] += '|TELEFONO_APODERADO_INVALIDO'

safe = w[mask_ok].copy()
excluded = w[~mask_ok].copy()
excluded['_reason_excluded'] = excluded['_reason_excluded'].str.lstrip('|')

safe_students = safe.sort_values('_row').drop_duplicates('_run_student', keep='last').copy()
students_upsert = pd.DataFrame({
    'run': safe_students['_run_student'],
    'date_of_birth': pd.to_datetime(safe_students[COL['student_birth']], errors='coerce').dt.date,
    'genero': safe_students[COL['student_gender']].map(norm_text),
    'direccion': safe_students[COL['student_address']].map(norm_text),
    'comuna': safe_students[COL['student_comuna']].map(norm_text),
    'repite_curso_actual': safe_students[COL['student_repeat']].map(yes_no_to_bool),
    'institucion_procedencia': safe_students[COL['student_origin']].map(norm_text),
    'con_quien_vive': safe_students[COL['student_live_with']].map(norm_text),
    'curso': safe_students[COL['student_course']].map(norm_text),
    'source': 'excel_libro_2026_lote1'
})

guardian_source = safe.sort_values('_row').drop_duplicates('_run_guardian', keep='last').copy()
last_name = (
    guardian_source[COL['guardian_last1']].map(norm_text).fillna('') + ' ' +
    guardian_source[COL['guardian_last2']].map(norm_text).fillna('')
).str.strip().replace('', pd.NA)

guardians_upsert = pd.DataFrame({
    'run': guardian_source['_run_guardian'],
    'first_name': guardian_source[COL['guardian_name']].map(norm_text),
    'last_name': last_name,
    'apellido_paterno': guardian_source[COL['guardian_last1']].map(norm_text),
    'apellido_materno': guardian_source[COL['guardian_last2']].map(norm_text),
    'email': guardian_source['_email_guardian'],
    'phone': guardian_source['_phone_guardian'],
    'address': guardian_source[COL['guardian_address']].map(norm_text),
    'comuna': guardian_source[COL['guardian_comuna']].map(norm_text),
    'date_of_birth': pd.to_datetime(guardian_source[COL['guardian_birth']], errors='coerce').dt.date,
    'nivel_educacional': guardian_source[COL['guardian_edu']].map(norm_text),
    'family_tie': guardian_source[COL['guardian_relation']].map(norm_text),
    'relationship_type': guardian_source[COL['guardian_relation']].map(norm_text),
    'source': 'excel_libro_2026_lote1'
})

guardians_upsert['last_name'] = guardians_upsert['last_name'].fillna(guardians_upsert['apellido_paterno']).fillna('SIN_APELLIDO')

students_path = out_dir / 'lote1_students_upsert.csv'
guardians_path = out_dir / 'lote1_guardians_upsert.csv'
excluded_path = out_dir / 'lote1_excluded_rows.csv'
conflicts_path = out_dir / 'lote1_conflict_guardian_ruts.csv'
summary_path = out_dir / 'lote1_summary.txt'

students_upsert.to_csv(students_path, index=False, encoding='utf-8-sig')
guardians_upsert.to_csv(guardians_path, index=False, encoding='utf-8-sig')
excluded_cols = ['_row', COL['run_student'], COL['run_guardian'], COL['guardian_email'], COL['guardian_phone'], COL['withdraw_date'], '_reason_excluded']
excluded[excluded_cols].to_csv(excluded_path, index=False, encoding='utf-8-sig')
pd.DataFrame({'run_guardian_conflictivo': sorted(conflict_ruts)}).to_csv(conflicts_path, index=False, encoding='utf-8-sig')

summary = [
    'LOTE 1 - ACTUALIZACION SEGURA DESDE EXCEL',
    f'Filas origen: {len(w)}',
    f'Filas aptas (post-filtro): {len(safe)}',
    f'Estudiantes upsert (run unico): {len(students_upsert)}',
    f'Apoderados upsert (run unico): {len(guardians_upsert)}',
    f'Filas excluidas: {len(excluded)}',
    f'RUT apoderado conflictivos: {len(conflict_ruts)}',
    '',
    'Archivos:',
    str(students_path),
    str(guardians_path),
    str(excluded_path),
    str(conflicts_path)
]
summary_path.write_text('\n'.join(summary), encoding='utf-8')
print('\n'.join(summary))
