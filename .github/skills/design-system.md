---
name: design-system
description: "Use when creating UI components, choosing colors, defining typography, implementing dark mode, or reviewing accessibility. Enforces semantic tokens, shadcn/ui primitives, and WCAG 2.2 AA compliance."
---

# Design System — Gestión Escolar

## Overview

Guía de diseño para **Gestión Escolar** con React Vite. Tokens semánticos HSL, componentes reutilizables, dark mode y accesibilidad WCAG 2.2 AA.

## Foundations

### Typography

| Role | Uso |
|:---|:---|
| Headline | Títulos de página, headers de sección |
| Body | Párrafos, labels, captions |
| Mono | Código, IDs, timestamps, valores técnicos |

### Color Tokens (HSL via CSS custom properties)

Usar siempre tokens semánticos, nunca colores raw de Tailwind:

| Token | Propósito |
|:---|:---|
| `--primary` | Brand color, CTAs, links |
| `--secondary` | Backgrounds sutiles |
| `--muted` | Áreas disabled, placeholders |
| `--destructive` | Delete, error actions |
| `--border` | Bordes, dividers |
| `--ring` | Focus rings |

### Spacing

- Border radius: `rounded-lg` (8px), `rounded-md` (6px), `rounded-sm` (4px)
- Usar `gap-*` sobre margins individuales para flex/grid

## Reglas: Hacer

1. Usar tokens semánticos: `bg-primary`, `text-muted-foreground`, nunca `bg-blue-500`
2. Usar componentes de librería UI antes de crear custom
3. Soportar dark mode en todo estilo custom
4. Diseñar para estados: default, hover, focus-visible, active, disabled, loading, error
5. Responsive first: mobile breakpoints, después scale up
6. `gap-*` sobre margins para flex/grid layouts

## Reglas: No Hacer

1. No usar color classes raw (`bg-blue-500`, `text-red-600`, `border-gray-200`)
2. No hex values en className (`bg-[#FF0000]`)
3. No mezclar escalas de grises (`slate-*` con `gray-*`)
4. No `<div>` como buttons — usar `<button>` o componente Button
5. No inline styles salvo valores dinámicos
6. No reimplementar componentes que ya existen en la librería UI

## Accessibility (WCAG 2.2 AA)

- Keyboard-first con `focus-visible` states visibles
- HTML semántico antes de ARIA (`<button>` > `<div role="button">`)
- Color nunca como único indicador — combinar con ícono o texto
- Touch targets mínimo 44×44px en mobile
- `aria-live` regions para contenido dinámico (toasts, status changes)

## Migration Guide

| Antes (hardcoded) | Después (semántico) |
|:---|:---|
| `bg-blue-500` | `bg-primary` |
| `text-gray-500` | `text-muted-foreground` |
| `text-green-600` | `text-success` |
| `bg-red-50` | `bg-destructive/10` |
| `border-gray-200` | `border-border` |

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| DS1 | Color class raw de Tailwind en lugar de token semántico |
| DS2 | Hex value en className |
| DS3 | Componente custom que duplica uno existente de UI library |
| DS4 | Elemento interactivo sin focus-visible state |
| DS5 | Contraste de texto menor a 4.5:1 |
| DS6 | Sin soporte dark mode en CSS custom |
| DS7 | `<div>` usado como botón sin role/keyboard handling |
