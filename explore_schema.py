#!/usr/bin/env python3
"""Explore Supabase schema using service role key."""
import os, requests, json
from dotenv import load_dotenv
load_dotenv()

url = os.getenv('VITE_SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
headers = {'apikey': key, 'Authorization': f'Bearer {key}'}

# Students
r = requests.get(f'{url}/rest/v1/students?select=*&limit=2', headers=headers)
print('STUDENTS status:', r.status_code, 'count:', len(r.json()) if r.ok else 'ERR')
if r.ok and r.json():
    print('STUDENTS cols:', list(r.json()[0].keys()))
    s = r.json()[0]
    print(f"  Sample: run={s.get('run')} name={s.get('first_name')} {s.get('apellido_paterno')} {s.get('apellido_materno')} curso={s.get('curso')}")

# Fee
r2 = requests.get(f'{url}/rest/v1/fee?select=*&limit=2', headers=headers)
print('\nFEE status:', r2.status_code, 'count:', len(r2.json()) if r2.ok else 'ERR')
if r2.ok and r2.json():
    print('FEE cols:', list(r2.json()[0].keys()))
    f = r2.json()[0]
    print(f"  Sample: student_id={f.get('student_id')} amount={f.get('amount')} cuota={f.get('numero_cuota')} status={f.get('status')} due={f.get('due_date')}")

# Cursos
r3 = requests.get(f'{url}/rest/v1/cursos?select=*&limit=10', headers=headers)
print('\nCURSOS status:', r3.status_code, 'count:', len(r3.json()) if r3.ok else 'ERR')
if r3.ok and r3.json():
    print('CURSOS cols:', list(r3.json()[0].keys()))
    for c in r3.json():
        print(f"  {c.get('nom_curso')} year={c.get('year_academico')} id={c.get('id')}")

# Total students count
r4 = requests.get(f'{url}/rest/v1/students?select=id', headers={**headers, 'Prefer': 'count=exact', 'Range': '0-0'})
print(f"\nTotal students: {r4.headers.get('content-range', 'unknown')}")

# Total fees count
r5 = requests.get(f'{url}/rest/v1/fee?select=id', headers={**headers, 'Prefer': 'count=exact', 'Range': '0-0'})
print(f"Total fees: {r5.headers.get('content-range', 'unknown')}")
