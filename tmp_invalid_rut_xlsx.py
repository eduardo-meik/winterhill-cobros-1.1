import pandas as pd
import re
from pathlib import Path

path = Path(r"C:/Meik_Apps/winterhill-cobros-1.1/Libro Matrícula Año Escolar 2026 (3).xlsx")
df = pd.read_excel(path, sheet_name='Hoja 4')

c_run='RUN ESTUDIANTE'
c_gr='  ¿CUÁL ES EL RUT DEL APODERADO?  '
c_name='NOMBRE COMPLETO DEL ESTUDIANTE' if 'NOMBRE COMPLETO DEL ESTUDIANTE' in df.columns else None


def norm(x):
    if pd.isna(x):
        return None
    s=str(x).strip()
    return s if s else None

def norm_rut(x):
    s=norm(x)
    return s.upper().replace('.','').replace(' ','') if s else None

def is_valid(s):
    return bool(s and re.fullmatch(r'\d{7,8}-[\dK]', str(s).upper()))

sr=df[c_run].map(norm_rut)
gr=df[c_gr].map(norm_rut)

bad_sr=df[sr.notna() & ~sr.map(is_valid)].copy()
bad_sr['_run_norm']=sr[bad_sr.index]

bad_gr=df[gr.notna() & ~gr.map(is_valid)].copy()
bad_gr['_rut_norm']=gr[bad_gr.index]

print('invalid student RUN rows:', len(bad_sr))
if len(bad_sr):
    cols=[c for c in [c_run,'CURSO ',c_name,c_gr] if c and c in bad_sr.columns]
    cols.append('_run_norm')
    print(bad_sr[cols].head(20).to_string(index=False))

print('\ninvalid guardian RUT rows:', len(bad_gr))
if len(bad_gr):
    cols=[c for c in [c_run,'CURSO ',c_gr,'¿CUÁL ES EL NOMBRE DEL APODERADO? ','  ¿CUÁL ES EL APELLIDO PATERNO DEL APODERADO?  '] if c in bad_gr.columns]
    cols.append('_rut_norm')
    print(bad_gr[cols].head(30).to_string(index=False))
