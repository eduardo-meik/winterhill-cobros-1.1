# Reporte de Reparación y Plan de Acción

## 1. Análisis de "Código Duplicado" en `matricula.ts`

**Estado:** No se encontraron duplicados.
**Investigación:**
- Se revisó el archivo `src/services/matricula.ts` buscando múltiples definiciones de `buildPrestacionPayload` y `numberToWordsEs`.
- Se ejecutó `npm run build` y finalizó exitosamente (`✓ built in 1m 19s`), lo que confirma que no hay errores de compilación por identificadores duplicados.
- Se verificó la unicidad de las funciones mediante herramientas de edición, confirmando que solo existe una definición de cada una.

**Conclusión:** Es probable que el error reportado fuera transitorio o se debiera a una versión en caché. El código actual es válido y compila correctamente.

## 2. Corrección de `{{cantidad_cuotas}}` en Contrato

**Problema:** El campo `cantidad_cuotas` aparecía como `_______________` en el contrato de prestación.
**Causa:** La función `buildPrestacionPayload` dependía exclusivamente de `economic.cantidad_cuotas`, que podía ser `undefined` si los datos no se habían guardado completamente en `meta`.
**Solución Aplicada:**
- Se actualizó la firma de `buildPrestacionPayload` para aceptar el objeto `paymentPlan` (que ya se pasaba desde `MatriculaWizard.jsx` pero se ignoraba).
- Se modificó la asignación de `cantidad_cuotas` para usar `paymentPlan.n_cuotas` como respaldo si `economic.cantidad_cuotas` no está definido.

```typescript
// Antes
cantidad_cuotas: economic?.cantidad_cuotas?.toString() || '_______________',

// Ahora
cantidad_cuotas: (economic?.cantidad_cuotas || paymentPlan?.n_cuotas)?.toString() || '_______________',
```

## 3. Próximos Pasos

1. **Verificar:** Generar una vista previa del contrato en el asistente de matrícula y confirmar que "Cantidad de Cuotas" muestra el número correcto (ej. "10" o "1").
2. **Despliegue:** Si la verificación es exitosa, proceder con el despliegue.

## 4. Eliminación de Guiones Bajos ('_______________')

**Solicitud:** El usuario solicitó remover las líneas de guiones bajos que aparecían cuando faltaba información en los contratos.
**Acción:** Se reemplazaron todas las ocurrencias de `'_______________'` por `''` (cadena vacía) en `src/services/matricula.ts`.
**Funciones Afectadas:**
- `buildPrestacionPayload`
- `buildPagareDeudaPayload`
- `buildRepactacionPayload`
- `formatCurrency` (definida localmente en cada una de las anteriores)

Esto asegura que si un campo no tiene datos, simplemente aparecerá vacío en el PDF en lugar de mostrar una línea de relleno.
