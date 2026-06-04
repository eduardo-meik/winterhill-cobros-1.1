---
name: enterprise-audit
description: "Use when performing code review, PR review, security audit, compliance check, or technical debt analysis. Applies ISO 27001, OWASP Top 10, and quality standards to the codebase."
---

# Enterprise-Grade Code Auditor — Gestión Escolar

## Overview

Auditor de seguridad y calidad para **Gestión Escolar**. Stack: React Vite + Supabase. Estándares: ISO 27001, OWASP Top 10, ISO 25010.

## Protocolo de Revisión

### Paso 1 — Escaneo de Prioridad 0 (Leaks)

Antes de analizar lógica, buscar con Regex:
- Claves de API hardcodeadas (patrones `AIza`, `sk-`, `ghp_`)
- JWT secrets en código fuente
- Variables de entorno expuestas en código cliente
- Archivos `.json` con service account keys fuera de `.gitignore`

> **Si detectas credenciales reales, detén la revisión y emite aviso de seguridad inmediato.**

### Paso 2 — Análisis por Capas

| Capa | Qué verificar |
|:---|:---|
| **Seguridad** | OWASP Top 10: inyección, XSS, CSRF, broken auth, SSRF |
| **Calidad** | Complejidad ciclomática (máx 10), DRY, separación de responsabilidades |
| **Tests** | Módulos sin archivos `.test.*` o `.spec.*` correspondientes |
| **Soberanía** | URLs de API con separación de ambientes (dev/staging/prod) |

### Paso 3 — Backlog de Deuda Técnica

Para hallazgos de severidad Media o superior:

| ID | Hallazgo | Severidad | Esfuerzo | Archivo | Acción |
|:---|:---|:---|:---|:---|:---|
| TD-1 | Función sin tests | Alta | 2h | `src/lib/X.ts` | Crear tests |
| TD-2 | Lógica duplicada en 3 archivos | Media | 1h | `src/app/api/...` | Extraer helper |

**Esfuerzo:** S (<1h), M (1-4h), L (4-8h), XL (>8h)

## Formato de Salida

| ID | Categoría | Hallazgo | Severidad | Estándar | Sugerencia |
|:---|:---|:---|:---|:---|:---|
| EX-S1 | Seguridad | Secret hardcodeado | CRÍTICA | ISO 27001 A.10.1 | Mover a env vars |
| EX-C1 | Calidad | Complejidad > 10 | Media | ISO 25010 | Refactorizar |
| EX-A1 | Auditoría | Login sin log | Alta | ISO 27001 A.12.4.1 | Agregar structured log |
| EX-T1 | Tests | Módulo sin tests | Alta | ISO 25010 | Crear test suite |

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| A1 | Credencial real en código fuente |
| A2 | API route sin validación de input |
| A3 | Módulo crítico (auth, API) sin tests |
| A4 | Complejidad ciclomática > 15 sin justificación |
| A5 | PII en logs sin enmascarar |
| A6 | Dependencia con CVE crítica no resuelta |
