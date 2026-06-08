import pandas as pd
import json
import re
from pathlib import Path

xlsx = Path('Libro Matrícula Año Escolar 2026 (3).xlsx')
df = pd.read_excel(xlsx, sheet_name='Hoja 4')
guard_col = '  ¿CUÁL ES EL RUT DEL APODERADO?  '

def canon_rut(x):
    if pd.isna(x):
        return None
    s = re.sub(r'[^0-9kK]', '', str(x)).upper()
    if not s:
        return None
    if len(s) < 8:
        return None
    body, dv = s[:-1], s[-1]
    # drop potential leading zeros in body
    body = body.lstrip('0') or '0'
    return f'{body}-{dv}'

xg = df[guard_col].map(canon_rut).dropna()
x_set = set(xg)

# baseline guardians
j = json.loads(Path('sql/backups_pre_limpieza_2026-03-06/guardians.json').read_text(encoding='utf-8-sig'))
if isinstance(j, dict):
    for _,v in j.items():
        if isinstance(v, list):
            j=v
            break
b_set = {canon_rut(r.get('run')) for r in j if isinstance(r,dict)}
b_set = {x for x in b_set if x}

print('RUT Excel canon únicos:', len(x_set))
print('RUT baseline canon únicos:', len(b_set))
print('Match canon:', len(x_set & b_set))
print('No match canon:', len(x_set - b_set))
print('Muestra no match canon (20):', sorted(list(x_set - b_set))[:20])
