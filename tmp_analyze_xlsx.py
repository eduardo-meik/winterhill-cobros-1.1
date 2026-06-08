import pandas as pd
import re
from pathlib import Path

path = Path(r"C:/Meik_Apps/winterhill-cobros-1.1/Libro Matrícula Año Escolar 2026 (3).xlsx")
xl = pd.ExcelFile(path)
print("SHEETS:", xl.sheet_names)

key_pattern = re.compile(r"rut|dv|apoder|estudiante|alumno|correo|mail|telefono|fono|cel|direccion|curso|nivel|comuna|fecha|matric|folio|pagar", re.I)

for sh in xl.sheet_names:
    df = xl.parse(sh)
    print(f"\n=== SHEET: {sh} ===")
    print("rows:", len(df), "cols:", len(df.columns))
    cols = [str(c) for c in df.columns]
    key_cols = [c for c in cols if key_pattern.search(c)]
    print("key_columns:", key_cols)

    for c in key_cols:
        s = df[c]
        nn = s.notna().sum()
        uniq = s.dropna().astype(str).str.strip().replace('', pd.NA).dropna().nunique()
        print(f"  - {c}: non_null={nn}, unique={uniq}")

    print("sample key data:")
    if key_cols:
        print(df[key_cols].head(8).to_string(index=False))
    else:
        print(df.head(8).to_string(index=False))
