# Reporte: update_cheques.csv vs BD de Matricula

Fecha: 2026-03-16
Fuente CSV: `update_cheques.csv`
Detalle tecnico: `tmp_update_cheques_report_20260316.json`

## Resumen ejecutivo

- Filas CSV revisadas: 50
- Filas asociadas a una matricula 2026: 50
- Filas sin match confiable: 0
- Matriculas unicas asociadas desde el CSV: 40
- Filas duplicadas sobre la misma matricula/familia: 10
- Filas asociadas a matriculas con cheques realmente cargados en BD: 11
- Filas asociadas a matriculas sin ningun cheque en BD: 39
- Matriculas 2026 con cheques en BD: 10
- Matriculas con cheques en BD no representadas por el CSV: 0

Conclusion principal: con las 4 equivalencias manuales incorporadas, el CSV ya referencia correctamente todas las matriculas 2026 detectadas por el cruce. De esas 50 filas, 11 apuntan a matriculas que hoy tienen cheques cargados y 39 a matriculas que siguen sin registros en la tabla `cheques`.

## Coincidencia completa

- DANIELA IBARRA BARRIENTOS: match completo contra `DANIELA IGNACIA IBARRA BARRIENTOS`.
  - Banco: Santander
  - Cantidad: 10
  - Valor por cheque: 133126
  - Series: coinciden exactamente

## Filas con cheques en BD pero con diferencias

- ALONSO TOMÁS MARTORI COVARRUBIAS: 10 cheques en CSV y 10 en BD; banco y cantidad coinciden; difiere el monto.
- ALVARO MEDINA FIGUEROA: 10 cheques en CSV y 10 en BD; banco y monto coinciden; difieren las series.
- AMPARO VILCHES: 10 cheques en CSV y 10 en BD; banco y monto coinciden; difieren las series.
- ANTONELLA PAZ NAVARRO AVILÉS: 10 cheques en CSV y 10 en BD; monto y cantidad coinciden; diferencia de banco por spelling (`SEGURITY` vs `SECURITY`).
- ARANZA LARIOS GUTIERREZ: CSV indica 10 cheques, BD tiene 30; banco y monto coinciden; diferencia fuerte de cantidad y series.
- HELENA SEPULVEDA OJEDA: 10 cheques en CSV y 10 en BD; monto coincide; diferencia de banco por rotulo (`CHILE` vs `BANCO DE CHILE`).
- MAGDALENA SALAZAR CORNEJO: 10 cheques en CSV y 10 en BD; difieren banco, monto y series.
- BENJAMIN SALAZAR CORNEJO: 10 cheques en CSV y 10 en BD; difieren banco, monto y series.
- LORETO RIOS CHAVEZ: 10 cheques en CSV y 10 en BD; banco y monto coinciden; difieren las series.
- MATILDE CAMPUSANO: 10 cheques en CSV y 10 en BD; difieren las series y en BD aparecen montos mixtos.

## Filas sin match confiable

- No quedan filas sin match despues de aplicar las equivalencias manuales al CSV.

Observacion: ya no quedan matriculas con cheques en BD fuera de la cobertura del CSV.

## Matriculas con cheques en BD no cubiertas por el CSV

- No quedan casos en esta categoria tras la normalizacion manual de nombres.

## Lectura operativa

- El problema dominante no es de curso ni de identificacion de matricula: la mayoria de filas si se puede ubicar en 2026.
- El problema dominante es de registro: 39 de las 50 filas quedan asociadas a matriculas que aun no tienen cheques cargados en la tabla `cheques`.
- Donde si existen cheques en BD, la inconsistencia mas frecuente es en las series (`numero_serie`), no en banco ni en monto.

## Equivalencias manuales aplicadas

- ALFONSO MARTORI COVARRUVIA -> ALONSO TOMÁS MARTORI COVARRUBIAS
  - Matricula: `05d4264e-b81e-4b4f-a8e2-3e873ebdc833`.
  - Resultado: match confirmado; el caso ahora queda cubierto por el CSV.

- ANTONELA NAVARRO -> ANTONELLA PAZ NAVARRO AVILÉS
  - Matricula: `a3e1b488-8df0-4d03-9da7-452de10c810f`.
  - Resultado: match confirmado; el caso ahora queda cubierto por el CSV.

- ANTONIA CANTATURRI CONCHA -> GIULIANO ANTONINO CANTARUTTI CONCHA
  - Matricula: `3a2ffbbc-85b4-4f1d-9b01-50d9e1c4493d`.
  - Resultado: match confirmado tras la correccion manual del nombre.

- FRANCISCOCARRASCO CONSTANSA -> FRANCISCO GABRIEL CARRASCO SEPÚLVEDA
  - Matricula: `e23eab60-d5cd-49e5-90a8-189104140ce8`.
  - Resultado: match confirmado; sigue siendo un grupo familiar sin cheques cargados en BD.

Balance de la normalizacion manual:

- 4 de 4 casos quedaron absorbidos por el matching.
- 2 de esos 4 corresponden a matriculas con cheques reales en BD: ALONSO y ANTONELLA.
- 2 corresponden a matriculas 2026 sin cheques cargados en BD: GIULIANO ANTONINO CANTARUTTI CONCHA y FRANCISCO GABRIEL CARRASCO SEPÚLVEDA.

## Revision manual de series con cheques reales en BD

De las filas con cheques realmente cargados en BD, 7 presentan diferencia de series. El resto de las filas marcadas con `series` en el JSON lo estan porque la matricula no tiene cheques en BD, no porque exista una discrepancia serie a serie.

- ALVARO MEDINA FIGUEROA
  - CSV: `0000012` a `0000022`.
  - BD: `12,13,14,15,17,18,19,20,21,22`.
  - Lectura: no es solo formato. En BD falta `16`; en CSV sobran 11 valores para una fila que dice `10` cheques.

- AMPARO VILCHES
  - CSV: `0000037` a `0000045`.
  - BD: `0000036` a `0000045`.
  - Lectura: parece corrimiento de una posicion en el CSV; BD tiene una serie inicial adicional (`36`) y completa 10 cheques.

- ARANZA LARIOS GUTIERREZ
  - CSV: 10 series `4882627` a `4882636`.
  - BD: 30 registros para la misma matricula.
  - Dentro de BD hay 10 series correctas que coinciden con CSV, mas 20 registros extra (`4884627...` y `39939814882627...`).
  - Lectura: la BD parece tener duplicacion o contaminacion de series, no un simple error del CSV.

- MAGDALENA SALAZAR CORNEJO y BENJAMIN SALAZAR CORNEJO
  - Ambas filas ahora apuntan de forma consistente a la misma matricula familiar con 10 cheques en BD.
  - CSV: valor `235996`, banco `ESTADO` y una lista de series malformada alrededor de `1011`.
  - BD: 10 cheques en `BancoEstado`, todos por `102870`, con series `2278607` a `2278616`.
  - Lectura: ya no hay ambigüedad de identidad relevante; el conflicto es de datos del grupo familiar, porque banco, monto y seriales del CSV no coinciden con lo cargado en BD.

- LORETO RIOS CHAVEZ
  - CSV: `000026` a `000033` y ultimo valor mal unido como `003435`.
  - BD: `hco0000026` a `hco0000035`.
  - Lectura: la diferencia principal es de formato/prefijo en BD y un error de digitacion en el ultimo tramo del CSV.

- MATILDE CAMPUSANO
  - CSV: `000001` a `000010`.
  - BD: `01` a `10`.
  - Lectura: las series son equivalentes por formato, pero la BD tiene montos mezclados (`13000`, `130000`, `134260`, `136750`), asi que el problema real no esta en la serie sino en la calidad del dato financiero.