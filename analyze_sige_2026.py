#!/usr/bin/env python3
"""
Análisis completo del archivo SIGE 2026 del Colegio Winterhill.
Detecta duplicados, inconsistencias, datos de prueba, formas de pago, 
prioridad y descuentos.
"""
import csv
import re
import json
from collections import Counter, defaultdict

def parse_money(val):
    """Parse Chilean peso format: $1,028,700 or 102870 or 25.718"""
    if not val or val.strip() == '':
        return None
    val = val.strip().replace('$', '').replace(',', '').replace(' ', '')
    # Handle case where . is used as thousands separator (25.718 = 25718)
    # If the number has a dot and 3 digits after dot, it's thousands separator
    if '.' in val:
        parts = val.split('.')
        if len(parts) == 2 and len(parts[1]) == 3:
            val = val.replace('.', '')  # thousands separator
        elif len(parts) == 2 and len(parts[1]) == 0:
            val = parts[0]
    try:
        return int(float(val))
    except ValueError:
        return None

def normalize_pago(pago):
    """Normalize payment method to uppercase standard"""
    if not pago or pago.strip() == '':
        return 'SIN FORMA DE PAGO'
    p = pago.strip().upper()
    if p in ('PAGARE', 'PAGARÉ'):
        return 'PAGARE'
    if p in ('CHEQUE', 'CHEQUES'):
        return 'CHEQUE'
    if p in ('TRANSFERENCIA', 'TRANFERENCIA'):
        return 'TRANSFERENCIA'
    if p in ('TARJETA',):
        return 'TARJETA'
    if p in ('PRIORITARIO',):
        return 'PRIORITARIO'
    if p in ('DESCUENTO',):
        return 'DESCUENTO'
    if p in ('BECA',):
        return 'BECA'
    if 'DESCUENTO' in p or 'DESC' in p:
        return 'DESCUENTO'
    return p

# Arancel estándar 2026 por nivel
ARANCEL_BASICA = 1028700
ARANCEL_MEDIA = 1331260

def get_arancel_esperado(curso):
    """Retorna el arancel anual esperado según el curso"""
    c = curso.strip().upper()
    if 'MEDIO' in c or 'MEDIA' in c:
        return ARANCEL_MEDIA
    return ARANCEL_BASICA

rows = []
with open('sige_2026.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    for line_num, row in enumerate(reader, start=2):
        if len(row) < 12:
            row.extend([''] * (12 - len(row)))
        rec = {
            'linea': line_num,
            'curso_2026': row[0].strip(),
            'num': row[1].strip(),
            'rut': row[2].strip(),
            'nombre': row[3].strip(),
            'detalle': row[4].strip(),
            'col5': row[5].strip(),
            'estado': row[6].strip(),
            'pago_raw': row[7].strip(),
            'cuota_raw': row[8].strip(),
            'num_cuotas_raw': row[9].strip(),
            'anual_raw': row[10].strip(),
            'observacion': row[11].strip() if len(row) > 11 else '',
        }
        rec['pago'] = normalize_pago(rec['pago_raw'])
        rec['cuota'] = parse_money(rec['cuota_raw'])
        rec['num_cuotas'] = int(rec['num_cuotas_raw']) if rec['num_cuotas_raw'].strip().isdigit() else None
        rec['anual'] = parse_money(rec['anual_raw'])
        rec['arancel_esperado'] = get_arancel_esperado(rec['curso_2026'])
        rows.append(rec)

print(f"Total registros SIGE 2026: {len(rows)}")
print(f"Header: {header}")

# ============================================================
# 1. DUPLICADOS POR RUT
# ============================================================
rut_counter = Counter(r['rut'] for r in rows)
duplicados = {rut: count for rut, count in rut_counter.items() if count > 1}
print(f"\n=== DUPLICADOS POR RUT ({len(duplicados)}) ===")
for rut, count in sorted(duplicados.items()):
    matches = [r for r in rows if r['rut'] == rut]
    for m in matches:
        print(f"  RUT {rut} ({count}x): {m['nombre']} - Curso: {m['curso_2026']} (línea {m['linea']})")

# ============================================================
# 2. INCONSISTENCIAS DE MONTOS
# ============================================================
print(f"\n=== INCONSISTENCIAS DE MONTOS ===")
inconsistencias = []

for r in rows:
    issues = []
    
    # a) PRIORITARIO con cuotas/montos
    if r['pago'] == 'PRIORITARIO' and (r['cuota'] is not None or r['anual'] is not None):
        issues.append(f"PRIORITARIO con monto: cuota={r['cuota_raw']}, anual={r['anual_raw']}")
    
    # b) Cuota * num_cuotas != anual
    if r['cuota'] is not None and r['num_cuotas'] is not None and r['anual'] is not None:
        esperado = r['cuota'] * r['num_cuotas']
        if abs(esperado - r['anual']) > 100:  # tolerance for rounding
            issues.append(f"cuota({r['cuota']}) x {r['num_cuotas']} = {esperado} ≠ anual({r['anual']})")
    
    # c) Anual faltante pero cuota presente
    if r['cuota'] is not None and r['anual'] is None and r['pago'] != 'PRIORITARIO':
        issues.append(f"Tiene cuota({r['cuota_raw']}) pero sin monto anual")
    
    # d) Monto anual muy diferente al arancel esperado (ni el estándar ni un descuento razonable)
    if r['anual'] is not None and r['anual'] > 0:
        arancel = r['arancel_esperado']
        if r['anual'] > arancel * 1.5:
            issues.append(f"Monto anual {r['anual']} EXCESIVO vs arancel {arancel}")
        # Check for known bad amount - e.g. $257 instead of $257,180
        if r['anual'] < 1000 and r['num_cuotas'] and r['num_cuotas'] >= 10:
            issues.append(f"Monto anual sospechosamente bajo: {r['anual']}")
    
    # e) PAGARE/CHEQUE sin monto
    if r['pago'] in ('PAGARE', 'CHEQUE', 'TRANSFERENCIA') and r['cuota'] is None and r['anual'] is None:
        issues.append(f"Forma de pago {r['pago']} sin monto asociado")
    
    # f) Formato de cuota sin signo $
    if r['cuota_raw'] and '$' not in r['cuota_raw'] and r['cuota'] is not None:
        issues.append(f"Formato cuota sin $: '{r['cuota_raw']}'")
    
    # g) Solo 1 cuota (posible error o tarjeta)
    if r['num_cuotas'] == 1 and r['pago'] not in ('TARJETA', 'BECA', 'SIN FORMA DE PAGO'):
        issues.append(f"Solo 1 cuota con pago {r['pago']}")
    
    # h) 5 cuotas (posible Arenas Landeros familia especial)
    if r['num_cuotas'] == 5:
        issues.append(f"Tiene 5 cuotas (verificar si es correcto)")
    
    # i) No tiene forma de pago pero tiene montos
    if r['pago'] == 'SIN FORMA DE PAGO' and (r['cuota'] is not None or r['anual'] is not None):
        issues.append(f"Sin forma de pago pero con monto: cuota={r['cuota_raw']}, anual={r['anual_raw']}")
    
    # j) 4 Medio con arancel de básica
    if 'MEDIO' in r['curso_2026'].upper() and r['anual'] is not None:
        if r['anual'] == ARANCEL_BASICA:
            issues.append(f"Alumno de Media con arancel {r['anual']} = arancel BÁSICA (debería ser {ARANCEL_MEDIA})")
    
    if issues:
        inconsistencias.append((r, issues))
        for iss in issues:
            print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {iss}")

# ============================================================
# 3. DATOS DE PRUEBA / TEST / DRAFT
# ============================================================
print(f"\n=== REFERENCIAS A TEST/DRAFT/PRUEBA ===")
test_patterns = re.compile(r'(test|testing|prueba|borrar|draft|drat)', re.IGNORECASE)
test_refs = []
for r in rows:
    obs = r['observacion']
    found = test_patterns.findall(obs)
    if found:
        test_refs.append(r)
        print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | obs: {obs[:100]}")

# ============================================================
# 4. SIN MATRICULAR 
# ============================================================
print(f"\n=== SIN MATRICULAR ===")
sin_matricular = []
no_matricula_pattern = re.compile(r'SIN MATRIC|NO APARECE MATRIC|NO APARECE COMO MATRIC|SIN REGISTRO DE MATRICULA|NO HAY REGISTRO', re.IGNORECASE)
for r in rows:
    obs = r['observacion']
    if no_matricula_pattern.search(obs):
        sin_matricular.append(r)
        print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {r['curso_2026']} | obs: {obs[:80]}")

# Also students with empty pago AND no amounts AND not PRIORITARIO
for r in rows:
    if r['pago'] == 'SIN FORMA DE PAGO' and r['cuota'] is None and r['anual'] is None:
        if r['pago_raw'].strip() == '' and r not in sin_matricular:
            # Check if observation mentions sin matricular
            if not no_matricula_pattern.search(r['observacion']):
                sin_matricular.append(r)
                print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {r['curso_2026']} | Sin datos de pago")

# ============================================================
# 5. NO ADMITIDOS
# ============================================================
print(f"\n=== NO ADMITIDOS ===")
for r in rows:
    if 'NO ADMITIDO' in r['estado'].upper():
        print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {r['curso_2026']} | {r['estado']}")

# ============================================================
# 6. FORMAS DE PAGO - RESUMEN
# ============================================================
print(f"\n=== FORMAS DE PAGO (RESUMEN) ===")
pago_counter = Counter(r['pago'] for r in rows)
for pago, count in pago_counter.most_common():
    print(f"  {pago:25} : {count}")

# ============================================================
# 7. PRIORITARIOS VS NO PRIORITARIOS
# ============================================================
prioritarios = [r for r in rows if r['pago'] == 'PRIORITARIO']
no_prioritarios = [r for r in rows if r['pago'] != 'PRIORITARIO']
print(f"\n=== PRIORITARIOS VS PAGADORES ===")
print(f"  Prioritarios: {len(prioritarios)}")
print(f"  No prioritarios (pagadores + otros): {len(no_prioritarios)}")

# ============================================================
# 8. DESCUENTOS
# ============================================================
print(f"\n=== DESCUENTOS ===")
descuentos = []
for r in rows:
    if r['pago'] == 'DESCUENTO' or r['pago'] == 'BECA':
        descuentos.append(r)
        arancel = r['arancel_esperado']
        pct = round((1 - (r['anual'] or 0) / arancel) * 100, 1) if r['anual'] else '?'
        print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {r['curso_2026']} | anual={r['anual_raw']:>12} | ~{pct}% desc")

# Also find students with amounts less than standard arancel (implicit discount)
print(f"\n=== CON DESCUENTO IMPLÍCITO (arancel menor al estándar, no marcados como DESCUENTO) ===")
for r in rows:
    if r['anual'] is not None and r['anual'] > 0 and r['pago'] not in ('DESCUENTO', 'BECA', 'PRIORITARIO'):
        arancel = r['arancel_esperado']
        if r['anual'] < arancel * 0.95:  # more than 5% discount
            pct = round((1 - r['anual'] / arancel) * 100, 1)
            descuentos.append(r)
            print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | {r['curso_2026']} | pago={r['pago']:15} | anual={r['anual']:>10} vs {arancel} | ~{pct}% desc")

# ============================================================
# 9. OBSERVACIONES SOBRE CUOTAS (9 cuotas en vez de 10)
# ============================================================
print(f"\n=== ALERTAS EN OBSERVACIONES ===")
cuota_9_pattern = re.compile(r'9 cuotas|con 9|DUPLICADO', re.IGNORECASE)
for r in rows:
    if cuota_9_pattern.search(r['observacion']):
        print(f"  L{r['linea']} {r['rut']} {r['nombre'][:35]:35} | obs: {r['observacion'][:80]}")

# ============================================================
# 10. RESUMEN POR CURSO
# ============================================================
print(f"\n=== RESUMEN POR CURSO ===")
cursos = defaultdict(lambda: {'total': 0, 'prioritarios': 0, 'pagadores': 0, 'sin_matricular': 0})
for r in rows:
    c = r['curso_2026']
    cursos[c]['total'] += 1
    if r['pago'] == 'PRIORITARIO':
        cursos[c]['prioritarios'] += 1
    elif r['pago'] in ('PAGARE', 'CHEQUE', 'TRANSFERENCIA', 'TARJETA', 'DESCUENTO', 'BECA'):
        cursos[c]['pagadores'] += 1
    else:
        cursos[c]['sin_matricular'] += 1

for curso in sorted(cursos.keys()):
    d = cursos[curso]
    print(f"  {curso:15} | Total: {d['total']:2} | Prio: {d['prioritarios']:2} | Pagan: {d['pagadores']:2} | Sin dato: {d['sin_matricular']:2}")

# ============================================================
# 11. APELLIDOS EN COMÚN (posibles hermanos)
# ============================================================
print(f"\n=== POSIBLES HERMANOS (mismo primer apellido) ===")
apellidos = defaultdict(list)
for r in rows:
    parts = r['nombre'].split()
    if len(parts) >= 2:
        apellido = parts[0]
        apellidos[apellido].append(r)

for ap, studs in sorted(apellidos.items()):
    if len(studs) > 1:
        ruts = set(s['rut'] for s in studs)
        if len(ruts) > 1:  # not duplicates
            names = [f"{s['nombre'][:30]} ({s['curso_2026']})" for s in studs]
            # Actually check by first two words (apellido paterno + materno)
            pass

# Better: group by first TWO words (paterno + materno)
apellidos2 = defaultdict(list)
for r in rows:
    parts = r['nombre'].split()
    if len(parts) >= 2:
        key = f"{parts[0]} {parts[1]}"
        apellidos2[key].append(r)

hermanos = []
for key, studs in sorted(apellidos2.items()):
    ruts = set(s['rut'] for s in studs)
    if len(ruts) > 1:  # different students with same double surname
        hermanos.append((key, studs))
        names_str = "; ".join(f"{s['nombre'][:30]} ({s['curso_2026']}, {s['pago']})" for s in studs)
        print(f"  {key}: {names_str}")

# ============================================================
# GENERATE JSON for markdown report
# ============================================================
report = {
    'total': len(rows),
    'duplicados': [(r['rut'], r['nombre'], r['curso_2026'], r['linea']) for rut in duplicados for r in rows if r['rut'] == rut],
    'inconsistencias_count': len(inconsistencias),
    'test_refs_count': len(test_refs),
    'sin_matricular_count': len(sin_matricular),
    'prioritarios_count': len(prioritarios),
    'pagadores_count': len([r for r in rows if r['pago'] in ('PAGARE', 'CHEQUE', 'TRANSFERENCIA', 'TARJETA')]),
    'descuentos_count': len([r for r in rows if r['pago'] in ('DESCUENTO', 'BECA')]),
    'pago_breakdown': dict(pago_counter.most_common()),
}

print(f"\n=== RESUMEN FINAL ===")
print(f"Total estudiantes SIGE: {report['total']}")
print(f"Duplicados RUT: {len(duplicados)} RUTs")
print(f"Inconsistencias: {report['inconsistencias_count']}")
print(f"Refs test/draft: {report['test_refs_count']}")
print(f"Sin matricular: {report['sin_matricular_count']}")
print(f"Prioritarios: {report['prioritarios_count']}")
print(f"Pagadores: {report['pagadores_count']}")
print(f"Con descuento explícito: {report['descuentos_count']}")
