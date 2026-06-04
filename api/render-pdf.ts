import type { VercelRequest, VercelResponse } from '@vercel/node';
import chromium from '@sparticuz/chromium';
import puppeteerCore, { type Browser } from 'puppeteer-core';

chromium.setGraphicsMode = false;

const isDev = process.env.NODE_ENV !== 'production' && !process.env.AWS_REGION;
const DEFAULT_ASSET_BASE = process.env.PDF_ASSET_BASE_URL;

export const config = {
  api: {
    bodyParser: false,
  },
};

type MarginInput =
  | number
  | {
      top?: number;
      right?: number;
      bottom?: number;
      left?: number;
    };

type PdfRequestPayload = {
  html: string;
  assetBaseUrl?: string;
  options?: {
    format?: string;
    landscape?: boolean;
    margin?: MarginInput;
    printBackground?: boolean;
  };
  metadata?: {
    title?: string;
    subject?: string;
    author?: string;
    keywords?: string;
    creator?: string;
  };
  watermark?: string;
  includeHeader?: boolean;
  includeSignatureSection?: boolean;
  guardianRun?: string;
  folioNumber?: string;
};

let browserPromise: Promise<Browser> | null = null;

async function getBrowser(): Promise<Browser> {
  if (!browserPromise) {
    if (isDev) {
      const puppeteerModule: any = await import('puppeteer');
      const puppeteer = puppeteerModule?.default ?? puppeteerModule;
      browserPromise = puppeteer.launch({
        headless: 'new',
        args: ['--font-render-hinting=none'],
      });
    } else {
      const executablePath = await chromium.executablePath();
      browserPromise = puppeteerCore.launch({
        args: chromium.args,
        defaultViewport: null,
        executablePath,
        headless: 'shell',
      });
    }
  }
  return browserPromise!;
}

function readRequestBody(req: VercelRequest): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    req.on('data', (chunk) => {
      chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
    });

    req.on('end', () => {
      resolve(Buffer.concat(chunks).toString('utf8'));
    });

    req.on('error', (err) => reject(err));
  });
}

function toMillimeters(value?: number, fallback = '20mm'): string {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) {
    return `${value}mm`;
  }
  return fallback;
}

function normalizeMargin(input?: MarginInput): { top: string; right: string; bottom: string; left: string } {
  if (typeof input === 'number') {
    const mm = toMillimeters(input);
    return { top: mm, right: mm, bottom: mm, left: mm };
  }

  if (input && typeof input === 'object') {
    return {
      top: toMillimeters(input.top),
      right: toMillimeters(input.right),
      bottom: toMillimeters(input.bottom),
      left: toMillimeters(input.left),
    };
  }

  const fallback = '20mm';
  return { top: fallback, right: fallback, bottom: fallback, left: fallback };
}

function injectBaseHref(html: string, assetBaseUrl?: string): string {
  const base = assetBaseUrl?.trim() || DEFAULT_ASSET_BASE || '';
  if (!base) return html;

  if (/<base\s[^>]*href=/i.test(html)) {
    return html;
  }

  const normalized = base.endsWith('/') ? base : `${base}/`;
  const baseTag = `<base href="${normalized}">`;

  if (/<head[^>]*>/i.test(html)) {
    return html.replace(/<head([^>]*)>/i, `<head$1>\n${baseTag}`);
  }

  return `<head>${baseTag}</head>${html}`;
}

async function renderPdf(payload: PdfRequestPayload): Promise<Buffer> {
  const browser = await getBrowser();
  const page = await browser.newPage();

  try {
    const htmlWithBase = injectBaseHref(payload.html, payload.assetBaseUrl);

    await page.setContent(htmlWithBase, { waitUntil: 'networkidle0' });
    try {
      await page.emulateMediaType('print');
    } catch {
      // Ignore if emulateMediaType is not available in current runtime
    }

    const options = payload.options ?? {};
    const margin = normalizeMargin(options.margin);
    const format = (options.format || 'A4').toString().toUpperCase();
    const landscape = !!options.landscape;
    const printBackground = options.printBackground !== false;

    const pdfBuffer = await page.pdf({
      format: format as any,
      landscape,
      printBackground,
      preferCSSPageSize: true,
      margin,
    });

    return Buffer.from(pdfBuffer);
  } finally {
    await page.close();
  }
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }

  let payload: PdfRequestPayload;

  try {
    const raw = await readRequestBody(req);
    payload = raw ? (JSON.parse(raw) as PdfRequestPayload) : ({} as PdfRequestPayload);
  } catch (error) {
    console.error('[render-pdf] Invalid request payload', error);
    res.status(400).json({ error: 'Invalid JSON payload' });
    return;
  }

  if (!payload?.html || typeof payload.html !== 'string') {
    res.status(400).json({ error: 'Missing html in request body' });
    return;
  }

  try {
    const pdfBuffer = await renderPdf(payload);
    res.status(200);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Cache-Control', 'no-store');
    res.send(pdfBuffer);
  } catch (error) {
    console.error('[render-pdf] Failed to render PDF', error);
    res.status(500).json({ error: 'Failed to render PDF' });
  }
}
