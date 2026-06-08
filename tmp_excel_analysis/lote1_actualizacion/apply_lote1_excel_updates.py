import json
import os
from pathlib import Path
from urllib import error, parse, request

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
ENV_PATHS = [ROOT / '.env', ROOT / '.env.local']
STUDENTS_CSV = Path(__file__).with_name('lote1_students_upsert.csv')
GUARDIANS_CSV = Path(__file__).with_name('lote1_guardians_upsert.csv')


def load_env():
    env = {}
    for env_path in ENV_PATHS:
        if not env_path.exists():
            continue
        for line in env_path.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            env[key] = value
    return env


def normalize_rut(value):
    if pd.isna(value):
        return None
    text = str(value).strip().upper().replace('.', '').replace(' ', '')
    return text or None


def format_rut_for_db(value):
    normalized = normalize_rut(value)
    if not normalized:
        return None
    if '-' in normalized:
        body, dv = normalized.split('-', 1)
    else:
        body, dv = normalized[:-1], normalized[-1]
    body = body.lstrip('0') or '0'
    groups = []
    while body:
        groups.append(body[-3:])
        body = body[:-3]
    dotted_body = '.'.join(reversed(groups))
    return f'{dotted_body}-{dv}'


def to_iso_date(value):
    parsed = pd.to_datetime(value, errors='coerce')
    if pd.isna(parsed):
        return None
    return parsed.date().isoformat()


def to_bool(value):
    if pd.isna(value):
        return None
    if isinstance(value, bool):
        return value
    text = str(value).strip().lower()
    if text in {'true', '1', 'si', 'sí', 'yes'}:
        return True
    if text in {'false', '0', 'no'}:
        return False
    return None


def normalize_gender(value):
    text = (str(value).strip() if not pd.isna(value) else '')
    if not text:
        return None
    upper = text.upper()
    if upper.startswith('FEMEN'):
        return 'FEMENINO'
    if upper.startswith('MASCUL'):
        return 'MASCULINO'
    if 'NO BINAR' in upper or 'FLUID' in upper or 'FLUÍD' in upper:
        return 'NO BINARIE'
    return None


def normalize_relationship_type(value):
    text = (str(value).strip() if not pd.isna(value) else '')
    if not text:
        return None
    upper = text.upper()
    if 'MADRE' in upper or 'MAMA' in upper or 'MAMÁ' in upper:
        return 'MADRE'
    if 'PADRE' in upper or 'PAPA' in upper or 'PAPÁ' in upper:
        return 'PADRE'
    return 'TUTOR'


def clean_payload(payload):
    return {key: value for key, value in payload.items() if value is not None and value != ''}


def rest_request(base_url, service_key, method, endpoint, query_params=None, body=None):
    url = f"{base_url.rstrip('/')}/rest/v1/{endpoint}"
    if query_params:
        url += '?' + parse.urlencode(query_params, doseq=True)
    headers = {
        'apikey': service_key,
        'Authorization': f'Bearer {service_key}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Prefer': 'return=representation',
    }
    data = None if body is None else json.dumps(body).encode('utf-8')
    req = request.Request(url, data=data, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode('utf-8')
            if not raw.strip():
                return []
            return json.loads(raw)
    except error.HTTPError as exc:
        detail = exc.read().decode('utf-8', errors='ignore')
        raise RuntimeError(f'HTTP {exc.code} {exc.reason} for {method} {endpoint}: {detail}') from exc


def build_student_payload(row):
    return clean_payload({
        'date_of_birth': to_iso_date(row.get('date_of_birth')),
        'genero': normalize_gender(row.get('genero')),
        'direccion': row.get('direccion') if pd.notna(row.get('direccion')) else None,
        'comuna': row.get('comuna') if pd.notna(row.get('comuna')) else None,
        'repite_curso_actual': to_bool(row.get('repite_curso_actual')),
        'institucion_procedencia': row.get('institucion_procedencia') if pd.notna(row.get('institucion_procedencia')) else None,
        'con_quien_vive': row.get('con_quien_vive') if pd.notna(row.get('con_quien_vive')) else None,
    })


def build_guardian_payload(row):
    dob = to_iso_date(row.get('date_of_birth'))
    return clean_payload({
        'first_name': row.get('first_name') if pd.notna(row.get('first_name')) else None,
        'last_name': row.get('last_name') if pd.notna(row.get('last_name')) else None,
        'apellido_paterno': row.get('apellido_paterno') if pd.notna(row.get('apellido_paterno')) else None,
        'apellido_materno': row.get('apellido_materno') if pd.notna(row.get('apellido_materno')) else None,
        'email': row.get('email') if pd.notna(row.get('email')) else None,
        'phone': row.get('phone') if pd.notna(row.get('phone')) else None,
        'address': row.get('address') if pd.notna(row.get('address')) else None,
        'comuna': row.get('comuna') if pd.notna(row.get('comuna')) else None,
        'date_of_birth': dob,
        'date_birth': dob,
        'nivel_educacional': row.get('nivel_educacional') if pd.notna(row.get('nivel_educacional')) else None,
        'family_tie': normalize_relationship_type(row.get('family_tie')),
        'relationship_type': normalize_relationship_type(row.get('relationship_type')),
    })


def patch_by_run(base_url, service_key, endpoint, run_value, payload):
    if not payload:
        return 0, []
    query = {'run': f'eq.{run_value}'}
    data = rest_request(base_url, service_key, 'PATCH', endpoint, query_params=query, body=payload)
    return len(data), data


def main():
    env = load_env()
    base_url = env.get('VITE_SUPABASE_URL')
    service_key = env.get('SUPABASE_SERVICE_ROLE_KEY') or env.get('SERVICE_ROLE_KEY')

    if not base_url or not service_key:
        raise SystemExit('Faltan VITE_SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env/.env.local')

    students_df = pd.read_csv(STUDENTS_CSV)
    guardians_df = pd.read_csv(GUARDIANS_CSV)

    results = {
        'students_total': len(students_df),
        'students_matched': 0,
        'students_missing': [],
        'students_failed': [],
        'guardians_total': len(guardians_df),
        'guardians_matched': 0,
        'guardians_missing': [],
        'guardians_failed': [],
    }

    for _, row in students_df.iterrows():
        run_value = format_rut_for_db(row.get('run'))
        if not run_value:
            continue
        payload = build_student_payload(row)
        try:
            matched, _ = patch_by_run(base_url, service_key, 'students', run_value, payload)
            if matched:
                results['students_matched'] += 1
            else:
                results['students_missing'].append(run_value)
        except Exception as exc:
            results['students_failed'].append({'run': run_value, 'error': str(exc)})

    for _, row in guardians_df.iterrows():
        run_value = format_rut_for_db(row.get('run'))
        if not run_value:
            continue
        payload = build_guardian_payload(row)
        try:
            matched, _ = patch_by_run(base_url, service_key, 'guardians', run_value, payload)
            if matched:
                results['guardians_matched'] += 1
            else:
                results['guardians_missing'].append(run_value)
        except Exception as exc:
            results['guardians_failed'].append({'run': run_value, 'error': str(exc)})

    out_path = Path(__file__).with_name('lote1_apply_results.json')
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')

    print(json.dumps(results, ensure_ascii=False, indent=2))
    print(f'RESULT_FILE={out_path}')


if __name__ == '__main__':
    main()
