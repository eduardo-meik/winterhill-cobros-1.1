import json
from pathlib import Path
from urllib import parse, request

path = Path('sql/backups_pre_limpieza_2026-03-06/students.json')
data = json.loads(path.read_text(encoding='utf-8-sig'))
print('students sample owner_id', data[0].get('owner_id'))
print('students sample run', data[0].get('run'))
path2 = Path('sql/backups_pre_limpieza_2026-03-06/guardians.json')
data2 = json.loads(path2.read_text(encoding='utf-8-sig'))
print('guardians sample owner_id', data2[0].get('owner_id'))
print('guardians sample run', data2[0].get('run'))

env = {}
for env_path in [Path('.env'), Path('.env.local')]:
    if env_path.exists():
        for line in env_path.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
base_url = env['VITE_SUPABASE_URL'].rstrip('/')
service_key = env['SUPABASE_SERVICE_ROLE_KEY']
headers = {'apikey': service_key, 'Authorization': f'Bearer {service_key}', 'Accept': 'application/json'}
runs = ['19152079-3','10989462-1','12846829-3','24255274-1','24408543-1','15215716-9','17201918-8','17031575-8','16877043-K','18705495-8','9782305-2','7732546-8']
for run_value in runs:
    for table in ['students', 'guardians']:
        url = f"{base_url}/rest/v1/{table}?select=run,owner_id&run=eq.{parse.quote(run_value, safe='.-')}"
        req = request.Request(url, headers=headers, method='GET')
        with request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read().decode('utf-8'))
        if data:
            print('exists', table, run_value, data[0]['owner_id'])
