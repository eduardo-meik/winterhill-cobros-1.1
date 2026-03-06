# Puppeteer PDF Service

This branch introduces an initial server-rendered PDF pipeline using Puppeteer. The goal is to replace the current html2canvas + jsPDF stack with a Chrome-quality renderer while keeping the browser workflow as a fallback during the migration.

## What’s Included

- `api/render-pdf.ts`: Vercel serverless function that launches headless Chromium (via `@sparticuz/chromium`) to render provided HTML into a PDF buffer.
- `src/services/pdfGenerator.ts`: Client-side dispatcher that prefers the Puppeteer service when `VITE_PDF_ENGINE=puppeteer` and silently falls back to the legacy renderer if the request fails or times out.
- Environment variables to toggle engines and tune the remote call timeout.
- SPA rewrite exclusions in `vercel.json` so `/api/*` routes reach the new handler.

## Runtime Configuration

| Variable | Scope | Description |
| --- | --- | --- |
| `VITE_PDF_ENGINE` | Vite | Set to `puppeteer` to enable the remote flow. Defaults to `browser`. |
| `VITE_PDF_SERVICE_URL` | Vite | Optional override for the API endpoint (defaults to `/api/render-pdf`). |
| `VITE_PDF_SERVICE_TIMEOUT_MS` | Vite | Abort the remote fetch after this many milliseconds (fallback triggers afterwards). |
| `PDF_ASSET_BASE_URL` | Server | Optional absolute URL used as `<base>` when rendering so static assets (e.g. `/logo-winterhill.png`) resolve correctly. If omitted, the client-provided origin is used. |

## Local Development

1. Install dependencies if you haven’t already: `npm install`.
2. Run `npm run dev` for the Vite front-end as usual.
3. To exercise the Puppeteer route locally, start a second terminal and run `npx vercel dev`. Point `VITE_PDF_SERVICE_URL` to `http://localhost:3000/api/render-pdf` and enable `VITE_PDF_ENGINE=puppeteer`.
4. If the serverless function is not running, the UI automatically falls back to browser PDF generation to avoid blocking flows.

## Next Steps

- Migrate individual document flows (matrícula, repactación, recibos) to opt into `VITE_PDF_ENGINE=puppeteer` in staging.
- Expand the serverless handler to honour headers/signature boxes and watermark options on the server side.
- Evaluate handling of assets (fonts/images) for production and define caching strategy.
- Add integration tests that hit `/api/render-pdf` with representative HTML payloads.
