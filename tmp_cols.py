import pandas as pd
from pathlib import Path
xl = pd.read_excel(Path('Libro Matrícula Año Escolar 2026 (3).xlsx'), sheet_name='Hoja 4')
print(list(xl.columns))
print('rows', len(xl))
