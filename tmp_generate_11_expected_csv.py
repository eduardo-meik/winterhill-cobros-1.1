import csv
from decimal import Decimal, InvalidOperation
from pathlib import Path

source_csv = Path(r'c:\Meik_Apps\winterhill-cobros-1.1\reporte_matriculados_forma_pago_vs_aranceles_2026_20260408 copy_11_casos.csv')
diff_records_csv = Path(r'c:\Meik_Apps\winterhill-cobros-1.1\tmp_csv_internal_matricula_vs_aranceles_diff_records.csv')
output_csv = Path(r'c:\Meik_Apps\winterhill-cobros-1.1\reporte_matriculados_forma_pago_vs_aranceles_2026_20260408 copy_11_casos_con_esperados.csv')

with source_csv.open('r', encoding='utf-8-sig', newline='') as f:
    source_rows = list(csv.DictReader(f))
    source_headers = list(source_rows[0].keys())

with diff_records_csv.open('r', encoding='utf-8-sig', newline='') as f:
    diff_rows = list(csv.DictReader(f))
diff_by_student = {row['ID Estudiante']: row for row in diff_rows}


def to_decimal(value):
    text = '' if value is None else str(value).strip()
    if not text:
        return None
    try:
        return Decimal(text)
    except (InvalidOperation, ValueError):
        return None


def is_positive(value):
    dec = to_decimal(value)
    return dec is not None and dec > 0


extra_headers = [
    'issues',
    'resolucion_sugerida',
    'esperado_matricula_forma_pago',
    'esperado_matricula_cuotas',
    'esperado_matricula_monto_por_cuota',
    'esperado_matricula_total_anual',
    'esperado_aranceles_n_cuotas',
    'esperado_aranceles_forma_pago',
    'esperado_aranceles_monto_min',
    'esperado_aranceles_monto_max',
    'esperado_aranceles_total',
]

output_rows = []
for row in source_rows:
    diff = diff_by_student[row['ID Estudiante']]
    issues = diff['issues'].split('|') if diff['issues'] else []
    arancel_has_values = (
        row.get('Aranceles: Forma de Pago', '').strip() not in ('', 'SIN_FEE')
        or is_positive(row.get('Aranceles: N° Cuotas', ''))
        or is_positive(row.get('Aranceles: Monto Cuota Mínimo', ''))
        or is_positive(row.get('Aranceles: Total', ''))
    )

    if 'FEE_FALTANTE' in issues and not arancel_has_values:
        resolucion = 'Copiar matrícula hacia aranceles'
    elif 'FEE_FALTANTE' in issues and arancel_has_values:
        resolucion = 'Revisión manual'
    else:
        resolucion = 'Copiar aranceles hacia matrícula'

    if resolucion == 'Copiar matrícula hacia aranceles':
        expected_aranceles_n_cuotas = row.get('Matrícula: N° Cuotas', '')
        expected_aranceles_forma_pago = row.get('Matrícula: Forma de Pago', '')
        expected_aranceles_monto = row.get('Matrícula: Monto por Cuota', '')
        expected_aranceles_total = row.get('Matrícula: Total Anual', '')
        expected_matricula_forma_pago = row.get('Matrícula: Forma de Pago', '')
        expected_matricula_cuotas = row.get('Matrícula: N° Cuotas', '')
        expected_matricula_monto = row.get('Matrícula: Monto por Cuota', '')
        expected_matricula_total = row.get('Matrícula: Total Anual', '')
    else:
        expected_matricula_forma_pago = row.get('Aranceles: Forma de Pago', '') if row.get('Aranceles: Forma de Pago', '').strip() else row.get('Matrícula: Forma de Pago', '')
        expected_matricula_cuotas = row.get('Aranceles: N° Cuotas', '') if row.get('Aranceles: N° Cuotas', '').strip() else row.get('Matrícula: N° Cuotas', '')
        expected_matricula_monto = row.get('Aranceles: Monto Cuota Mínimo', '') if row.get('Aranceles: Monto Cuota Mínimo', '').strip() else row.get('Matrícula: Monto por Cuota', '')
        expected_matricula_total = row.get('Aranceles: Total', '') if row.get('Aranceles: Total', '').strip() else row.get('Matrícula: Total Anual', '')
        expected_aranceles_n_cuotas = row.get('Aranceles: N° Cuotas', '')
        expected_aranceles_forma_pago = row.get('Aranceles: Forma de Pago', '')
        expected_aranceles_monto = row.get('Aranceles: Monto Cuota Mínimo', '')
        expected_aranceles_total = row.get('Aranceles: Total', '')

    output_row = dict(row)
    output_row.update({
        'issues': diff['issues'],
        'resolucion_sugerida': resolucion,
        'esperado_matricula_forma_pago': expected_matricula_forma_pago,
        'esperado_matricula_cuotas': expected_matricula_cuotas,
        'esperado_matricula_monto_por_cuota': expected_matricula_monto,
        'esperado_matricula_total_anual': expected_matricula_total,
        'esperado_aranceles_n_cuotas': expected_aranceles_n_cuotas,
        'esperado_aranceles_forma_pago': expected_aranceles_forma_pago,
        'esperado_aranceles_monto_min': expected_aranceles_monto,
        'esperado_aranceles_monto_max': expected_aranceles_monto,
        'esperado_aranceles_total': expected_aranceles_total,
    })
    output_rows.append(output_row)

with output_csv.open('w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=source_headers + extra_headers, quoting=csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(output_rows)

print(f'selected_rows = {len(output_rows)}')
print(output_csv)
