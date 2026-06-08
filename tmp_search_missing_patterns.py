import pandas as pd
from pathlib import Path

patterns = ['19152079','25458455','24257000','25131769','24557181','23886325']
df = pd.read_csv(Path('tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv'))
for p in patterns:
    subset = df[df['run'].astype(str).str.contains(p, na=False, regex=False)]
    print('\nPATTERN', p, 'count', len(subset))
    if len(subset):
        print(subset[['run','date_of_birth','genero','curso']].head(10).to_string(index=False))
