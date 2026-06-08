import json
from pathlib import Path
for fname in ['sql/backups_pre_limpieza_2026-03-06/students.json','sql/backups_pre_limpieza_2026-03-06/guardians.json']:
    p = Path(fname)
    data = json.loads(p.read_text(encoding='utf-8-sig'))
    if isinstance(data, dict):
        for _, v in data.items():
            if isinstance(v, list):
                data = v
                break
    print('\n===', fname, '===')
    print('rows', len(data))
    for row in data[:10]:
        keys = [k for k in row.keys() if 'run' in k.lower() or 'rut' in k.lower() or k in ('whole_name','first_name','last_name')]
        print({k: row.get(k) for k in keys})
        break
