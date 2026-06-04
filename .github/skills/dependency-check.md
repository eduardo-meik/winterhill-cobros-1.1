---
name: dependency-check
description: "Use when auditing dependencies for license compliance (ISO/IEC 5230), outdated packages, vulnerability scanning, or supply chain analysis. Analyzes package.json or requirements.txt."
---

# Supply Chain & License Compliance — Gestión Escolar

## Overview

Análisis de cadena de suministro para **Gestión Escolar**. Verificar licencias, versiones obsoletas, vulnerabilidades y dependencias sin mantenimiento.

## Protocolo de Análisis

### Paso 1 — Lectura de Dependencias

- Leer `package.json` o `requirements.txt` (dependencies + devDependencies)
- Identificar total de paquetes y categorías (UI, data, AI, security, testing)

### Paso 2 — Criterios de Evaluación

| Criterio | Severidad | Estándar |
|:---|:---|:---|
| Licencia GPL/AGPL en módulos propietarios | CRÍTICA | ISO/IEC 5230 |
| Dependencia > 2 versiones mayores de retraso | Alta | OWASP A06:2021 |
| Librería sin mantenimiento (> 1 año sin commits) | Alta | SLSA Level 1 |
| CVE conocida sin parche disponible | CRÍTICA | OWASP A06:2021 |
| Dependencia duplicada (misma función, distinto paquete) | Media | Best Practice |

### Paso 3 — Verificación por Paquete

Para cada dependencia, verificar:

1. **Licencia:** MIT, Apache-2.0, ISC → OK. GPL/AGPL → Rechazar en código propietario
2. **Versión actual vs última estable:** Diferencia de versiones mayores
3. **Actividad del repo:** Último commit, issues abiertos, mantenedores activos
4. **Vulnerabilidades:** CVEs conocidas en la versión instalada

### Paso 4 — Comandos de Auditoría

```bash
# Node.js
npm audit
npm outdated
npx license-checker --summary

# Python
pip audit
pip list --outdated
```

## Formato de Salida

| Paquete | Versión Actual | Última | Licencia | Estado | Acción |
|:---|:---|:---|:---|:---|:---|
| next | ^16.x | 16.x | MIT | ✅ OK | - |
| example-lib | ^2.0 | 5.0 | GPL-3.0 | ❌ RECHAZAR | Buscar alternativa MIT |

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| DC1 | Dependencia con CVE crítica sin parche |
| DC2 | Licencia GPL/AGPL en código propietario |
| DC3 | Paquete sin commits en > 1 año en producción |
| DC4 | Dependencia duplicada (ej. axios + fetch wrapper + got) |
| DC5 | `npm audit` con vulnerabilidades críticas sin resolver |
