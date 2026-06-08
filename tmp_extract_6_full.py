import pandas as pd
from pathlib import Path

xl = pd.read_excel(Path('Libro Matrícula Año Escolar 2026 (3).xlsx'), sheet_name='Hoja 4')
need = ['19152079-3','25458455-K','24257000-6','25131769-0','24557181-K','23886325-1']

def canon(x):
    if pd.isna(x):
        return None
    s = str(x).strip().upper().replace('.','').replace(' ','')
    if not s:
        return None
    if '-' in s:
        body, dv = s.split('-',1)
    else:
        body, dv = s[:-1], s[-1]
    return f"{int(body)}-{dv}" if body.isdigit() else f"{body}-{dv}"

xl['run_canon'] = xl['RUN ESTUDIANTE'].map(canon)
cols = [
    'NOMBRES','APELLIDO PATERNOV','APELLIDO MATERNO','RUN ESTUDIANTE','FECHA NAC ESTUD','NACIONALIDAD','GÉNERO ESTUDIANTE',
    '  ¿CON QUIÉN VIVE EL ESTUDIANTE?','DIRECCIÓN ESTUDIANTE','COMUNA','  ¿EL ESTUDIANTE REPITE EL CURSO ACTUAL?  ',
    '  ¿CUÁL ES LA INSTITUCIÓN DE PROCEDENCIA DEL ESTUDIANTE?  ','¿CUÁL ES EL NOMBRE DEL APODERADO? ',
    '  ¿CUÁL ES EL APELLIDO PATERNO DEL APODERADO?  ','  ¿CUÁL ES EL APELLIDO MATERNO DEL APODERADO?  ',
    '¿CUÁL ES SU RELACIÓN CON EL ESTUDIANTE?','FECHA NAC APODERADO','  ¿CUÁL ES EL RUT DEL APODERADO?  ',
    '  ¿CUÁL ES EL NIVEL EDUCACIONAL DEL APODERADO?  ','  ¿CUÁL ES LA DIRECCIÓN DE RESIDENCIA DEL APODERADO?  ',
    '  ¿CUÁL ES LA COMUNA DE RESIDENCIA DEL APODERADO? ','  ¿CUÁL ES EL EMAIL DE CONTACTO DEL APODERADO?  ','¿CUÁL ES SU TELÉFONO?',
    'APODERADO SECUNDARIO','RELACION CON ESTUDIANTE_APODERADO_SECUNDARIO','RUT APODERADO SECUNDARIO','FECH NAC APOD SEC',
    'AÑADA EL TELÉFONO DEL CONTACTO DISTINTO AL APODERADO SI FUESE EL CASO','MAIL APODERADO SECUNDARIO','FECHA DE RETIRO',
    '  MOTIVO DEL RETIRO DEL ESTUDIANTE ','CONDICION','CURSO '
]
for r in need:
    row = xl[xl['run_canon'] == r]
    print('\n###', r)
    if row.empty:
        print('NOT FOUND')
        continue
    rec = row[cols].iloc[0]
    for c in cols:
        print(f'{c}: {rec[c]}')
