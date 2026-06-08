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
queries = ['8° BÁSICO A','4° BÁSICO B','7° BÁSICO A','1° MEDIO B']
for q in queries:
    url = f"{base_url}/rest/v1/cursos?select=id,nom_curso,codigo_curso_matricula,year_academico&nom_curso=ilike.{parse.quote('%'+q+'%', safe='')}&year_academico=eq.2026"
    req = request.Request(url, headers=headers, method='GET')
    with request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode('utf-8'))
    print('\nQUERY', q)
    for row in data:
        print(row)
