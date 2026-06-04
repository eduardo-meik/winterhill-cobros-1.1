# Informe de Cruce SIGE 2026 vs Base de Datos

**Fecha:** 2026-03-06  
**Fuente oficial:** `sige_2026.csv` (441 estudiantes, 17 cursos)  
**Base de datos:** 517 estudiantes totales

---

## Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| Estudiantes en lista oficial SIGE 2026 | 441 |
| Estudiantes en BD (total) | 517 |
| Estudiantes BD en cursos 2025 | 456 |
| Estudiantes BD en cursos 2026 | 39 |
| Estudiantes BD en cursos 2024 (residual) | 22 |
| RUNs oficiales no encontrados en BD (total) | 6 |
| → Verdaderamente faltantes | 1 |
| → Con RUN incorrecto en BD | 5 |
| Estudiantes ACTIVO en BD no en lista oficial | ~78 |
| → Egresados 4° Medio 2025 (esperado) | ~30 |
| → Registros duplicados con RUN truncado | ~7 |
| → Posibles retiros/traslados | ~39 |
| Estudiantes con estructura de nombre incorrecta | ~60 |

---

## 1. Estudiantes Oficiales NO Encontrados en BD (6)

### 1.1 Verdaderamente faltante (1)

| RUN oficial | Nombre oficial | Curso 2026 | Observación SIGE |
|-------------|---------------|------------|------------------|
| 27.067.010-5 | MUÑOZ CARVAJAL RENATO AUGUSTO | 1° Básico | SIN MATRICULAR |

### 1.2 Presentes en BD pero con RUN incorrecto (5)

| RUN oficial | Nombre oficial | Curso 2026 | RUN actual BD | Problema |
|-------------|---------------|------------|---------------|----------|
| 26.920.280-**7** | SEPÚLVEDA BRAVO DIEGO VALENTÍN | 1° Básico | 26.920.280-**1** | Dígito verificador incorrecto + typo "VALETÍN" |
| 26.757.037-K | ROJAS VACCARO ANOUK TABARÉ | 1° Básico | 99.999.999-9 | RUN ficticio |
| 25.479.463-5 | FLORES MUÑOZ SIMONE ANTONIA | 3° Básico-A | 2.547.943-5 | RUN truncado/malformado |
| 29.030.419-9 | TERUEL FLORENCIA AYALÉN | 3° Básico-B | 100.589.843-5 | RUN ficticio; SIGE dice "NUEVO NO ADMITIDO" |
| 24.254.730-6 | PONCE LABARCA AINHOA BELÉN | 8° Básico | 2.454.730-6 | RUN truncado/malformado |

---

## 2. Registros Duplicados con RUN Truncado (eliminar duplicados)

Estos son registros que tienen un RUN truncado Y existe otro registro con el RUN correcto para el mismo estudiante:

| RUN truncado (eliminar) | RUN correcto (mantener) | Nombre | Curso 2025 |
|------------------------|------------------------|--------|------------|
| 2.397.907-3 | 23.097.907-3 | ARAYA CORTÉS ANTONELLA | 2° MEDIO B |
| 2.250.142-9 | 22.501.642-9 | MORAGA MENA ABEL IGNACIO | 3° MEDIO A |
| 2.504.174-0 | 25.041.974-0 | THOMAS BASAURE FRANCO ALLEN | 4° BASICO A |
| 2.712.604-7 | 27.126.104-7* | AQUEVEQUE SOLANO FACUNDO | 1° BASICO |
| 2.292.942-2 | — | "Pendiente" CARVAJAL GUAJARDO | 4° MEDIO A (dato de prueba) |

*\*Verificar RUN correcto*

> **Nota:** Los RUNs `2.547.943-5` y `2.454.730-6` NO son duplicados — son los únicos registros de esos estudiantes y necesitan **corrección de RUN** (ver sección 1.2).

---

## 3. Egresados 4° Medio 2025 (~30 estudiantes)

Estudiantes en `4° MEDIO A` año 2025 que **no aparecen en la lista SIGE 2026**. Esto es **esperado** ya que egresan:

| RUN | Nombre | Estado |
|-----|--------|--------|
| 22.553.082-3 | ARANA CALDERÓN LUCAS FEINALDO | ACTIVO |
| 22.656.288-5 | AROS BRIONES LUCÍA AMPARO | ACTIVO |
| 22.695.195-4 | ARRIAGADA CORTÉS BENITO EDUARDO | ACTIVO |
| 22.419.562-1 | BANDA BASTÍAS AZKINTU ALEJANDRO | ACTIVO |
| 22.708.810-9 | CAÑÓN BERNOFF TOMÁS SALVADOR | ACTIVO |
| 22.684.749-9 | CANSECO CÁRCAMO VALENTINA ANTONELLA | ACTIVO |
| 22.559.294-2 | CARVAJAL GUAJARDO LEONOR CAROLINA | ACTIVO |
| 22.585.803-9 | CONTRERAS ESTAY VIOLETA ABRIL | ACTIVO |
| 22.269.017-K | CRESPO SARMIENTO AMARO ANTONIO | ACTIVO |
| 22.269.021-8 | CRESPO SARMIENTO BELÉN NATALIA | ACTIVO |
| 22.269.011-0 | CRESPO SARMIENTO EMMA PAZ | ACTIVO |
| 22.684.772-3 | DÍAZ FUENZALIDA PABLO ANDRÉS | ACTIVO |
| 22.746.402-K | FERRER CÉSPEDES MICAELA ANTONIA | ACTIVO |
| 22.665.241-8 | GATICA OSORIO FERNANDA ANAHIS | ACTIVO |
| 22.533.775-6 | GUZMAN TORRES RENATA CONSTANZA | ACTIVO |
| 22.546.944-K | MANRÍQUEZ MENDOZA VICENTE TOMÁS | ACTIVO |
| 22.558.548-2 | MARDONES LESPINASSE MARTÍN IGNACIO SAMIR | ACTIVO |
| 22.590.693-9 | MOLINA TAPIA FLORENCIA ANDREA | ACTIVO |
| 22.597.780-1 | OLLINO BRAVO JOSE | ACTIVO |
| 22.578.661-5 | OYARZÚN GALLEGOS GABRIEL EDUARDO | ACTIVO |
| 22.484.430-1 | PEÑA BUSTAMANTE DIEGO EMILIANO | ACTIVO |
| 22.225.498-1 | PIZARRO CABELLO MIA PAZ NIKOLE | ACTIVO |
| 22.408.057-3 | RAMÍREZ ARANCIBIA DEAVIN NICKO AGUSTÍN | ACTIVO |
| 22.663.470-3 | RIQUELME ALEGRÍA CLAUDIO ANDRÉS | ACTIVO |
| 22.415.458-5 | RIVEROS CALVO GASTÓN VICENTE | ACTIVO |
| 22.679.457-3 | ROMÁN DELGADILLO EMILIA | ACTIVO |
| 22.593.273-5 | SAÉZ MONSALVE VALENTINA ANDREA | ACTIVO |
| 22.387.523-8 | SOTO MORALES MAXIMILIANO TOMÁS | ACTIVO |
| 23.022.065-4 | VALDÉS SANTIAGO BENJAMÍN ESTEBAN | ACTIVO |
| 22.398.005-8 | VIDAL SANCHEZ SERGIO ISMAEL | ACTIVO |

**Acción recomendada:** Cambiar `estado_std` a `EGRESADO` al cierre del año académico 2025.

---

## 4. Posibles Retiros/Traslados (~39 estudiantes)

Estudiantes con estado ACTIVO en BD que **NO están en la lista oficial SIGE 2026** y **NO son egresados 4° Medio**:

| RUN | Nombre | Curso 2025 | Observación |
|-----|--------|------------|-------------|
| 26.457.405-6 | BANDA VALENZUELA ISABEL ELIANA | 1° BASICO A | No en lista 2° Básico 2026 |
| 26.685.499-4 | TORRES FERNÁNDEZ AMANDA | 1° BASICO A | No en lista 2° Básico 2026 |
| 26.741.815-2 | VALDÉS COVARRUBIAS SAMUEL SIMÓN | 1° BASICO A | No en lista 2° Básico 2026 |
| 25.872.208-6 | ALFARO ARANCIBIA EMA FAIRUZ | 2° BASICO A | No en lista 3° Básic 2026 |
| 25.725.141-1 | BANDA VALENZUELA SALVADOR INTI | 2° BASICO A | No en lista 3° Básico 2026 |
| 26.051.126-2 | PINTO LAZO AGUSTÍN ANTONIO | 2° BASICO A | No en lista 3° Básico 2026 |
| 26.083.645-5 | ALFARO ORTEGA HENZEL VALENTÍN | 2° BASICO B | No en lista 3° Básico 2026 |
| 26.081.615-2 | CHANDÍA LÓPEZ DOMINIQUE PAZ | 2° BASICO B | No en lista 3° Básico 2026 |
| 25.828.018-0 | GATICA JARAMILLO AMARO ESTEBAN | 2° BASICO B | No en lista 3° Básico 2026 |
| 25.964.631-6 | MANCINI ABALLAY GIULIANO MARCUS | 2° BASICO B | No en lista 3° Básico 2026 |
| 25.392.498-5 | ARANDA ARANDA GONZALO LEÓN | 3° BASICO B | No en lista 4° Básico 2026 |
| 25.485.834-K | HENRÍQUEZ BOHORQUEZ EMMA ISABELLA | 3° BASICO B | No en lista 4° Básico 2026 |
| 25.038.237-5 | LEIVA PALMA AMARO MAURICIO | 3° BASICO B | No en lista 4° Básico 2026 |
| 25.567.073-5 | MONTIEL TORRES NEFTALI RODOLFO | 3° BASICO B | No en lista 4° Básico 2026 |
| 25.323.437-7 | MARCHANT GARRIDO ANDREW JARED | 4° BASICO A | No en lista 5° Básico 2026 |
| 25.109.403-9 | SONNEVILLE VALDIVIA DOMINGO | 4° BASICO A | No en lista 5° Básico 2026 |
| 24.745.487-K | BRITO GONZÁLEZ ANTONIA VALENTINA | 5° BASICO A | No en lista 6° Básico 2026 |
| 24.682.546-7 | QUEGLAS RAMÍREZ FATIMA ALMA | 5° BASICO A | No en lista 6° Básico 2026 |
| 24.305.401-K | AHUMADA PÉREZ NICOLÁS EMILIO | 6° BASICO A | No en lista 7° Básico 2026 |
| 23.923.777-0 | BENAVIDES DONOSO ÉLIAN ISMAEL | 6° BASICO A | No en lista 7° Básico 2026 |
| 24.321.352-5 | CHAURA ARAYA MAXIMILIANO ESTEBAN | 6° BASICO A | No en lista 7° Básico 2026 |
| 24.958.405-3 | ALBORNOZ MORGADO ANAÍS ILLARI | 6° BASICO B | No en lista 7° Básico 2026 |
| 23.711.586-4 | BARRIA ZULOAGA ANDRÉS OMAR | 1° MEDIO A | No en lista 2° Medio 2026 |
| 23.246.983-8 | ULLOA FIGUEROA SAMUEL ALONSO | 1° MEDIO A | No en lista 2° Medio 2026 |
| 23.616.299-0 | RIVEROS CALVO DOMINGO JOAQUÍN | 1° MEDIO A | No en lista 2° Medio 2026 |
| 23.205.149-9 | SANTELICES MEZA ISIDORA VALENTINA | 2° MEDIO A | Posible duplicado con 23.205.714-9 |
| 22.535.677-7 | SOTO MUÑOZ AGUSTÍN ALEXIS | 2° MEDIO B | No en lista 3° Medio 2026 |
| 23.214.906-K | ROMÁN DELGADILLO HERNÁN | 2° MEDIO B | No en lista 3° Medio 2026 |
| 22.592.959-9 | DE LA QUINTANA BOTTA EMILIA INES | 3° MEDIO A | No en lista 4° Medio 2026 |
| 22.923.379-3 | JARA MARTÍNEZ NICANOR EMILIANO | 3° MEDIO B | No en lista 4° Medio 2026 |
| 22.571.321-9 | PÉREZ GUZMÁN VALENTINA ISIDORA | 3° MEDIO B | No en lista 4° Medio 2026 |
| 23.937.375-5 | MONTIEL TORRES JOHAO ALEXIS | 8° BASICO A | No en lista 1° Medio 2026 |

**Acción recomendada:** Confirmar estado manualmente con administración escolar. Cambiar a `RETIRADO` si corresponde.

---

## 5. Estudiantes con Estructura de Nombre Incorrecta (~60)

Patrón detectado: Los nombres están distribuidos incorrectamente entre `first_name`, `apellido_paterno` y `apellido_materno`. El segundo nombre va en `apellido_paterno` y los dos apellidos van concatenados en `apellido_materno`.

### Ejemplos representativos:

| RUN | BD: first_name | BD: ap_paterno | BD: ap_materno | Correcto: first_name | Correcto: ap_paterno | Correcto: ap_materno |
|-----|---------------|----------------|----------------|---------------------|---------------------|---------------------|
| 27.245.224-5 | ELOISA | IZADI | ARENAS LANDEROS | ELOÍSA IZADI | ARENAS | LANDEROS |
| 27.231.851-4 | AMELIA | (Sin apellido) | LUCÍA HERNPANDEZ FUENTES | AMELIA LUCÍA | HERNÁNDEZ | FUENTES |
| 26.845.290-7 | NICANOR | (Sin apellido) | AUKAN NUÑEZ JORQUERA | NICANOR AUKAN | NÚÑEZ | JORQUERA |
| 22.599.890-6 | MATÍAS | ALONSO | NUÑEZ ORELLANA | MATÍAS ALONSO | NÚÑEZ | ORELLANA |
| 22.692.513-9 | AMANDA | ANTONIA | AREVELO TOLEDO | AMANDA ANTONIA | ARÉVALO | TOLEDO |
| 22.903.897-4 | SAYEN | DE | LOS ANGELES VERGARA CANDIA | SAYEN DE LOS ANGELES | VERGARA | CANDIA |
| 24.631.708-9 | LIBERTAD | (Sin apellido) | CACES SEPULVEDA | LIBERTAD | CACES | SEPÚLVEDA |
| 23.858.726-3 | LEONOR | AMANDA | PARRA LENI | LEONOR AMANDA | PARRA | LENI |
| 25.441.930-3 | LEON | IGNACIO | RAMIREZ HIGUERAS | LEÓN IGNACIO | RAMÍREZ | HIGUERAS |
| 25.300.537-8 | LETICIA | COLOMBA | ALARCON HUERTA | LETICIA COLOMBA | ALARCÓN | HUERTA |
| 25.354.011-7 | EMILIO | GAEL | CONTRERAS VERGARA | EMILIO GAEL | CONTRERAS | VERGARA |
| 25.618.895-3 | MATIAS | SALVADOR | VALPREDA VÍVEROS | MATÍAS SALVADOR | VALPREDA | VÍVEROS |
| 25.418.027-0 | SALVADOR | TOMAS | ABARZA MORALES | SALVADOR TOMÁS | ABARZA | MORALES |
| 25.720.765-K | VICENTE | ANTONIO | ESQUIVEL HECHENLEITNER | VICENTE ANTONIO | ESQUIVEL | HECHENLEITNER |
| 24.822.697-8 | MARIANO | IGNACIO | CARVAJAL PUYOL | MARIANO IGNACIO | CARVAJAL | PUYOL |
| 25.313.893-9 | DARKO | DUSÁN | KALASIC SOBARZO | DARKO DUSÁN | KALASIC | SOBARZO |
| 24.557.067-8 | ANTONIO | LEON | RAMIREZ ACEVEDO | ANTONIO LEÓN | RAMÍREZ | ACEVEDO |
| 23.795.147-6 | MATEO | IGNACIO | VALENZUELA GONZÁLEZ | MATEO IGNACIO | VALENZUELA | GONZÁLEZ |
| 24.140.462-5 | JOSEFA | LETICIA | ORTIZ BARRIOS | JOSEFA LETICIA | ORTIZ | BARRIOS |
| 24.317.585-2 | VICENTE | ALESSANDRO | ARANCIBIA CUEVAS | VICENTE ALESSANDRO | ARANCIBIA | CUEVAS |
| 23.714.855-K | AGUSTÍN | ANDRÉS | VELÁSQUEZ ZAVALA | AGUSTÍN ANDRÉS | VELÁSQUEZ | ZAVALA |
| 23.706.034-2 | GAEL | EMILIANO | FUENTES TORO | GAEL EMILIANO | FUENTES | TORO |
| 23.052.581-1 | IAN | FABRIZIO | SCHRODER RIVEROS | IAN FABRIZIO | SCHRÖDER | RIVEROS |
| 23.621.077-4 | VALENTINA | ISIDORA | VENENCIANO BERROETA | VALENTINA ISIDORA | VENENCIANO | BERROETA |
| 23.694.069-1 | DANTE | NICOLÁS | ROJAS AGUILERA | DANTE NICOLÁS | ROJAS | AGUILERA |
| 22.948.868-6 | GRACE | ABIGAIL | LARRONDO ESPINOZA | GRACE ABIGAIL | LARRONDO | ESPINOZA |
| 22.949.882-7 | MARTIN | ALONSO | ACUÑA ARIAS | MARTÍN ALONSO | ACUÑA | ARIAS |
| 23.251.961-4 | PHILIP | ANTONIO | VANI GUAJARDO | PHILIP ANTONIO | VANI | GUAJARDO |
| 23.423.284-3 | BIANCA | GIANELLA | RIVAS GONZÁLEZ | BIANCA GIANELLA | RIVAS | GONZÁLEZ |
| 23.630.186-9 | NATIVA | LUZ | QUIROGA MUÑOZ | NATIVA LUZ | QUIROGA | MUÑOZ |
| 23.091.788-4 | ISIDORA | MARTINA | PIA OPAZO MELLA | ISIDORA MARTINA PIA | OPAZO | MELLA |
| 23.079.901-6 | AMANDA | MONSERRAT | BERNAL CHACANA | AMANDA MONSERRAT | BERNAL | CHACANA |
| 24.051.700-0 | AMANDA | CAROLINA | SÁNCHEZ CARVALLO | AMANDA CAROLINA | SÁNCHEZ | CARVALLO |
| 23.743.638-5 | COLOMBA | ELUNEY | SALAZAR LÓPEZ | COLOMBA ELUNEY | SALAZAR | LÓPEZ |
| 25.980.651-8 | MUNAY | ANTAY | AGÜERO VIDAL | MUNAY ANTAY | AGÜERO | VIDAL |
| 23.839.626-3 | XADIEL | VICENTE | (AMANDA) ZUÑIGA FEBRE | XADIEL VICENTE | ZÚÑIGA | FEBRE |

> **Patrón:** Estos registros probablemente fueron ingresados con el nombre completo en un solo campo y luego separados automáticamente de forma incorrecta. El `apellido_materno` siempre contiene dos palabras (los dos apellidos reales concatenados).

**Acción recomendada:** Ejecutar corrección masiva redistribuyendo las partes del nombre. Ver archivo `sql/sige_2026_correcciones_nombres.csv` para el detalle completo.

---

## 6. Estado de Asignación de Cursos

### Distribución actual de estudiantes por año académico:

| Año Académico | Estudiantes | % | Observación |
|---------------|------------|---|-------------|
| 2024 | 22 | 4.3% | Datos residuales/prueba |
| 2025 | 456 | 88.2% | Año vigente — pendiente migración a 2026 |
| 2026 | 39 | 7.5% | Parcialmente migrados |

### Detalle cursos 2025 con cantidad de estudiantes:

| Curso 2025 | Alumnos BD | → Curso 2026 esperado | Alumnos SIGE 2026 |
|-----------|-----------|----------------------|-------------------|
| 1° BASICO A | 22 | 2° Básico | 26 |
| 2° BASICO A | 22 | 3° Básico-A | 25 |
| 2° BASICO B | 24 | 3° Básico-B | 21 |
| 3° BASICO A | 27 | 4° Básico-A | 26 |
| 3° BASICO B | 26 | 4° Básico-B | 22 |
| 4° BASICO A | 29 | 5° Básico | 25 |
| 5° BASICO A | 27 | 6° Básico | 26 |
| 6° BASICO A | 25 | 7° Básico | 25 |
| 7° BASICO A | 29 | 8° Básico | 29 |
| 8° BASICO A | 27 | 1° Medio-A | 26 |
| 8° BASICO B | 25 | 1° Medio-B | 26 |
| 1° MEDIO A | 32 | 2° Medio | 29 |
| 2° MEDIO A | 25 | 3° Medio-A | 25 |
| 2° MEDIO B | 24 | 3° Medio-B | 25 |
| 3° MEDIO A | 29 | 4° Medio-A | 33 |
| 3° MEDIO B | 31 | 4° Medio-B | 27 |
| 4° MEDIO A | 31 | EGRESA | — |
| — (nuevos) | — | 1° Básico | 25 |

> **Nota:** Las diferencias entre alumnos BD 2025 y SIGE 2026 se explican por: ingresos nuevos, retiros, traslados, y redistribución entre secciones A/B.

### Estado de migración a 2026:
- **39 estudiantes** ya están asignados a cursos 2026
- **456 estudiantes** aún están en cursos 2025 (requieren migración)
- La migración masiva de cursos 2025→2026 **aún no se ha realizado**

---

## 7. Posible Duplicado SANTELICES MEZA

| RUN | first_name | apellido_paterno | apellido_materno | Curso |
|-----|-----------|-----------------|-----------------|-------|
| 23.205.149-9 | ISIDORA VALENTINA | SANTELICES | MEZA | 2° MEDIO A (2025) |
| 23.205.714-9 | ISIDORA VALENTINA | SANTELICES | MEZA | 2° MEDIO A (2025) |

Ambos registros tienen el mismo nombre pero **diferente RUN**. En la lista SIGE 2026, solo aparece UNO (verificar cuál es el correcto y eliminar el otro).

---

## Resumen de Acciones Requeridas

| # | Acción | Registros | Prioridad |
|---|--------|-----------|-----------|
| 1 | Corregir RUNs incorrectos | 5 | ALTA |
| 2 | Eliminar registros duplicados (RUN truncado) | 5 | ALTA |
| 3 | Corregir estructura de nombres | ~60 | ALTA |
| 4 | Confirmar retiros/traslados con administración | ~39 | MEDIA |
| 5 | Marcar egresados 4° Medio como EGRESADO | ~30 | MEDIA |
| 6 | Migrar estudiantes de cursos 2025 a cursos 2026 | ~456 | MEDIA |
| 7 | Agregar estudiante faltante (si se matricula) | 1 | BAJA |
| 8 | Resolver duplicado SANTELICES MEZA | 1 | MEDIA |
| 9 | Mover estudiantes en cursos 2024 a curso correcto | 22 | BAJA |

---

*Archivo generado automáticamente. Ver también: `sql/sige_2026_correcciones.csv`*
