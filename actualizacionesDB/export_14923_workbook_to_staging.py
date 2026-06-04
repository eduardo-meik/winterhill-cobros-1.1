from __future__ import annotations

import csv
import json
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


WORKBOOK_PATH = Path(__file__).with_name(
    "14923 - Registro de matrícula - Colegio Winterhill - 13-04-2026 - 11_59.xlsx"
)
OUTPUT_DIR = Path(__file__).parent / "generated_staging_14923"
CHUNK_SIZE = 100

NS = {
    "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}

STUDENTS_COLUMNS = [
    "source_row_number",
    "rbd",
    "anio",
    "colegio",
    "local_escolar",
    "codigo_nivel_educativo",
    "nivel_educativo",
    "curso",
    "numero_lista",
    "numero_matricula",
    "fecha_matricula_raw",
    "run_estudiante",
    "run_dv",
    "apellido_paterno",
    "apellido_materno",
    "nombres",
    "estado_estudiante",
    "fecha_nacimiento_raw",
    "genero",
    "origen_indigena",
    "nacionalidad",
    "celular_estudiante",
    "email_estudiante",
    "pie",
    "nee_tipo",
    "diagnostico",
    "pro_retencion",
    "sep",
    "repite_curso_actual",
    "ingreso_anio_establecimiento",
    "observaciones",
    "motivo_ingreso_tardio",
    "region",
    "comuna",
    "direccion",
    "prevision",
    "grupo_sanguineo",
    "estatura_cm",
    "peso_kg",
    "alertas_salud",
    "embarazo_estudiante",
    "fecha_retiro_raw",
    "razon_retiro",
    "foto",
]

STUDENTS_HEADER_MAP = {
    "RBD": "rbd",
    "Año": "anio",
    "Colegio": "colegio",
    "Local escolar": "local_escolar",
    "Código Nivel Educativo": "codigo_nivel_educativo",
    "Nivel Educativo": "nivel_educativo",
    "Curso": "curso",
    "N° Lista": "numero_lista",
    "N° Matrícula": "numero_matricula",
    "Fecha de Matrícula": "fecha_matricula_raw",
    "RUN Estudiante": "run_estudiante",
    "Dígito verificador": "run_dv",
    "Primer Apellido Estudiante": "apellido_paterno",
    "Segundo Apellido Estudiante": "apellido_materno",
    "Nombre Estudiante": "nombres",
    "Estado Estudiante": "estado_estudiante",
    "Fecha de Nacimiento": "fecha_nacimiento_raw",
    "Género": "genero",
    "Origen indígena": "origen_indigena",
    "Nacionalidad": "nacionalidad",
    "Celular estudiante": "celular_estudiante",
    "Email Estudiante": "email_estudiante",
    "PIE": "pie",
    "Necesidades educativas especiales tipo": "nee_tipo",
    "Diagnóstico": "diagnostico",
    "Pro-retención": "pro_retencion",
    "SEP": "sep",
    "Repite curso actual": "repite_curso_actual",
    "Ingreso año establecimiento": "ingreso_anio_establecimiento",
    "Observaciones": "observaciones",
    "Motivo de ingreso tardío": "motivo_ingreso_tardio",
    "Región": "region",
    "Comuna": "comuna",
    "Dirección": "direccion",
    "Previsión": "prevision",
    "Grupo Sanguíneo": "grupo_sanguineo",
    "Estatura (cm)": "estatura_cm",
    "Peso (kg)": "peso_kg",
    "Alergias, dificultades físicas y/o cognitivas a considerar": "alertas_salud",
    "Estudiante en situación de embarazo": "embarazo_estudiante",
    "Fecha de Retiro": "fecha_retiro_raw",
    "Razón de Retiro": "razon_retiro",
    "Foto": "foto",
}

GUARDIANS_COLUMNS = [
    "source_row_number",
    "rbd",
    "anio",
    "colegio",
    "local_escolar",
    "codigo_nivel_educativo",
    "nivel_educativo",
    "curso",
    "numero_lista",
    "numero_matricula",
    "fecha_matricula_raw",
    "run_estudiante",
    "run_estudiante_dv",
    "estudiante_apellido_paterno",
    "estudiante_apellido_materno",
    "estudiante_nombres",
    "estado_estudiante",
    "run_apoderado",
    "run_apoderado_dv",
    "apoderado_apellido_paterno",
    "apoderado_apellido_materno",
    "apoderado_nombres",
    "fecha_nacimiento_apoderado_raw",
    "email_apoderado",
    "telefono_apoderado",
    "registrado_kimche",
    "relacion_con_estudiante",
    "puede_retirar",
    "contacto_emergencia",
    "vive_con_estudiante",
    "nivel_educacional",
    "situacion_laboral",
    "lugar_trabajo",
    "region_apoderado",
    "comuna_apoderado",
    "direccion_apoderado",
]

GUARDIANS_HEADER_MAP = {
    "RBD": "rbd",
    "Año": "anio",
    "Colegio": "colegio",
    "Local escolar": "local_escolar",
    "Código Nivel Educativo": "codigo_nivel_educativo",
    "Nivel Educativo": "nivel_educativo",
    "Curso": "curso",
    "N° Lista": "numero_lista",
    "N° Matrícula": "numero_matricula",
    "Fecha de Matrícula": "fecha_matricula_raw",
    "RUN Estudiante": "run_estudiante",
    "Dígito verificador": "run_estudiante_dv",
    "Primer Apellido Estudiante": "estudiante_apellido_paterno",
    "Segundo Apellido Estudiante": "estudiante_apellido_materno",
    "Nombre Estudiante": "estudiante_nombres",
    "Estado Estudiante": "estado_estudiante",
    "RUN Apoderado": "run_apoderado",
    "Dígito verificador Apoderado": "run_apoderado_dv",
    "Primer Apellido Apoderado": "apoderado_apellido_paterno",
    "Segundo Apellido Apoderado": "apoderado_apellido_materno",
    "Nombre Apoderado": "apoderado_nombres",
    "Fecha de Nacimiento Apoderado": "fecha_nacimiento_apoderado_raw",
    "Email Apoderado": "email_apoderado",
    "Teléfono Apoderado": "telefono_apoderado",
    "Registro en Kimche Familia": "registrado_kimche",
    "Relación con el Estudiante": "relacion_con_estudiante",
    "Puede retirar al estudiante": "puede_retirar",
    "Contacto de emergencia": "contacto_emergencia",
    "Vive Con Estudiante": "vive_con_estudiante",
    "Último nivel educacional": "nivel_educacional",
    "Situación laboral": "situacion_laboral",
    "Lugar de Trabajo": "lugar_trabajo",
    "Región Apoderado": "region_apoderado",
    "Comuna Apoderado": "comuna_apoderado",
    "Dirección Apoderado": "direccion_apoderado",
}


def col_to_index(col_ref: str) -> int:
    value = 0
    for char in col_ref:
        value = (value * 26) + (ord(char) - 64)
    return value - 1


def load_shared_strings(archive: zipfile.ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []

    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    return [
        "".join((node.text or "") for node in item.iterfind(".//a:t", NS))
        for item in root.findall("a:si", NS)
    ]


def workbook_sheet_targets(archive: zipfile.ZipFile) -> dict[str, str]:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    rel_map = {rel.attrib["Id"]: rel.attrib["Target"] for rel in rels}

    return {
        sheet.attrib["name"]: f"xl/{rel_map[sheet.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']]}"
        for sheet in workbook.findall("a:sheets/a:sheet", NS)
    }


def read_sheet_rows(archive: zipfile.ZipFile, target: str, shared_strings: list[str]) -> list[list[str]]:
    root = ET.fromstring(archive.read(target))
    rows = []
    for row in root.find("a:sheetData", NS).findall("a:row", NS):
        values_by_index: dict[int, str] = {}
        for cell in row.findall("a:c", NS):
            ref = cell.attrib.get("r", "")
            col_ref = "".join(char for char in ref if char.isalpha())
            value_node = cell.find("a:v", NS)
            value = "" if value_node is None or value_node.text is None else value_node.text
            if cell.attrib.get("t") == "s" and value:
                value = shared_strings[int(value)]
            values_by_index[col_to_index(col_ref)] = value

        max_index = max(values_by_index) if values_by_index else -1
        rows.append([values_by_index.get(index, "") for index in range(max_index + 1)])
    return rows


def project_rows(raw_rows: list[list[str]], header_map: dict[str, str], columns: list[str]) -> list[dict[str, str]]:
    header = raw_rows[0]
    index_by_header = {name: index for index, name in enumerate(header)}
    required_headers = set(header_map)
    missing_headers = sorted(required_headers - set(index_by_header))
    if missing_headers:
        raise ValueError(f"Faltan encabezados esperados: {missing_headers}")

    projected: list[dict[str, str]] = []
    for sheet_row_number, row in enumerate(raw_rows[1:], start=2):
        record = {column: "" for column in columns}
        record["source_row_number"] = str(sheet_row_number)
        for header_name, column_name in header_map.items():
            idx = index_by_header[header_name]
            record[column_name] = row[idx].strip() if idx < len(row) else ""
        projected.append(record)
    return projected


def sql_literal(value: str) -> str:
    return "NULL" if value == "" else "'" + value.replace("'", "''") + "'"


def write_csv(path: Path, columns: list[str], records: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        writer.writerows(records)


def write_insert_chunks(path_prefix: str, table_name: str, columns: list[str], records: list[dict[str, str]]) -> list[str]:
    generated_files: list[str] = []
    insert_columns = ", ".join(columns)
    for start in range(0, len(records), CHUNK_SIZE):
        chunk = records[start : start + CHUNK_SIZE]
        chunk_number = (start // CHUNK_SIZE) + 1
        sql_path = OUTPUT_DIR / f"{path_prefix}_{chunk_number:03d}.sql"
        values_sql = ",\n".join(
            "(" + ", ".join(sql_literal(record[column]) for column in columns) + ")"
            for record in chunk
        )
        sql = (
            f"INSERT INTO {table_name} ({insert_columns})\n"
            f"VALUES\n{values_sql}\n"
            "ON CONFLICT (source_row_number) DO UPDATE SET\n"
            + ",\n".join(
                f"  {column} = EXCLUDED.{column}"
                for column in columns
                if column != "source_row_number"
            )
            + ";\n"
        )
        sql_path.write_text(sql, encoding="utf-8")
        generated_files.append(str(sql_path))
    return generated_files


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(WORKBOOK_PATH) as archive:
        shared_strings = load_shared_strings(archive)
        sheet_targets = workbook_sheet_targets(archive)

        students_rows = read_sheet_rows(archive, sheet_targets["Estudiantes"], shared_strings)
        guardians_rows = read_sheet_rows(archive, sheet_targets["Apoderados"], shared_strings)

    students_records = project_rows(students_rows, STUDENTS_HEADER_MAP, STUDENTS_COLUMNS)
    guardians_records = project_rows(guardians_rows, GUARDIANS_HEADER_MAP, GUARDIANS_COLUMNS)

    students_csv = OUTPUT_DIR / "14923_estudiantes_staging.csv"
    guardians_csv = OUTPUT_DIR / "14923_apoderados_staging.csv"
    write_csv(students_csv, STUDENTS_COLUMNS, students_records)
    write_csv(guardians_csv, GUARDIANS_COLUMNS, guardians_records)

    students_sql = write_insert_chunks(
        path_prefix="14923_estudiantes_staging_insert",
        table_name="staging.matricula_14923_estudiantes_raw",
        columns=STUDENTS_COLUMNS,
        records=students_records,
    )
    guardians_sql = write_insert_chunks(
        path_prefix="14923_apoderados_staging_insert",
        table_name="staging.matricula_14923_apoderados_raw",
        columns=GUARDIANS_COLUMNS,
        records=guardians_records,
    )

    summary = {
        "workbook": str(WORKBOOK_PATH),
        "output_dir": str(OUTPUT_DIR),
        "students_rows": len(students_records),
        "guardians_rows": len(guardians_records),
        "students_csv": str(students_csv),
        "guardians_csv": str(guardians_csv),
        "students_sql_files": students_sql,
        "guardians_sql_files": guardians_sql,
    }
    (OUTPUT_DIR / "14923_export_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()