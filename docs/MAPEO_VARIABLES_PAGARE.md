# 📋 MAPEO COMPLETO DE VARIABLES DEL PAGARÉ

## 🔍 PROBLEMA ACTUAL
Las variables NO se están reemplazando. El HTML muestra `{{...}}` y `_____` en lugar de los datos reales.

---

## 📊 MAPEO EXACTO DE VARIABLES

### 1️⃣ FECHA (Generada automáticamente)
```
PLACEHOLDER: {{fecha_actual}}
ORIGEN: buildPagarePayload() genera la fecha del día actual
FORMATO: "27 de octubre del 2025"
CÓDIGO:
  const now = new Date();
  const day = now.getDate();
  const months = ['enero', 'febrero', ...];
  const month = months[now.getMonth()];
  const yearFull = now.getFullYear();
  const fecha_actual = `${day} de ${month} del ${yearFull}`;
```

### 2️⃣ DATOS DEL APODERADO (De tabla `guardians`)
```
PLACEHOLDER: {{guardian_full_name}}
ORIGEN: guardian.first_name + guardian.last_name
EJEMPLO: "ESTER ESTAY"
CÓDIGO: [guardian.first_name, guardian.last_name].filter(Boolean).join(' ')

PLACEHOLDER: {{guardian_run}}
ORIGEN: guardian.run
EJEMPLO: "10.710.002-4"
CÓDIGO: guardian.run || '_______________'

PLACEHOLDER: {{guardian_address}}
ORIGEN: guardian.address
EJEMPLO: "STA MARGARITA 237 C BELLAVISTA"
CÓDIGO: guardian.address || '_______________'

PLACEHOLDER: {{guardian_nacionalidad}}
ORIGEN: guardian.nacionalidad
EJEMPLO: "CHILENA"
CÓDIGO: guardian.nacionalidad || '_______________'

PLACEHOLDER: {{guardian_profesion}}
ORIGEN: guardian.profesion
EJEMPLO: "INGENIERO"
CÓDIGO: guardian.profesion || '_______________'

PLACEHOLDER: {{guardian_estado_civil}}
ORIGEN: guardian.estado_civil
EJEMPLO: "CASADO"
CÓDIGO: guardian.estado_civil || '_______________'
```

### 3️⃣ DATOS DE ESTUDIANTES (De tabla `students`)
```
PLACEHOLDER: {{students_table}}
ORIGEN: buildPagarePayload() genera tabla HTML completa
FORMATO: Tabla HTML con columnas: Número, Nombre, RUT, Curso
CÓDIGO:
  const tableRows = students.map((s, idx) => {
    const cursoDisplay = s.curso || s.grade || s.nivel || '';
    return `<tr>
      <td>${idx + 1}</td>
      <td>${s.whole_name || s.first_name}</td>
      <td>${s.run}</td>
      <td>${cursoDisplay}</td>
    </tr>`;
  }).join('');
  
  const studentsTable = `<table border="1">
    <thead><tr>
      <th>Número</th><th>Nombre</th><th>RUT</th><th>Curso año ${year}</th>
    </tr></thead>
    <tbody>${tableRows}</tbody>
  </table>`;
```

### 4️⃣ DATOS ECONÓMICOS (De formulario económico)
```
PLACEHOLDER: {{monto_matricula}}
ORIGEN: economic.monto_matricula
FORMATO: "150.000" (con separador de miles)
CÓDIGO: formatCurrency(economic?.monto_matricula)

PLACEHOLDER: {{colegiatura_anual}}
ORIGEN: economic.colegiatura_anual
FORMATO: "3.600.000"
CÓDIGO: formatCurrency(economic?.colegiatura_anual)

PLACEHOLDER: {{cantidad_cuotas}}
ORIGEN: economic.cantidad_cuotas
EJEMPLO: "10"
CÓDIGO: economic?.cantidad_cuotas || '_______________'

PLACEHOLDER: {{monto_cuota}}
ORIGEN: economic.monto_cuota
FORMATO: "360.000"
CÓDIGO: formatCurrency(economic?.monto_cuota)

PLACEHOLDER: {{dia_vencimiento}}
ORIGEN: economic.dia_vencimiento
EJEMPLO: "5"
CÓDIGO: economic?.dia_vencimiento || '_______________'
```

### 5️⃣ FORMA DE PAGO (De checkboxes UI)
```
PLACEHOLDER: {{forma_pago_cheques}}
ORIGEN: paymentMethod.cheques
FORMATO: "☑" si true, "☐" si false
CÓDIGO: paymentMethod?.cheques ? '☑' : '☐'

PLACEHOLDER: {{forma_pago_transferencia}}
ORIGEN: paymentMethod.transferencia
FORMATO: "☑" si true, "☐" si false
CÓDIGO: paymentMethod?.transferencia ? '☑' : '☐'

PLACEHOLDER: {{forma_pago_efectivo}}
ORIGEN: paymentMethod.efectivo
FORMATO: "☑" si true, "☐" si false
CÓDIGO: paymentMethod?.efectivo ? '☑' : '☐'

PLACEHOLDER: {{forma_pago_tarjeta}}
ORIGEN: paymentMethod.tarjeta
FORMATO: "☑" si true, "☐" si false
CÓDIGO: paymentMethod?.tarjeta ? '☑' : '☐'
```

### 6️⃣ AÑO (Del enrollment)
```
PLACEHOLDER: {{year}}
ORIGEN: enrollment.academic_year
EJEMPLO: "2025"
CÓDIGO: year
```

---

## 🔧 FUNCIÓN DE REEMPLAZO

```typescript
export function renderTemplate(raw: string, payload: Record<string, any>): string {
  return raw.replace(/{{\s*([a-zA-Z0-9_]+)\s*}}/g, (_m, key) => {
    const v = payload[key];
    if (v === undefined || v === null) return `{{${key}}}`;
    return typeof v === 'string' ? v : String(v);
  });
}
```

**REGEX USADA:** `/{{\s*([a-zA-Z0-9_]+)\s*}}/g`
- Busca: `{{cualquier_nombre}}`
- Captura: `cualquier_nombre`
- Reemplaza con: `payload['cualquier_nombre']`

---

## 🎯 PLACEHOLDERS EN EL TEMPLATE HTML

### Aparecen en estas líneas del contrato:

1. Línea 3: `En Viña del Mar, a {{fecha_actual}} entre...`
2. Línea 3: `Don(a), {{guardian_full_name}} (nacionalidad) {{guardian_nacionalidad}}`
3. Línea 3: `(profesión u oficio). {{guardian_profesion}} (estado civil) {{guardian_estado_civil}}`
4. Línea 3: `cédula de identidad N° {{guardian_run}} domiciliado/a en: {{guardian_address}}`
5. Línea 11: `para el año académico {{year}}, en calidad de alumnos(s)...`
6. Línea 13: `{{students_table}}`
7. Línea 40: `Por concepto de matricula, al contado, la suma de $ {{monto_matricula}}`
8. Línea 42: `Por concepto de colegiatura anual, el monto correspondiente a ${{colegiatura_anual}}`
9. Línea 42: `dividido en {{cantidad_cuotas}} cuotas mensuales de ${{monto_cuota}}`
10. Línea 42: `cada una para el día {{dia_vencimiento}} de cada mes.`
11. Línea 44: `Cheques: {{forma_pago_cheques}} Transferencia Electrónica: {{forma_pago_transferencia}}`
12. Línea 44: `Pago en efectivo: {{forma_pago_efectivo}} Tarjeta de Crédito: {{forma_pago_tarjeta}}`
13. Línea 66: `En caso de sufrir el/la estudiante durante su permanencia en el Colegio, éste proporcionará...`
14. Línea 71: `En el caso que el/la estudiante(s) tenga la calidad de "alumno prioritario" durante el presente año ({{year}})`

---

## ❌ ¿POR QUÉ NO FUNCIONA?

### Posibles causas:

#### A) Template NO se carga correctamente
```
VERIFICAR EN CONSOLE:
"📄 getActivePagareTemplate: Template loaded from file, length: 9234"
SI DICE length: 0 → Template NO se cargó
```

#### B) Payload NO tiene los datos
```
VERIFICAR EN CONSOLE:
"📦 Payload COMPLETO generated: {
  fecha_actual: "27 de octubre del 2025",
  guardian_full_name: "ESTER ESTAY",
  ...
}"
SI DICE undefined → Datos NO se fetchearon
```

#### C) renderTemplate() NO ejecuta el replace
```
VERIFICAR EN CONSOLE:
"📄 Checking if placeholders were replaced:
  - Contains {{fecha_actual}}? false"
SI DICE true → El regex NO reemplazó
```

#### D) HTML se carga ANTES de que renderTemplate ejecute
```
VERIFICAR EN CONSOLE:
"📄 HTML AFTER renderTemplate (first 500 chars): En Viña del Mar, a 27 de octubre..."
SI DICE "{{fecha_actual}}" → Hay problema de timing
```

---

## 🚨 SIGUIENTE PASO CRÍTICO

**NECESITO VER LOS LOGS DE LA CONSOLE** para identificar cuál de estas 4 causas está fallando.

Por favor sigue estas instrucciones:

1. **Ctrl+F5** - Hard refresh del navegador
2. **F12** - Abrir DevTools
3. **Console tab** - Ir a la pestaña Console
4. **Clear** - Limpiar console (botón 🗑️)
5. Ir a **Matrícula**
6. Agregar un estudiante
7. Llenar datos económicos
8. Click **Generar Vista Previa**
9. **Copiar TODOS los logs** de la console
10. **Pegar aquí**

Los logs dirán EXACTAMENTE dónde está fallando.
