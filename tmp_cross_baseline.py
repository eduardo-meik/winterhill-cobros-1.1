import pandas as pd
import json
import re
from pathlib import Path

xlsx = Path('Libro Matrícula Año Escolar 2026 (3).xlsx')
df = pd.read_excel(xlsx, sheet_name='Hoja 4')

student_col = 'RUN ESTUDIANTE'
guard_col = '  ¿CUÁL ES EL RUT DEL APODERADO?  '


def norm_rut(x):
    if pd.isna(x):
        return None
    s = str(x).strip().upper().replace('.', '').replace(' ', '')
    return s if s else None

x_runs = df[student_col].map(norm_rut).dropna()
x_guard = df[guard_col].map(norm_rut).dropna()

# compare students table extract
s_csv = Path('students_only_extract.csv')
sdf = pd.read_csv(s_csv)
cur_runs = sdf['run'].map(norm_rut).dropna() if 'run' in sdf.columns else pd.Series([], dtype=str)

x_set = set(x_runs)
cur_set = set(cur_runs)

print('=== CRUCE ESTUDIANTES CON students_only_extract.csv ===')
print('RUN en Excel:', len(x_set))
print('RUN en extract actual:', len(cur_set))
print('RUN Excel ya existen en extract:', len(x_set & cur_set))
print('RUN Excel no encontrados en extract:', len(x_set - cur_set))
print('RUN extract no están en Excel:', len(cur_set - x_set))

# show sample missing in extract
missing = sorted(list(x_set - cur_set))[:20]
print('Muestra RUN Excel no encontrados (20):', missing)

# try guardians baseline json
gjson = Path('sql/backups_pre_limpieza_2026-03-06/guardians.json')
if gjson.exists():
    data = json.loads(gjson.read_text(encoding='utf-8'))
    if isinstance(data, dict):
        # some exports wrap under key
        for k,v in data.items():
            if isinstance(v, list):
                data = v
                break
    if isinstance(data, list) and data:
        # heuristic run keys
        keys = list(data[0].keys())
        run_key = None
        for k in keys:
            lk = k.lower()
            if lk in ('run','rut','run_apoderado','guardian_run','guardian_rut') or 'run' in lk or 'rut' in lk:
                run_key = k
                break
        print('\n=== GUARDIANS BASELINE JSON ===')
        print('rows:', len(data))
        print('detected run key:', run_key)
        if run_key:
            g_runs = {norm_rut(r.get(run_key)) for r in data if isinstance(r, dict)}
            g_runs = {x for x in g_runs if x}
            xg_set = set(x_guard)
            print('RUT apoderado en Excel:', len(xg_set))
            print('RUT apoderado en baseline:', len(g_runs))
            print('RUT Excel ya existen en baseline:', len(xg_set & g_runs))
            print('RUT Excel no encontrados en baseline:', len(xg_set - g_runs))
            print('Muestra RUT Excel no encontrados (20):', sorted(list(xg_set - g_runs))[:20])
    else:
        print('\nNo se pudo interpretar guardians.json como lista de objetos')
else:
    print('\nNo existe guardians.json para cruce de apoderados')
