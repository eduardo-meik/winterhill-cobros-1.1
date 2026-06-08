import pandas as pd
from pathlib import Path
import json

results = json.loads(Path('tmp_excel_analysis/lote1_actualizacion/lote1_apply_results.json').read_text(encoding='utf-8'))
miss = set(results['students_missing'])
df = pd.read_csv('tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv')
# load original excel context for course and gender if needed
orig = pd.read_excel('Libro Matrícula Año Escolar 2026 (3).xlsx', sheet_name='Hoja 4')

# normalize excel run
orig['run_norm'] = orig['RUN ESTUDIANTE'].astype(str).str.strip().str.upper().str.replace('.', '', regex=False).str.replace(' ', '', regex=False)
orig['run_fmt'] = orig['run_norm'].str.replace(r'^(\d+)([0-9K])$', lambda m: f"{m.group(1)[:-1] if False else ''}", regex=True)

# helper to canonicalize dotted format from upsert csv run

def canonical(r):
    s = str(r).strip().upper().replace(' ', '').replace('.', '')
    if '-' in s:
        body, dv = s.split('-',1)
    else:
        body, dv = s[:-1], s[-1]
    return f'{int(body)}-{dv}' if body.isdigit() else f'{body}-{dv}'

# build maps from original and csv
orig_map = {}
for _, row in orig.iterrows():
    rn = str(row['RUN ESTUDIANTE']).strip().upper().replace(' ', '').replace('.', '')
    if not rn or rn == 'NAN':
        continue
    if '-' in rn:
        body, dv = rn.split('-',1)
    else:
        body, dv = rn[:-1], rn[-1]
    try:
        key = f"{int(body)}-{dv}"
    except Exception:
        continue
    orig_map[key] = row

print('MISSING LIST')
for run in sorted(miss):
    row = orig_map.get(run)
    if row is None:
        print(run, '| not found in Excel')
    else:
        print(run, '|', row.get('NOMBRE COMPLETO DEL ESTUDIANTE', row.get('nombres', '')), '|', row.get('CURSO ', ''), '| genero=', row.get('GÉNERO ESTUDIANTE', ''), '| comuna=', row.get('COMUNA', ''))
