import pandas as pd
import json
from pathlib import Path

xlsx = Path('Libro Matrícula Año Escolar 2026 (3).xlsx')
df = pd.read_excel(xlsx, sheet_name='Hoja 4')
guard_col = '  ¿CUÁL ES EL RUT DEL APODERADO?  '

def norm_rut(x):
    if pd.isna(x):
        return None
    s = str(x).strip().upper().replace('.', '').replace(' ', '')
    return s if s else None

xg_set = set(df[guard_col].map(norm_rut).dropna())

gjson = Path('sql/backups_pre_limpieza_2026-03-06/guardians.json')
text = gjson.read_text(encoding='utf-8-sig')
data = json.loads(text)
if isinstance(data, dict):
    list_val = None
    for _,v in data.items():
        if isinstance(v, list):
            list_val = v
            break
    if list_val is not None:
        data = list_val

print('guardians json type:', type(data).__name__)
print('rows:', len(data) if isinstance(data,list) else 0)
if isinstance(data,list) and data:
    keys = list(data[0].keys())
    print('sample keys:', keys)
    candidates = [k for k in keys if 'run' in k.lower() or 'rut' in k.lower()]
    print('run/rut keys:', candidates)
    run_key = candidates[0] if candidates else None
    if run_key:
        g_runs = {norm_rut(r.get(run_key)) for r in data if isinstance(r, dict)}
        g_runs = {x for x in g_runs if x}
        print('RUT apoderado en Excel:', len(xg_set))
        print('RUT apoderado en baseline:', len(g_runs))
        print('RUT Excel ya existen en baseline:', len(xg_set & g_runs))
        print('RUT Excel no encontrados en baseline:', len(xg_set - g_runs))
        print('Muestra RUT Excel no encontrados (20):', sorted(list(xg_set - g_runs))[:20])
