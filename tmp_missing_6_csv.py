import pandas as pd
from pathlib import Path

runs = ['19.152.079-3','25.458.455-K','24.257.000-6','25.131.769-0','24.557.181-K','23.886.325-1']
df = pd.read_csv(Path('tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv'))
for r in runs:
    row = df[df['run'] == r]
    print('\nRUN', r)
    if row.empty:
        print('no encontrado en lote1_students_upsert.csv')
    else:
        print(row[['run','date_of_birth','genero','direccion','comuna','repite_curso_actual','institucion_procedencia','con_quien_vive','curso']].head(1).to_string(index=False))
