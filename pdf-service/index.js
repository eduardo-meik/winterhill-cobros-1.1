const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer');
const puppeteerCore = require('puppeteer-core');
const chromium = require('@sparticuz/chromium');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins
app.use(cors({
  origin: '*', // Allow any origin
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));

function normalizeMargin(rawMargin) {
  const fallback = { top: '20mm', right: '15mm', bottom: '20mm', left: '15mm' };
  if (rawMargin == null) return fallback;

  if (typeof rawMargin === 'number') {
    const mm = `${rawMargin}mm`;
    return { top: mm, right: mm, bottom: mm, left: mm };
  }

  if (typeof rawMargin === 'string') {
    return {
      top: rawMargin,
      right: rawMargin,
      bottom: rawMargin,
      left: rawMargin,
    };
  }

  if (typeof rawMargin === 'object') {
    return {
      top: rawMargin.top || fallback.top,
      right: rawMargin.right || fallback.right,
      bottom: rawMargin.bottom || fallback.bottom,
      left: rawMargin.left || fallback.left,
    };
  }

  return fallback;
}

async function launchBrowser() {
  const commonArgs = [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
  ];

  // Strategy 1: bundled Chrome from puppeteer (works in local/dev environments).
  try {
    return await puppeteer.launch({
      headless: 'new',
      args: commonArgs,
    });
  } catch (puppeteerErr) {
    console.warn('[pdf-service] puppeteer.launch failed, trying @sparticuz/chromium fallback:', puppeteerErr?.message);
  }

  // Strategy 2: Chromium binary optimized for serverless/container environments.
  const executablePath = await chromium.executablePath();
  return puppeteerCore.launch({
    executablePath,
    args: [...chromium.args, ...commonArgs],
    defaultViewport: chromium.defaultViewport,
    headless: 'shell',
  });
}

app.post('/api/render-pdf', async (req, res) => {
  const body = req.body || {};
  const html = body.html || body.htmlContent;
  
  // Extract options from body.options or body root to support both formats
  const options = body.options || {};
  
  const format = options.format || body.format || 'Letter';
  const landscape = options.landscape || (body.orientation === 'landscape');
  const printBackground = options.printBackground !== undefined ? options.printBackground : true;
  const margin = normalizeMargin(options.margin || body.margin);

  const displayHeaderFooter = options.displayHeaderFooter === true;
  const headerTemplate = typeof options.headerTemplate === 'string' ? options.headerTemplate : '';
  const footerTemplate = typeof options.footerTemplate === 'string' ? options.footerTemplate : '';

  const metadata = body.metadata || {};

  if (!html || typeof html !== 'string') {
    return res.status(400).json({ error: 'html is required and must be a string' });
  }

  let browser;
  try {
    browser = await launchBrowser();
    const page = await browser.newPage();

    if (metadata && metadata.title) {
      await page.evaluateOnNewDocument(title => {
        document.title = title;
      }, metadata.title);
    }

    await page.setContent(html, { waitUntil: 'domcontentloaded' });

    const pdfBuffer = await page.pdf({
      format,
      landscape,
      printBackground,
      margin,
      displayHeaderFooter,
      headerTemplate,
      footerTemplate,
      preferCSSPageSize: true,
    });

    await browser.close();

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'inline; filename="documento.pdf"');
    return res.send(pdfBuffer);
  } catch (error) {
    if (browser) {
      await browser.close();
    }
    console.error('Error generating PDF:', error);
    return res.status(500).json({ error: 'Failed to generate PDF', details: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.send('PDF Service is running. Use POST /api/render-pdf to generate PDFs.');
});

app.listen(PORT, () => {
  console.log(`PDF service listening on port ${PORT}`);
});
