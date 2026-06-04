---
name: react-vite-standards
description: "Use when creating components, hooks, or pages in a React + Vite project. Enforces functional components, hook patterns, folder structure, and performance best practices."
---

# React + Vite Standards — Gestión Escolar

## Overview

Reglas para componentes, hooks y estructura en **Gestión Escolar** con React + Vite.

## Estructura de Carpetas

```
src/
├── components/        # Componentes reutilizables
│   ├── ui/            # Componentes de UI base (Button, Input, Modal)
│   └── [feature]/     # Componentes agrupados por feature
├── hooks/             # Custom hooks
├── pages/             # Vistas/rutas principales
├── services/          # Llamadas a API y lógica de datos
├── stores/            # Estado global (Zustand/Jotai)
├── types/             # Tipos TypeScript compartidos
├── utils/             # Funciones utilitarias puras
└── lib/               # Configuraciones de terceros
```

## Checklist Obligatorio

### 1. Componentes Funcionales

- Prohibido usar class components.
- Un componente por archivo, nombre PascalCase.
- Props tipadas con interfaz `Props` suffix:

```tsx
interface UserCardProps {
  name: string;
  role: 'admin' | 'viewer';
  onSelect?: (id: string) => void;
}

export function UserCard({ name, role, onSelect }: UserCardProps) {
  // ...
}
```

- No usar `any`. Preferir `unknown` si el tipo es dinámico.

### 2. Hooks

- Custom hooks empiezan con `use` y viven en `/hooks`.
- No poner lógica de negocio en componentes: extraer a hooks o services.
- Incluir todas las dependencias en `useEffect`/`useMemo`/`useCallback`.

### 3. Performance

- `React.lazy()` + `Suspense` para code splitting por ruta.
- Memoizar solo cuando hay un problema medido, no por defecto.
- Imágenes: formatos `webp`/`avif` y lazy loading nativo.

### 4. Estado

| Scope | Herramienta |
|:---|:---|
| Local | `useState` / `useReducer` |
| Global | Zustand o Jotai |
| Servidor | TanStack Query (React Query) |

### 5. Estilo

- Tailwind CSS como default.
- No CSS inline salvo valores dinámicos.
- Clases organizadas con `clsx` o `cn()`.

## Criterios de Rechazo

| ID | Regla |
|:---|:---|
| R1 | Class component |
| R2 | `any` en props o retornos |
| R3 | Lógica de negocio en componente (no en hook/service) |
| R4 | `useEffect` con dependencias faltantes |
| R5 | Múltiples componentes exportados desde un archivo |
| R6 | CSS inline extenso (>3 propiedades) |
| R7 | Import de ruta completa sin code splitting en lazy routes |
