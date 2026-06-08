import pandas as pd
from pathlib import Path

files = [
    Path('actualizacionesDB/generated_staging_14923/14923_estudiantes_staging.csv'),
    Path('actualizacionesDB/generated_staging_14923/14923_apoderados_staging.csv'),
    Path('students_only_extract.csv')
]
for p in files:
    if p.exists():
        try:
            df = pd.read_csv(p)
        except Exception:
            df = pd.read_csv(p, sep=';', encoding='latin1')
        print(f'\n=== {p.as_posix()} ===')
        print('rows', len(df), 'cols', len(df.columns))
        print('columns', list(df.columns)[:25])
        print(df.head(3).to_string(index=False))
    else:
        print(f'No existe: {p.as_posix()}')
