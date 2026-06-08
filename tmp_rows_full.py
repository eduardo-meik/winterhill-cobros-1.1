import pandas as pd
from pathlib import Path

df = pd.read_csv(Path('tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv'))
runs = ['19152079-3','25458455-K','24257000-6','25131769-0','24557181-K','23886325-1']
for r in runs:
    row = df[df['run'].astype(str).str.replace('.','',regex=False).str.replace(' ','',regex=False).str.upper() == r]
    print('\nRUN', r, 'count', len(row))
    if len(row):
        print(row.to_string(index=False))
