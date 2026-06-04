# 🔍 DEBUGGING: Pagaré No Muestra Datos

## Instrucciones Paso a Paso

Por favor, sigue estos pasos **EXACTAMENTE** y copia los logs de la consola:

### Paso 1: Refrescar Navegador
```
Ctrl + F5 (hard refresh para limpiar cache)
```

### Paso 2: Abrir DevTools Console
```
Presiona F12
Selecciona la pestaña "Console"
Click en el ícono 🗑️ (Clear console) para limpiar
```

### Paso 3: Navegar a Matrícula
```
Click en "Matrícula" en el menú
```

### Paso 4: Agregar Estudiante
```
En Step 0, agrega AL MENOS 1 estudiante de la lista
```

### Paso 5: Llenar Datos Económicos
```
En Step 1, llena:
- Monto Matrícula: 150000
- Colegiatura Anual: 3600000
- Cantidad Cuotas: 10
- Monto por Cuota: 360000
- Día Vencimiento: 5

Marca checkbox: ☑ Transferencia Electrónica

Click "💾 Guardar Datos"
Click "Siguiente"
```

### Paso 6: Generar Preview
```
En Step 2, click "📄 Generar Vista Previa"
```

### Paso 7: COPIAR TODOS LOS LOGS

En la consola deberías ver logs como estos. **COPIA TODOS Y PÉGALOS AQUÍ**:

```javascript
🎯 handleGeneratePagare started
👤 Guardian COMPLETO: {...}
👥 Students COMPLETO: [...]
💰 Economic data COMPLETO: {...}
💳 Payment method COMPLETO: {...}
📄 getActivePagareTemplate: Fetching template from DB...
⚠️ No active template in DB, loading from file /contratos/pagare.txt
📄 Template loaded from file, length: 9234
📄 File content preview (first 200 chars): ...
📄 Template loaded:
  - ID: file-fallback
  - Type: PAGARE
  - Version: 1
  - Content length: 9234
  - Content preview (first 300 chars): ...
💵 Economic numbers parsed: {...}
🔧 buildPagarePayload - Guardian data: {...}
📅 Fecha actual: 27 de octubre del 2025
👥 Students count: 1
💰 Economic data: {...}
💳 Payment method: {...}
✅ Final payload: {...}
📦 Payload COMPLETO generated: {...}
📄 HTML AFTER renderTemplate (length): 9800
📄 HTML AFTER renderTemplate (first 500 chars): ...
📄 Checking if placeholders were replaced:
  - Contains {{fecha_actual}}? false
  - Contains {{guardian_full_name}}? false
  - Contains {{guardian_run}}? false
```

## Lo que necesito saber:

### 1. ¿Se cargó el template?
Busca en los logs:
```
📄 Template loaded from file, length: XXXX
```

**Pregunta:** ¿Qué longitud muestra? (debe ser ~9000)

### 2. ¿Se generó el payload?
Busca en los logs:
```
✅ Final payload: {...}
```

**Pregunta:** ¿Muestra datos del guardian? (first_name, last_name, run, address)

### 3. ¿Se reemplazaron los placeholders?
Busca en los logs:
```
📄 Checking if placeholders were replaced:
  - Contains {{fecha_actual}}? true/false
  - Contains {{guardian_full_name}}? true/false
```

**Pregunta:** ¿Dice `false` o `true`?

### 4. ¿Qué muestra el HTML generado?
Busca en los logs:
```
📄 HTML AFTER renderTemplate (first 500 chars): ...
```

**Pregunta:** ¿Muestra datos reales o sigue mostrando "_____"?

## Posibles Problemas y Soluciones

### Problema A: Template no se carga (length = 0 o error)
**Solución:** Verificar que existe `/public/contratos/pagare.txt`

### Problema B: Payload está vacío (guardian = null o undefined)
**Solución:** Verificar que el usuario tiene apoderado en la BD

### Problema C: Placeholders NO se reemplazan (Contains = true)
**Solución:** Bug en función renderTemplate - necesita fix

### Problema D: Placeholders SÍ se reemplazan (Contains = false) pero HTML sigue mostrando "_____"
**Solución:** Problema con display - verificar dangerouslySetInnerHTML

---

## 📋 Por favor copia y pega TODOS los logs aquí:

```
[PEGA LOS LOGS AQUÍ]
```

Con esta información podré identificar EXACTAMENTE dónde está fallando el sistema.
