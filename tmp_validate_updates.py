import json
from pathlib import Path
from urllib import parse, request

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
checks = [
    ('students', '26.746.827-3', 'select=run,genero,direccion,comuna,repite_curso_actual'),
    ('guardians', '15.063.027-4', 'select=run,first_name,last_name,relationship_type,phone,email'),
]
for endpoint, run_value, select in checks:
    url = f"{base_url}/rest/v1/{endpoint}?{select}&run=eq.{parse.quote(run_value, safe='.-')}"
    req = request.Request(url, headers=headers, method='GET')
    with request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode('utf-8'))
    print('\n', endpoint, run_value)
    print(data)
