const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins
app.use(cors({
  origin: '*', // Allow any origin
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));

app.post('/api/render-pdf', async (req, res) => {
  const body = req.body || {};
  const html = body.html || body.htmlContent;
  
  // Extract options from body.options or body root to support both formats
  const options = body.options || {};
  
  const format = options.format || body.format || 'Letter';
  const landscape = options.landscape || (body.orientation === 'landscape');
  const printBackground = options.printBackground !== undefined ? options.printBackground : true;
  
  let margin = options.margin || body.margin || { top: '20mm', right: '15mm', bottom: '20mm', left: '15mm' };
  
  // Normalize margin if it's a number (Puppeteer requires an object)
  if (typeof margin === 'number' || typeof margin === 'string') {
    margin = {
      top: margin,
      right: margin,
      bottom: margin,
      left: margin
    };
  }

  const metadata = body.metadata || {};

  if (!html || typeof html !== 'string') {
    return res.status(400).json({ error: 'html is required and must be a string' });
  }

  let browser;
  try {
    // Use puppeteer.executablePath() to dynamically find the installed Chrome
    browser = await puppeteer.launch({
      headless: 'new',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
      ],
    });
    const page = await browser.newPage();

    if (metadata && metadata.title) {
      await page.evaluateOnNewDocument(title => {
        document.title = title;
      }, metadata.title);
    }

    await page.setContent(html, { waitUntil: 'networkidle0' });

    const pdfBuffer = await page.pdf({
      format,
      landscape,
      printBackground,
      margin,
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
