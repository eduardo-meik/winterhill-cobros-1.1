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
runs = ['19.152.079-3','25.458.455-K','24.257.000-6','25.131.769-0','24.557.181-K','23.886.325-1']
for run_value in runs:
    url = f"{base_url}/rest/v1/students?select=run&run=eq.{parse.quote(run_value, safe='.-')}"
    req = request.Request(url, headers=headers, method='GET')
    with request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode('utf-8'))
    print(run_value, 'count', len(data))
