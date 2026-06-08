import pandas as pd
from pathlib import Path
base=Path('tmp_excel_analysis/lote1_actualizacion')
ex=pd.read_csv(base/'lote1_excluded_rows.csv')
print('Excluidos total:', len(ex))
print('\nTop motivos:')
print(ex['_reason_excluded'].value_counts().head(12).to_string())
