#!/usr/bin/env python3
"""Analyze CSV content."""
import csv

rows = list(csv.DictReader(open('cuotas_importacion.csv', encoding='utf-8-sig')))
print(f'Total rows: {len(rows)}')

ruts = set(r['RUN'].strip() for r in rows)
nombres = set(
    r['APELLIDO PATERNO'].strip() + ' ' + r['APELLIDO MATERNO'].strip() + ' ' + r['NOMBRES'].strip()
    for r in rows
)
cursos = sorted(set(r['CURSO'].strip() for r in rows))
estados = sorted(set(r['ESTADO'].strip() for r in rows))
cuotas = sorted(set(r['CUOTA'].strip() for r in rows))

print(f'Unique RUNs: {len(ruts)}')
print(f'Unique students: {len(nombres)}')
print(f'Cursos: {cursos}')
print(f'Estados: {estados}')
print(f'Cuotas: {cuotas}')
print('\nStudents in CSV:')
for n in sorted(nombres):
    # Find RUN for this name
    for r in rows:
        full = r['APELLIDO PATERNO'].strip() + ' ' + r['APELLIDO MATERNO'].strip() + ' ' + r['NOMBRES'].strip()
        if full == n:
            print(f"  RUN={r['RUN'].strip()} | {n} | {r['CURSO'].strip()}")
            break

print('\nSample montos:')
for r in rows[:3]:
    print(f"  cuota={r['CUOTA']} monto={r[' MONTO ']} fecha={r['FECHA']} estado={r['ESTADO']}")
