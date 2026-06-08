import json
from pathlib import Path

path = Path('sql/backups_pre_limpieza_2026-03-06/students.json')
data = json.loads(path.read_text(encoding='utf-8'))
print('students sample owner_id', data[0].get('owner_id'))
print('students sample run', data[0].get('run'))
path2 = Path('sql/backups_pre_limpieza_2026-03-06/guardians.json')
data2 = json.loads(path2.read_text(encoding='utf-8'))
print('guardians sample owner_id', data2[0].get('owner_id'))
print('guardians sample run', data2[0].get('run'))
