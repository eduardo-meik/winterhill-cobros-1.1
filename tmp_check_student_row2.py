import pandas as pd
from pathlib import Path
p = Path('tmp_excel_analysis/lote1_actualizacion/lote1_students_upsert.csv')
df = pd.read_csv(p)
row = df[df['run'].astype(str).str.contains('23847613', na=False)]
print(row.to_string(index=False))
