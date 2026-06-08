import pandas as pd
from pathlib import Path

missing = ['19.152.079-3','25.458.455-K','24.257.000-6','25.131.769-0','24.557.181-K','23.886.325-1']

def canon(x):
    if pd.isna(x):
        return None
    s = str(x).strip().upper().replace('.','').replace(' ','')
    if not s:
        return None
    if '-' in s:
        body, dv = s.split('-',1)
    else:
        body, dv = s[:-1], s[-1]
    if not body:
        return None
    try:
        body_int = str(int(body))
    except Exception:
        body_int = body
    return f"{body_int}-{dv}"

xl = pd.read_excel(Path('Libro Matrícula Año Escolar 2026 (3).xlsx'), sheet_name='Hoja 4')
xl['run_canon'] = xl['RUN ESTUDIANTE'].map(canon)
cols = ['RUN ESTUDIANTE','CURSO ','GÉNERO ESTUDIANTE','DIRECCIÓN ESTUDIANTE','COMUNA']
for r in missing:
    row = xl[xl['run_canon'] == r]
    print('\nRUN', r)
    if row.empty:
        print('no encontrado en Excel')
    else:
        print(row[cols].head(1).to_string(index=False))
