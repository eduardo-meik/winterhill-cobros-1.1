import pandas as pd
from pathlib import Path

path = Path(r"C:/Meik_Apps/winterhill-cobros-1.1/Libro Matrícula Año Escolar 2026 (3).xlsx")
df = pd.read_excel(path, sheet_name='Hoja 4')

cols = {
  'student_run': 'RUN ESTUDIANTE',
  'student_birth': 'FECHA NAC ESTUD',
  'student_gender': 'GÉNERO ESTUDIANTE',
  'student_address': 'DIRECCIÓN ESTUDIANTE',
  'student_comuna': 'COMUNA',
  'student_course': 'CURSO ',
  'student_prev_course': 'CURSO 2025',
  'student_lives_with': '  ¿CON QUIÉN VIVE EL ESTUDIANTE?',
  'student_repeat': '  ¿EL ESTUDIANTE REPITE EL CURSO ACTUAL?  ',
  'student_origin_school': '  ¿CUÁL ES LA INSTITUCIÓN DE PROCEDENCIA DEL ESTUDIANTE?  ',
  'guardian_rut': '  ¿CUÁL ES EL RUT DEL APODERADO?  ',
  'guardian_name': '¿CUÁL ES EL NOMBRE DEL APODERADO? ',
  'guardian_last1': '  ¿CUÁL ES EL APELLIDO PATERNO DEL APODERADO?  ',
  'guardian_last2': '  ¿CUÁL ES EL APELLIDO MATERNO DEL APODERADO?  ',
  'guardian_relation': '¿CUÁL ES SU RELACIÓN CON EL ESTUDIANTE?',
  'guardian_birth': 'FECHA NAC APODERADO',
  'guardian_education': '  ¿CUÁL ES EL NIVEL EDUCACIONAL DEL APODERADO?  ',
  'guardian_address': '  ¿CUÁL ES LA DIRECCIÓN DE RESIDENCIA DEL APODERADO?  ',
  'guardian_comuna': '  ¿CUÁL ES LA COMUNA DE RESIDENCIA DEL APODERADO? ',
  'guardian_email': '  ¿CUÁL ES EL EMAIL DE CONTACTO DEL APODERADO?  ',
  'guardian_phone': '¿CUÁL ES SU TELÉFONO?',
  'sec_name': 'APODERADO SECUNDARIO',
  'sec_relation': 'RELACION CON ESTUDIANTE_APODERADO_SECUNDARIO',
  'sec_rut': 'RUT APODERADO SECUNDARIO',
  'sec_phone': 'AÑADA EL TELÉFONO DEL CONTACTO DISTINTO AL APODERADO SI FUESE EL CASO',
  'sec_email': 'MAIL APODERADO SECUNDARIO',
  'withdraw_date': 'FECHA DE RETIRO',
}

# helper normalizers

def norm(x):
  if pd.isna(x):
    return None
  s = str(x).strip()
  return s if s else None

def norm_rut(x):
  s = norm(x)
  return s.upper().replace('.', '').replace(' ', '') if s else None

def valid_rut(s):
  if not s:
    return False
  import re
  return bool(re.fullmatch(r'\d{7,8}-[\dK]', str(s).upper()))

sr = df[cols['student_run']].map(norm_rut)
gr = df[cols['guardian_rut']].map(norm_rut)
mask_ready = sr.map(valid_rut) & gr.map(valid_rut)
ready = df[mask_ready]

print('TOTAL ready rows:', len(ready))
print('RETIRO dentro de ready:', int(ready[cols['withdraw_date']].notna().sum()))
print('\nCobertura de campos en ready (% no nulo):')
for k,c in cols.items():
  if c in ready.columns:
    pct = (ready[c].notna().sum()/len(ready)*100) if len(ready) else 0
    print(f'{k}: {ready[c].notna().sum()}/{len(ready)} ({pct:.1f}%)')

# Distinct entities
print('\nEntidades distintas en ready:')
print('RUN estudiantes únicos:', ready[cols['student_run']].dropna().astype(str).str.strip().nunique())
print('RUT apoderados únicos:', ready[cols['guardian_rut']].dropna().astype(str).str.strip().nunique())
print('RUT apoderado secundario únicos:', ready[cols['sec_rut']].dropna().astype(str).str.strip().nunique())
