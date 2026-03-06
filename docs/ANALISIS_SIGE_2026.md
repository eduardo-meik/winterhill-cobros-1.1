# Análisis SIGE 2026 — Colegio Winterhill

> **Fecha:** 2 de marzo de 2026  
> **Fuente:** `sige_2026.csv` (datos del Ministerio de Educación)  
> **Total registros:** 441 estudiantes  
> **Nota:** No se pudo contrastar con la base de datos del programa de matrícula (falta archivo `.env` con credenciales Supabase). El análisis se basa en el CSV y las observaciones del propio colegio registradas en la columna "OBSERVACION PROGRAMA".

---

## 1. Resumen General

| Indicador | Cantidad |
|---|---:|
| Total estudiantes SIGE | **441** |
| Duplicados por RUT | **0** |
| Inconsistencias de montos | **37** |
| Referencias a "draft" / "borrar" / datos de prueba | **27** |
| Sin matricular en programa | **50** |
| No admitidos | **1** |
| Prioritarios (exentos de pago) | **185** (42.0%) |
| Pagadores (pagaré/cheque/trans/tarjeta) | **201** (45.6%) |
| Con descuento explícito | **13** |
| Con descuento implícito (arancel < estándar) | **44** |
| Sin forma de pago registrada | **42** (9.5%) |
| Con 9 cuotas en vez de 10 (según obs.) | **24** |

---

## 2. Duplicados por RUT

**No se encontraron RUTs duplicados** en el archivo SIGE. Los 441 registros tienen RUT único.

Sin embargo, las observaciones del colegio mencionan **duplicados en el reporte del programa de matrícula**:

| RUT | Nombre | Curso | Observación |
|---|---|---|---|
| 26741815-2 | VALDÉS COVARRUBIAS SAMUEL SIMÓN | 2° Básico | APARECE DUPLICADO EN REPORTE Y CON 9 CUOTAS |
| 24473727-7 | VALDÉS COVARRUBIAS SANTIAGO | 7° Básico | APARECE DUPLICADO EN REPORTE Y CON 9 CUOTAS |
| 24373455-K | YÁÑEZ KOENIG LEÓN EMILIO | 7° Básico | DUPLICADO POR HNO / DEBE DECIR 10 CUOTAS |
| 23552329-9 | YÁÑEZ KOENIG CATALINA ANTONIA | 1 Medio -A | REPORTE SALE DUPLICADO POR HNO / DEBE DECIR 10 CUOTAS |
| 22501642-9 | MORAGA MENA ABEL IGNACIO | 4 Medio -A | INGRESADO DOS VECES AL PROGRAMA |

> **Nota:** Los Valdés Covarrubias y Yáñez Koenig probablemente aparecen duplicados en el programa porque comparten apoderado con hermanos. El caso de Moraga Mena es un ingreso duplicado real que debe corregirse.

---

## 3. Inconsistencias de Montos

### 3.1 Monto excesivamente alto (error de digitación)

| RUT | Nombre | Curso | Cuota | N° Cuotas | Anual | Arancel esperado | Problema |
|---|---|---|---:|---:|---:|---:|---|
| 25904278-K | CARRASCO SEPÚLVEDA CONSTANZA PAZ | 3° Básico-A | $1,202,870 | 10 | $12,028,700 | $1,028,700 | **Monto MAL INGRESADO** — 11.7x el arancel |

### 3.2 Monto anual sospechosamente bajo (error de formato)

| RUT | Nombre | Curso | Cuota | N° Cuotas | Anual | Problema |
|---|---|---|---:|---:|---:|---|
| 24958405-3 | ALBORNOZ MORGADO ANAÍS ILLARI | 7° Básico | 25.718 | 10 | **$257** | Debería ser $257,180 — mal parseado el separador de miles |

### 3.3 Estudiante de Media con arancel de Básica

| RUT | Nombre | Curso | Anual | Arancel Media | Problema |
|---|---|---|---:|---:|---|
| 22832796-4 | CARRASCO SEPÚLVEDA CRISTIAN ANDRÉS | 4 Medio -A | $1,028,700 | $1,331,260 | Paga arancel de Básica ($1,028,700) en vez de Media. **Verificar con pagaré** |

### 3.4 PRIORITARIO pero con monto de cuotas asignado

Estos estudiantes están marcados como "PRIORITARIO" (exentos) pero tienen montos ingresados en el programa. **Deben eliminarse las cuotas o cambiar la forma de pago.**

| RUT | Nombre | Curso | Cuota | Anual | Observación |
|---|---|---|---:|---:|---|
| 25924637-7 | BRIONES FIGUEROA HELENA MAILEN | 3° Básico-A | $102,870 | $1,028,700 | APARECE CON MONTO A PAGAR EN PROGRAMA |
| 26071660-3 | GALLARDO ROSS TRISTÁN ANDRÈ | 3° Básico-A | $102,870 | $1,028,700 | APARECE CON CUOTAS EN PROGRAMA |
| 25947700-K | JARAMILLO MORALES JOAQUÍN ALONZO | 3° Básico-A | $102,870 | $1,028,700 | APARECE COMO PRIORITARIO Y CON CUOTAS |
| 26057653-4 | SPIGETTH LABRIN ISIDORA IGNACIA | 3° Básico-A | $102,870 | $1,028,700 | APARECE COMO PRIORITARIO Y CON CUOTAS |
| 25764691-2 | ZOLEZZI HENRÍQUEZ RAFFAELLA V. | 3° Básico-A | $102,870 | $1,028,700 | APARECE COMO PRIORITARIO Y CON CUOTAS |
| 25890092-8 | FIGUEROA DONOSO ÁMBAR ALEJANDRA | 3° Básico-B | $102,870 | $1,028,700 | APARECE CON CUOTAS EN PROGRAMA |
| 25349901-K | SAN MARTÍN MONTERO NICOLÁS GAEL | 4° Básico-B | $102,870 | $1,028,700 | Aparece con cuotas y monto en programa |
| 23307488-8 | BÁEZ CONTRERAS ALEXIS ANDRÉS | 3 Medio -B | 106,501 | — | PRIORITARIO con monto de cuota sin anual |

### 3.5 Sin forma de pago pero con montos asignados

| RUT | Nombre | Curso | Cuota | Anual | Observación |
|---|---|---|---:|---:|---|
| 24386397-K | EGAÑA CABRERA ELENA FRANCISCA | 7° Básico | $102,870 | $1,028,700 | No aparece como matriculado — "draft" |
| 22918793-7 | OPAZO CABELLO RENATO ALONSO | 3 Medio -A | $133,126 | $1,331,260 | APARECE CON CHEQUES Y PAGARÉ |
| 23269629-K | BARRAZA MELO FRANCISCA IGNACIA | 3 Medio -B | 106,501 | $1,065,010 | CON PAGARÉ Y CHEQUES SIN DETALLAR |
| 22783399-8 | SOLÍS GÓMEZ MAGDALENA BEATRIZ | 4 Medio -A | $133,126 | $1,331,260 | Aparece con cheques y pagaré. INCLUIR NOMBRE SOCIAL |

### 3.6 Forma de pago pero sin monto

| RUT | Nombre | Curso | Pago | Problema |
|---|---|---|---|---|
| 24171839-5 | LOYOLA GRONDONA BASTIÁN A. | 8° Básico | PAGARÉ | PAGARÉ sin monto asociado |
| 25686131-3 | VEGA PLAZA PASCAL ALUDY | 4° Básico-B | CHEQUE | CHEQUE sin monto — "DRAFT" |

### 3.7 Solo 1 cuota (posibles errores o pagos completos)

| RUT | Nombre | Curso | Pago | Cuota | Anual | Observación |
|---|---|---|---|---:|---:|---|
| 25840798-9 | LASNIER FIGUEROA THOMAS V. | 3° Básico-B | PAGARÉ | $1,028,700 | $1,028,700 | 1 cuota = anual completo. No matriculado "draft" |
| 23699034-6 | VICUÑA PÉREZ MIGUEL ESTEBAN | 1 Medio -A | CHEQUE | $1,331,260 | $1,331,260 | 1 cheque por el total |
| 23613517-9 | CASTRO CORREA MATÍAS ANKATU | 2 Medio | CHEQUE | $1,331,260 | $1,331,260 | Dice 1 cheque pero obs. dice 8 cuotas |

### 3.8 Cuotas en 5 (familia Arenas Landeros — pagaré x $217,036)

| RUT | Nombre | Curso | Cuota | N° Cuotas | Anual | Obs. |
|---|---|---|---:|---:|---:|---|
| 27245224-5 | ARENAS LANDEROS ELOÍSA IZADI | 1° Básico | $205,740 | 5 | $1,028,700 | Pagaré x 217036 en programa |
| 25658625-8 | ARENAS LANDEROS DANTE LEÓN | 4° Básico-B | $205,740 | 5 | $1,028,700 | Pagaré x 217036 en programa |
| 23882043-K | ARENAS LANDEROS OCTAVIO ANDRÉS | 1 Medio -A | $266,252 | 5 | $1,331,260 | Pagaré x 217036 en programa |

> Familia con acuerdo especial de 5 cuotas. Los montos cuadran al anual. Verificar que el pagaré refleje $217,036.

### 3.9 Cuota sin formato $ (inconsistencia de formato)

Se encontraron **12 registros** donde la cuota no incluye el signo `$`:

| RUT | Nombre | Curso | Cuota (raw) |
|---|---|---|---|
| 24609631-7 | ALLENDE TABILO IGNACIO JAVIER | 5° Básico | 72,009 |
| 25230505-K | MUÑOZ NAVARRO EMILIA JOSEFA | 5° Básico | 36,005 |
| 25178753-0 | VEAS ASPILLAGA AMARANTA ROSA | 5° Básico | 51,435 |
| 24587195-3 | ARANA CALDERÓN FRANCO AUGUSTO | 6° Básico | 25,718 |
| 24958405-3 | ALBORNOZ MORGADO ANAÍS ILLARI | 7° Básico | 25.718 |
| 24557181-K | GALLARDO ARROYO MATEO JULIÁN | 7° Básico | 72,009 |
| 25581814-9 | MALLEA DÍAZ LUA ABRIL | 7° Básico | 25,718 |
| 23691703-7 | NAVARRO RIVEROS ROBERT KLAUS | 1 Medio -A | 106,501 |
| 23443471-3 | SALINAS VÉLIZ AMANDA FRANCISCA | 2 Medio | 147,918 |
| 22921315-6 | HERRERA CARRASCO JULIETA | 3 Medio -A | 106,501 |
| 23255578-5 | CISTERNAS ESPINOZA JOSEFA A. | 3 Medio -B | 93,188 |
| 23082366-9 | LERIS MUÑOZ JOSEPHINA PAZ | 3 Medio -B | 93,188 |
| 23219047-7 | MIRANDA ÁLVAREZ DAMIÁN IGNACIO | 3 Medio -B | 190,180 |
| 22941028-8 | GONZÁLEZ MORA JOAQUÍN AMARO | 4 Medio -A | 93,188 |
| 23269629-K | BARRAZA MELO FRANCISCA IGNACIA | 3 Medio -B | 106,501 |
| 23307488-8 | BÁEZ CONTRERAS ALEXIS ANDRÉS | 3 Medio -B | 106,501 |

---

## 4. Referencias a "Draft", "Borrar" y Datos de Prueba

Se encontraron **27 registros** con referencias a estados de prueba en las observaciones. Ningún nombre de estudiante contiene "test" o "prueba" — los datos corresponden a estudiantes reales con matrículas incompletas o en estado borrador.

### 4.1 Matrículas en estado "DRAFT" (borrador) en el programa

| RUT | Nombre | Curso | Pago | Observación |
|---|---|---|---|---|
| 25810408-0 | MEDINA SEPÚLVEDA DANTE VELKAN | 3° Básico-A | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 25869579-8 | CORTÉS BASCUÑÁN PAZ MIA | 3° Básico-B | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 25964135-7 | CUADRO CÁRCAMO FACUNDO GASPAR | 3° Básico-B | PAGARÉ | NO aparece como matriculado en programa "draft" |
| 25873333-9 | GONZÁLEZ CASTRO GASPAR ALONSO | 3° Básico-B | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 25840798-9 | LASNIER FIGUEROA THOMAS VALENTÍN | 3° Básico-B | PAGARÉ | NO aparece como matriculado en programa "draft". CON PAGARÉ Y 1 CUOTA |
| 25830620-1 | PEÑAFIEL ALVARADO SILVIO DARÍO | 3° Básico-B | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 26129705-1 | RIQUELME MONSALVES RAFAELA F. | 3° Básico-B | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 26191736-K | ROJAS PUGAS ENYA FENRIR | 3° Básico-B | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 25852711-9 | ZAPATA VIDELA GASPAR ARTURO | 3° Básico-B | — | SIN MATRÍCULA SIN DATOS DE PAGO "DRAFT" |
| 25511928-1 | ALARCÓN OYARZÚN AYLIN MAITE E. | 4° Básico-A | PAGARÉ | APARECE COMO "drat" CON CHEQUE Y TRANSFERENCIA |
| 25495456-K | CASTILLO BUSTAMANTE DANTE ARITZ | 4° Básico-A | PAGARÉ | APARECE COMO "drat" CON PAGARÉ Y TRANSFERENCIA |
| 25606891-5 | UBERUAGA CAJALES MARTÍN | 4° Básico-B | DESCUENTO | APARECE EN "DRAFT" |
| 25686131-3 | VEGA PLAZA PASCAL ALUDY | 4° Básico-B | CHEQUE | APARECE EN "DRAFT" CON CHEQUES SIN INGRESAR |
| 24900633-5 | CANDIA ROJAS LAUTARO | 5° Básico | PRIORITARIO | APARECE EN "DRAFT" |
| 24822697-8 | CARVAJAL PUYOL MARIANO IGNACIO | 5° Básico | PAGARÉ | APARECE EN "DRAFT" |
| 24687493-K | CUADRO CÁRCAMO MATILDA ESPERANZA | 6° Básico | PAGARÉ | NO aparece como matriculado en programa "draft" |
| 24705100-7 | DÍAZ NOVOA LAURA RENATA | 6° Básico | CHEQUE | NO aparece como matriculado en programa "draft" |
| 24402364-9 | DUQUE PUGAS ALMA | 7° Básico | PRIORITARIO | NO aparece como matriculado en programa "draft" |
| 24386397-K | EGAÑA CABRERA ELENA FRANCISCA | 7° Básico | — | NO aparece como matriculado en programa "draft" |
| 24105774-7 | ALLENDE TABILO SOFÍA ANTONELLA | 8° Básico | PRIORITARIO | EN "DRAFT" |
| 23937301-1 | ESCOBAR CEBALLO AGUSTINA J. | 8° Básico | TARJETA | EN "DRAFT" |
| 24223389-1 | SEREY PÉREZ GASPAR ALONSO | 8° Básico | PRIORITARIO | EN "DRAFT" |
| 23847613-5 | GONZÁLEZ KIMER AURORA MAGDALENA | 1 Medio -A | CHEQUE | EN "DRAFT" |
| 23705014-2 | EGAÑA CABRERA MÁXIMO LEONIDAS | 1 Medio -B | — | APARECE MATRICULADO "draft" SIN CERTIFICADO NI PAGARÉ |
| 26476798-9 | FEREDA GUTIERREZ DAVIAN E. | 1 Medio -B | — | APARECE MATRICULADO "draft" SIN CERTIFICADO NI PAGARÉ |

### 4.2 Solicitudes de "BORRAR CUOTAS"

| RUT | Nombre | Curso | Pago |
|---|---|---|---|
| 27183790-9 | PEÑA LÓPEZ ISAAC GAEL | 1° Básico | PRIORITARIO |
| 27184747-5 | VALDÉS MATURANA RODRIGO LEÓN | 1° Básico | PRIORITARIO |

> Estos son prioritarios a los que erróneamente se les generaron cuotas. Deben limpiarse en la base de datos.

---

## 5. Formas de Pago

### 5.1 Distribución general

| Forma de Pago | Cantidad | % del Total |
|---|---:|---:|
| PRIORITARIO | 185 | 42.0% |
| PAGARÉ | 154 | 34.9% |
| SIN FORMA DE PAGO | 42 | 9.5% |
| CHEQUE | 31 | 7.0% |
| DESCUENTO | 12 | 2.7% |
| TRANSFERENCIA | 12 | 2.7% |
| TARJETA | 4 | 0.9% |
| BECA | 1 | 0.2% |

### 5.2 Pagos con Tarjeta (pago único)

| RUT | Nombre | Curso | Monto |
|---|---|---|---:|
| 23937301-1 | ESCOBAR CEBALLO AGUSTINA J. | 8° Básico | $720,090 |
| 23256719-8 | AGUIRRE CRUZ THEO | 3 Medio -A | $1,331,260 |
| 23200888-1 | AGUILAR BROUSSAIN FACUNDO | 3 Medio -B | $1,331,260 |
| 22559294-2 | CARVAJAL GUAJARDO LEONOR CAROLINA | 4 Medio -A | $1,331,260 |

> **Alerta:** CARVAJAL GUAJARDO aparece con 10 pagos de $1,331,260 en el reporte (obs.) — posible error de $13.3M total.

### 5.3 Beca

| RUT | Nombre | Curso | Monto |
|---|---|---|---:|
| 23126375-6 | BARRÍA ZÁRRAGA ARIEL EMILIO | 3 Medio -A | $0 |

> Aparece con pago en reporte pero con beca en programa. **Verificar cuál es correcto.**

### 5.4 Observaciones con formas de pago múltiple

| RUT | Nombre | Curso | Pago Registrado | Observación |
|---|---|---|---|---|
| 25761339-9 | NAVARRO AVILÉS ANTONELLA PAZ | 3° Básico-A | CHEQUE | Seleccionado CHEQUE y TRANSFERENCIA |
| 25917951-3 | MUÑOZ MENDES NAHUEL G. | 3° Básico-A | PAGARÉ | Seleccionado transferencia y pagaré |
| 25832054-9 | PUEBLA MORENO ELEONORA | 3° Básico-A | PAGARÉ | Seleccionado transferencia y pagaré |
| 25924270-3 | SALINAS CARRASCO VICENTE S. | 3° Básico-A | PAGARÉ | Seleccionado transferencia y pagaré |
| 25554250-8 | ARAOS VERGARA FRANCESCO A. | 3° Básico-B | PAGARÉ | Seleccionado transferencia y pagaré |
| 25262916-5 | AYALA AGUILERA RENATO SAMUEL | 4° Básico-B | PAGARÉ | CON PAGARÉ Y TRANSFERENCIA |
| 22918793-7 | OPAZO CABELLO RENATO ALONSO | 3 Medio -A | — | APARECE CON CHEQUES Y PAGARÉ |
| 23704392-8 | VIDAL SÁNCHEZ FERNANDA EMILIA | 1 Medio -A | TRANSFERENCIA | Aparece con cheque Y transferencia |
| 23040665-0 | CARVAJAL GUTIÉRREZ DANAE A. | 4 Medio -B | CHEQUE | APARECEN CHEQUES Y PAGARÉ |

---

## 6. Prioritarios

**185 estudiantes (42.0%)** están marcados como PRIORITARIOS (exentos de copago por vulnerabilidad socioeconómica).

### 6.1 Resumen por curso

| Curso | Total | Prioritarios | % Prioritarios |
|---|---:|---:|---:|
| 1° Básico | 25 | 11 | 44.0% |
| 2° Básico | 26 | 14 | 53.8% |
| 3° Básico-A | 25 | 10 | 40.0% |
| 3° Básico-B | 21 | 13 | 61.9% |
| 4° Básico-A | 26 | 12 | 46.2% |
| 4° Básico-B | 22 | 10 | 45.5% |
| 5° Básico | 25 | 9 | 36.0% |
| 6° Básico | 26 | 13 | 50.0% |
| 7° Básico | 25 | 4 | 16.0% |
| 8° Básico | 29 | 15 | 51.7% |
| 1 Medio -A | 26 | 6 | 23.1% |
| 1 Medio -B | 26 | 15 | 57.7% |
| 2 Medio | 29 | 7 | 24.1% |
| 3 Medio -A | 25 | 11 | 44.0% |
| 3 Medio -B | 25 | 12 | 48.0% |
| 4 Medio -A | 33 | 15 | 45.5% |
| 4 Medio -B | 27 | 8 | 29.6% |

### 6.2 Prioritarios con cuotas erróneas (acción requerida)

Los 8 casos de la sección 3.4 requieren **limpieza de cuotas** en el programa de matrícula.

---

## 7. Descuentos

### 7.1 Descuentos explícitos (marcados como "DESCUENTO" o "BECA")

| RUT | Nombre | Curso | Cuota | N° Cuotas | Anual | % Desc. |
|---|---|---|---:|---:|---:|---:|
| 26757037-K | ROJAS VACCARO ANOUK TABARÉ | 1° Básico | $36,005 | 10 | $360,050 | 65% |
| 26657060-0 | BERROCAL ROA ISIDORA ALINE | 2° Básico | $25,718 | 10 | $257,180 | 75% |
| 25969885-5 | LABRÍN MUÑOZ SANDINO TAHIEL | 3° Básico-A | $30,861 | 10 | $308,610 | 70% |
| 25033387-0 | JIMÉNEZ ACUÑA ALLAN ALEJANDRO | 3° Básico-B | $25,718 | 10 | $257,180 | 75% |
| 25558118-K | CANCINO TAPIA TOMÁS LEÓN | 4° Básico-B | $36,005 | 10 | $360,050 | 65% |
| 25606891-5 | UBERUAGA CAJALES MARTÍN | 4° Básico-B | $36,005 | 10 | $360,050 | 65% |
| 25304357-1 | MARTÍNEZ PÉREZ MAILEN PAZ | 5° Básico | $25,718 | 10 | $257,180 | 75% |
| 25230505-K | MUÑOZ NAVARRO EMILIA JOSEFA | 5° Básico | 36,005 | 10 | $360,050 | 65% |
| 24587195-3 | ARANA CALDERÓN FRANCO AUGUSTO | 6° Básico | 25,718 | 10 | $257,180 | 75% |
| 24958405-3 | ALBORNOZ MORGADO ANAÍS ILLARI | 7° Básico | 25.718 | 10 | **$257** ⚠️ | ~100% ⚠️ |
| 24581814-9 | MALLEA DÍAZ LUA ABRIL | 7° Básico | 25,718 | 10 | $257,180 | 75% |
| 24315417-0 | MARTÍNEZ PÉREZ RAFAEL ALONSO | 7° Básico | $25,718 | 10 | $257,180 | 75% |
| 23126375-6 | BARRÍA ZÁRRAGA ARIEL EMILIO | 3 Medio -A | $0 | 0 | $0 | 100% (BECA) |

> ⚠️ ALBORNOZ MORGADO: El monto anual dice $257 en vez de $257,180. **Error de formato — corregir.**

### 7.2 Descuentos implícitos (arancel menor al estándar, no marcados como "DESCUENTO")

Se encontraron **44 estudiantes** pagando menos del arancel estándar sin estar explícitamente marcados como descuento:

| % Desc. | Arancel Básica ($1,028,700) | Arancel Media ($1,331,260) |
|---:|---:|---:|
| 10% | 5 estudiantes | — |
| 20% | 3 estudiantes | 4 estudiantes |
| 24.1% | 1 estudiante | — |
| 30% | 2 estudiantes | 3 estudiantes |
| 35% | — | 1 estudiante |
| 40% | 5 estudiantes | 7 estudiantes |
| 50% | 2 estudiantes | — |
| 60% | 2 estudiantes | 3 estudiantes |

#### Detalle de los descuentos implícitos más significativos (≥ 40%)

| RUT | Nombre | Curso | Pago | Anual | Arancel | % Desc. |
|---|---|---|---|---:|---:|---:|
| 26297890-7 | RAMÍREZ ACEVEDO JULIÁN EDUARDO | 2° Básico | PAGARÉ | $411,480 | $1,028,700 | 60% |
| 26340647-8 | PIÑONES RAMÍREZ AUKAN AMARU | 2° Básico | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 25353074-K | MATURANA DÍAZ STEFFANO JÓAN | 4° Básico-A | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 25713058-4 | RUBINA STRAUBE MAE AMÉLIE | 4° Básico-A | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 25262916-5 | AYALA AGUILERA RENATO SAMUEL | 4° Básico-B | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 25067339-6 | PIÑA BOMBAL SEBASTIÁN HERNÁN | 5° Básico | PAGARÉ | $514,350 | $1,028,700 | 50% |
| 25178753-0 | VEAS ASPILLAGA AMARANTA ROSA | 5° Básico | PAGARÉ | $514,350 | $1,028,700 | 50% |
| 25232702-9 | VARGAS ARAVENA ELOÍSA | 5° Básico | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 24245393-K | CEPEDA FOXON AYÜN | 7° Básico | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 24557067-8 | RAMÍREZ ACEVEDO ANTONIO LEÓN | 7° Básico | PAGARÉ | $411,480 | $1,028,700 | 60% |
| 24133380-9 | PEIRANO CARVAJAL FLORENCIA P. | 8° Básico | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 23942270-5 | ZAVALA SALUCCI FELIPE ALEJANDRO | 8° Básico | PAGARÉ | $617,220 | $1,028,700 | 40% |
| 23681990-6 | AMOR ABURTO VICENTE ALONSO | 1 Medio -B | PAGARÉ | $532,500 | $1,331,260 | 60% |
| 23450299-9 | ÁVILA TELLO RENATA RAYEN | 2 Medio | PAGARÉ | $798,760 | $1,331,260 | 40% |
| 23378477-K | DÍAZ CALBULLANCA CRISTÓBAL A. | 2 Medio | PAGARÉ | $798,760 | $1,331,260 | 40% |
| 23337628-0 | ROMANI GUTIÉRREZ CRISTÓBAL LEÓN | 2 Medio | PAGARÉ | $798,760 | $1,331,260 | 40% |
| 23341445-K | SEGURA PEZO ISIDORA VALENTINA | 2 Medio | PAGARÉ | $798,760 | $1,331,260 | 40% |
| 23251268-7 | VARGAS ARAVENA ROMÁN | 3 Medio -B | PAGARÉ | $798,760 | $1,331,260 | 40% |
| 23277432-0 | WILSON CÁRCAMO ALONSO MARTÍN | 3 Medio -B | PAGARÉ | $532,500 | $1,331,260 | 60% |
| 22961936-5 | AMOR ABURTO FRANCISCO JAVIER | 4 Medio -A | PAGARÉ | $532,500 | $1,331,260 | 60% |
| 22878786-8 | RODRÍGUEZ ABURTO JOSEFA RENATA | 4 Medio -A | PAGARÉ | $798,760 | $1,331,260 | 40% |

> Los hermanos AMOR ABURTO (60% desc. ambos), RAMÍREZ ACEVEDO (60% desc. ambos), y hermanos VARGAS ARAVENA (40% desc. ambos) mantienen descuentos consistentes entre ellos.

---

## 8. Sin Matricular en el Programa

**50 estudiantes** aparecen en SIGE pero sin matrícula completa (incluye sin datos de pago y menciones explícitas de "sin matricular"):

### 8.1 Explícitamente "SIN MATRICULAR" (29 casos)

| RUT | Nombre | Curso | Observación |
|---|---|---|---|
| 27249739-7 | CANALES GODOY SANTIAGO ALEJANDRO | 1° Básico | SIN MATRICULAR — BARBARA BRIONES |
| 26838566-5 | GODOY DIDIER SALVADOR GASPAR | 1° Básico | SIN MATRICULAR, SOLO SU HERMANA |
| 27067010-5 | MUÑOZ CARVAJAL RENATO AUGUSTO | 1° Básico | SIN MATRICULAR |
| 25767658-7 | ESPINOZA CORNEJO SALVADOR EMILIANO | 3° Básico-A | No aparece matriculado, SOLO SU HERMANA |
| 25810408-0 | MEDINA SEPÚLVEDA DANTE VELKAN | 3° Básico-A | NO aparece como matriculado — "draft" |
| 25869579-8 | CORTÉS BASCUÑÁN PAZ MIA | 3° Básico-B | NO aparece como matriculado — "draft" |
| 25964135-7 | CUADRO CÁRCAMO FACUNDO GASPAR | 3° Básico-B | NO aparece como matriculado — "draft" |
| 25873333-9 | GONZÁLEZ CASTRO GASPAR ALONSO | 3° Básico-B | NO aparece como matriculado — "draft" |
| 25840798-9 | LASNIER FIGUEROA THOMAS VALENTÍN | 3° Básico-B | NO aparece como matriculado — "draft" |
| 25830620-1 | PEÑAFIEL ALVARADO SILVIO DARÍO | 3° Básico-B | NO aparece como matriculado — "draft" |
| 26129705-1 | RIQUELME MONSALVES RAFAELA F. | 3° Básico-B | NO aparece como matriculado — "draft" |
| 26191736-K | ROJAS PUGAS ENYA FENRIR | 3° Básico-B | NO aparece como matriculado — "draft" |
| 25852711-9 | ZAPATA VIDELA GASPAR ARTURO | 3° Básico-B | SIN MATRÍCULA SIN DATOS DE PAGO "DRAFT" |
| 25404838-0 | TAPIA ROJAS INARA | 4° Básico-A | SIN MATRICULAR |
| 25605450-7 | AVDALOV SAGREDO BRISA OLIVIA | 4° Básico-B | SIN MATRICULAR |
| 25300537-8 | ALARCÓN HUERTA LETICIA COLOMBA | 5° Básico | SIN MATRICULAR |
| 25125189-4 | AVENDAÑO LUNA SOFÍA ELIZABETH | 5° Básico | SIN MATRICULAR |
| 25109214-1 | LÓPEZ GONZÁLEZ JAVIERA EMILIA | 5° Básico | SIN MATRICULAR. SIN REGISTRO DE FORMA DE PAGO |
| 25168497-9 | MANCILLA GALLARDO LAUTARO | 5° Básico | NO APARECE MATRICULADO, SOLO SU HERMANA |
| 24687493-K | CUADRO CÁRCAMO MATILDA ESPERANZA | 6° Básico | NO aparece como matriculado — "draft" |
| 24705100-7 | DÍAZ NOVOA LAURA RENATA | 6° Básico | NO aparece como matriculado — "draft" |
| 24831872-4 | MERCADO FIGUEROA PEDRO SEBASTIÁN | 6° Básico | SIN MATRICULAR NI FORMA DE PAGO |
| 24704324-1 | MIRANDA ZAMORANO MATEO AMARO | 6° Básico | SIN MATRICULAR sin apoderado NI FORMA DE PAGO |
| 24402364-9 | DUQUE PUGAS ALMA | 7° Básico | NO aparece como matriculado — "draft" |
| 24386397-K | EGAÑA CABRERA ELENA FRANCISCA | 7° Básico | NO aparece como matriculado — "draft" |
| 24569213-7 | RALLÍN SALAZAR ISIDORA BEATRIZ | 7° Básico | Aparece matriculado — SIN APODERADO NI FORMA PAGO |
| 24113987-5 | SALAZAR ORBENES ISABELLA ANTONIA | 8° Básico | APARECE MATRICULADA SIN MATRICULAR. SIN APODERADO |
| 24074294-2 | TAPIA VÁSQUEZ MARTÍN ALIRO | 8° Básico | NO APARECE MATRICULADO EN PROGRAMA |
| 23882519-9 | MIRANDA ZAMORANO BENJAMÍN OCTAVIO | 1 Medio -A | SIN MATRICULAR. MATÍAS MALDONADO MIRANDA |
| 23111722-9 | AROS BRIONES GASPAR ALONSO | 3 Medio -A | NO APARECE MATRICULADO |
| 22514762-0 | PIZARRO CABELLO VLADYMIR IGNACIO | 4 Medio -B | NO HAY REGISTRO DE MATRÍCULA |

### 8.2 No admitido

| RUT | Nombre | Curso |
|---|---|---|
| 29030419-9 | TERUEL FLORENCIA AYALÉN | 3° Básico-B |

> Esta estudiante está marcada como **"NUEVO NO ADMITIDO"**. No debería estar en el sistema.

---

## 9. Alerta: 9 Cuotas en vez de 10

**24 estudiantes** tienen observaciones indicando que en el reporte del programa aparecen con 9 cuotas en vez de 10. Esto puede significar pérdida de ingresos si no se corrige:

| RUT | Nombre | Curso |
|---|---|---|
| 26793920-9 | KARMY ELTIT IAN SALVADOR | 1° Básico |
| 27233231-2 | NIELSEN FLORES FARID RODRIGO | 1° Básico |
| 26863472-K | PIÑA BOMBAL MAXIMILIANO VICENTE | 1° Básico |
| 26116316-0 | CARRILLO BRIONES SANTIAGO ALONSO | 2° Básico |
| 26211725-1 | MATTIA PAZ SANTIAGO | 2° Básico |
| 26741815-2 | VALDÉS COVARRUBIAS SAMUEL SIMÓN | 2° Básico |
| 26128305-0 | AVENDAÑO LUNA LAURA ANTONIA | 3° Básico-A |
| 25479463-5 | FLORES MUÑOZ SIMONE ANTONIA | 3° Básico-A |
| 25723210-7 | KARMY ELTIT ÓLIVER VALENTÍN | 3° Básico-A |
| 25969885-5 | LABRÍN MUÑOZ SANDINO TAHIEL | 3° Básico-A |
| 25943041-0 | MENDOZA DAZA GASPAR | 3° Básico-A |
| 25821721-7 | MIRANDA MADARIAGA JOAQUÍN ALONSO | 3° Básico-A |
| 25607211-4 | CANTARUTTI CONCHA GIULIANO A. | 4° Básico-A |
| 25412424-9 | MORALES RAMÍREZ IGNACIA EMILIA | 4° Básico-A |
| 25589136-7 | MUÑOZ ARIAS ISABELLA VIOLETA | 4° Básico-B |
| 25067339-6 | PIÑA BOMBAL SEBASTIÁN HERNÁN | 5° Básico |
| 24625627-6 | SILVA ACEVEDO MATILDA CELESTE | 6° Básico |
| 24473727-7 | VALDÉS COVARRUBIAS SANTIAGO | 7° Básico |
| 24373455-K | YÁÑEZ KOENIG LEÓN EMILIO | 7° Básico |
| 23552329-9 | YÁÑEZ KOENIG CATALINA ANTONIA | 1 Medio -A |
| 23884967-5 | REVECO PÉREZ LEÓN | 1 Medio -B |
| 23381582-9 | SCHULZ GALLEGUILLOS SOFIA V.M. | 2 Medio |
| 23252188-0 | FUNES GARVISO FLORENCIA ANTONIA | 3 Medio -A |
| 22994477-0 | ORTIZ MOLINA AGUSTÍN | 4 Medio -A |
| 22862722-4 | PERALTA ROJAS EMILIA IGNACIA | 4 Medio -B |

---

## 10. Resumen por Curso

| Curso | Total | Prioritarios | Pagadores | Sin Dato/Pago | % Prio |
|---|---:|---:|---:|---:|---:|
| 1° Básico | 25 | 11 | 11 | 3 | 44.0% |
| 2° Básico | 26 | 14 | 12 | 0 | 53.8% |
| 3° Básico-A | 25 | 10 | 14 | 1 | 40.0% |
| 3° Básico-B | 21 | 13 | 6 | 2 | 61.9% |
| 4° Básico-A | 26 | 12 | 13 | 1 | 46.2% |
| 4° Básico-B | 22 | 10 | 11 | 1 | 45.5% |
| 5° Básico | 25 | 9 | 12 | 4 | 36.0% |
| 6° Básico | 26 | 13 | 9 | 4 | 50.0% |
| 7° Básico | 25 | 4 | 19 | 2 | 16.0% |
| 8° Básico | 29 | 15 | 11 | 3 | 51.7% |
| 1 Medio -A | 26 | 6 | 18 | 2 | 23.1% |
| 1 Medio -B | 26 | 15 | 7 | 4 | 57.7% |
| 2 Medio | 29 | 7 | 18 | 4 | 24.1% |
| 3 Medio -A | 25 | 11 | 12 | 2 | 44.0% |
| 3 Medio -B | 25 | 12 | 11 | 2 | 48.0% |
| 4 Medio -A | 33 | 15 | 13 | 5 | 45.5% |
| 4 Medio -B | 27 | 8 | 17 | 2 | 29.6% |
| **TOTALES** | **441** | **185** | **214** | **42** | **42.0%** |

---

## 11. Acciones Requeridas (prioridad)

### Críticas (afectan facturación)
1. **Corregir monto CARRASCO SEPÚLVEDA CONSTANZA PAZ** (3° Básico-A): $12,028,700 → $1,028,700
2. **Corregir monto ALBORNOZ MORGADO ANAÍS ILLARI** (7° Básico): $257 → $257,180
3. **Verificar 24 estudiantes con 9 cuotas** en vez de 10 — posible cuota faltante
4. **Verificar CARRASCO SEPÚLVEDA CRISTIAN ANDRÉS** (4 Medio): paga arancel Básica en vez de Media
5. **Verificar CARVAJAL GUAJARDO LEONOR CAROLINA** (4 Medio): posible error de 10x$1.3M con tarjeta

### Importantes (limpiar datos)
6. **Eliminar cuotas de 8 prioritarios** que las tienen erróneamente
7. **Finalizar 27 matrículas en "draft"** o eliminar registros incompletos
8. **Completar forma de pago de 42 estudiantes** sin datos
9. **Eliminar a TERUEL FLORENCIA AYALÉN** (no admitido)
10. **Eliminar duplicado MORAGA MENA ABEL IGNACIO** (ingresado 2 veces)

### Menores (formato y datos)
11. Normalizar formato de cuotas sin signo `$` (16 registros)
12. Rectificar apellidos invertidos de apoderados (CACES SEPÚLVEDA)
13. Registrar nombres sociales donde aplique (4 casos mencionados)
14. Verificar descuentos implícitos sin % registrado en programa (~44 casos)
