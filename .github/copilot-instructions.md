## Gestión Escolar — Agent Skills

**Stack:** React Vite + Supabase | Testing: Ambos (Jest + Playwright)

## Enterprise Compliance Layer
- Siempre que el usuario pida un "Review" o "PR", activa automáticamente la skill `enterprise-audit`.

## Skills Disponibles

Las siguientes skills están disponibles en `.github/skills/` y se activan por descripción:

- **security-guardrails**: Use when creating or modifying API routes, handling user input, managing secrets, or reviewing code for security vulnerabilities. Enforces Zod/Pydantic validation, parameterized queries, and OWASP Top 10 prevention.
- **brainstorming-contracts**: Use when designing new features, API endpoints, or database schemas. Forces contract-first design: define schemas, API surface, and error contracts before writing implementation code.
- **error-handling-patterns**: Use when implementing error boundaries, API error responses, retry logic, stream error recovery, or structured error logging. Covers UI error boundaries, typed API errors, and SSE stream patterns.
- **logging-sanitizer**: Use when reviewing logs for PII exposure, implementing structured logging, or ensuring GDPR/ISO 27701 compliance in log output. Verifies log integrity, PII masking, and audit trail completeness.
- **dependency-check**: Use when auditing dependencies for license compliance (ISO/IEC 5230), outdated packages, vulnerability scanning, or supply chain analysis. Analyzes package.json or requirements.txt.
- **enterprise-audit**: Use when performing code review, PR review, security audit, compliance check, or technical debt analysis. Applies ISO 27001, OWASP Top 10, and quality standards to the codebase.
- **react-vite-standards**: Use when creating components, hooks, or pages in a React + Vite project. Enforces functional components, hook patterns, folder structure, and performance best practices.
- **design-system**: Use when creating UI components, choosing colors, defining typography, implementing dark mode, or reviewing accessibility. Enforces semantic tokens, shadcn/ui primitives, and WCAG 2.2 AA compliance.
- **supabase-architect**: Use when working with Supabase: database queries, RLS policies, Auth, Edge Functions, or Storage. Enforces parameterized queries, RLS by default, and migration-based schema changes.
- **testing-domain**: Use when writing unit tests, integration tests, creating mocks, or setting up test infrastructure. Covers Jest/Vitest patterns, mock strategies, API route testing, and coverage thresholds.
- **playwright-e2e**: Use when writing E2E tests, setting up Playwright, or automating browser interactions. Enforces data-testid selectors, test isolation, explicit waits, and CI/CD integration.

## Jerarquía de Archivos

1. `.github/copilot-instructions.md` (Este archivo — Índice maestro)
2. `.github/skills/*.md` (Skills individuales con reglas específicas)
3. `src/` (El código a juzgar)

## Convenciones Generales

- Cada skill tiene una tabla de **Criterios de Rechazo** con IDs únicos (S1, E1, etc.). Referenciar estos IDs en code reviews.
- Las skills se activan automáticamente según su campo `description` en el frontmatter YAML.
- Ante conflicto entre skills, prevalece `security-guardrails` sobre cualquier otra.
