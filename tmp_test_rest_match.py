import json
from pathlib import Path
from urllib import parse, request

# load env
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
headers = {
    'apikey': service_key,
    'Authorization': f'Bearer {service_key}',
    'Accept': 'application/json',
}
for endpoint, run_value in [('students','24.223.389-1'), ('guardians','15.063.027-4')]:
    url = f"{base_url}/rest/v1/{endpoint}?select=run&run=eq.{parse.quote(run_value, safe='.-')}"
    req = request.Request(url, headers=headers, method='GET')
    with request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode('utf-8'))
    print(endpoint, run_value, data[:3], 'count', len(data))
