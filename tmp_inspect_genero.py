import json
from pathlib import Path

p = Path('sql/backups_pre_limpieza_2026-03-06/students.json')
data = json.loads(p.read_text(encoding='utf-8-sig'))
if isinstance(data, dict):
    for _, v in data.items():
        if isinstance(v, list):
            data = v
            break
vals = {}
for row in data:
    g = row.get('genero')
    vals[g] = vals.get(g, 0) + 1
print(vals)
