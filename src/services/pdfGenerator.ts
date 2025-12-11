export interface PDFGenerationOptions {
  htmlContent: string;
  filename?: string;
  orientation?: 'portrait' | 'landscape';
  format?: 'a4' | 'letter';
  margin?: number; // in mm
  includeHeader?: boolean;
  includeSignatureSection?: boolean;
  watermark?: string; // 'BORRADOR', 'NO FIRMADO', etc.
  guardianRun?: string;
  folioNumber?: string; // Número de folio del documento
  metadata?: {
    title?: string;
    subject?: string;
    author?: string;
    keywords?: string;
    creator?: string;
  };
  assetBaseUrl?: string;
}

const DEFAULT_PDF_SERVICE_URL = 'https://pdf-service-3ypq.onrender.com/api/render-pdf';
const PDF_SERVICE_TIMEOUT_MS = Number(import.meta.env?.VITE_PDF_SERVICE_TIMEOUT_MS || '25000');

type RemoteMarginPayload =
  | number
  | {
      top?: number;
      right?: number;
      bottom?: number;
      left?: number;
    };

interface RemotePDFRequest {
  html: string;
  assetBaseUrl?: string;
  options: {
    format: string;
    landscape: boolean;
    margin: RemoteMarginPayload;
    printBackground: boolean;
    displayHeaderFooter?: boolean;
    headerTemplate?: string;
    footerTemplate?: string;
  };
  metadata?: PDFGenerationOptions['metadata'];
  watermark?: string;
  guardianRun?: string;
  folioNumber?: string;
  includeHeader?: boolean;
  includeSignatureSection?: boolean;
}

export async function generatePDFFromHTML(options: PDFGenerationOptions): Promise<Blob> {
  // Para contratos y documentos legales, usamos SIEMPRE el servicio remoto
  // basado en Puppeteer. No se hace fallback a html2canvas/jsPDF.
  return generatePuppeteerPDFFromHTML(options);
}

function resolveAssetBaseUrl(candidate?: string): string | undefined {
  const trimmed = candidate?.trim();
  if (trimmed && /^https?:\/\//i.test(trimmed)) {
    return trimmed.endsWith('/') ? trimmed : `${trimmed}/`;
  }

  if (typeof window !== 'undefined' && window.location?.origin) {
    const origin = window.location.origin;
    return origin.endsWith('/') ? origin : `${origin}/`;
  }

  return undefined;
}

function buildRemotePayload(options: PDFGenerationOptions): RemotePDFRequest {
  const {
    htmlContent,
    orientation = 'portrait',
    format = 'letter',
    margin = 20,
    includeHeader = true,
    includeSignatureSection = true,
    watermark,
    guardianRun,
    folioNumber,
    metadata,
    assetBaseUrl,
  } = options;

  if (!htmlContent || typeof htmlContent !== 'string') {
    throw new Error('Se requiere htmlContent para generar el PDF');
  }

  // Custom Header Logic:
  // If includeHeader is requested, we override the default backend header (which contains unwanted text)
  // and instead provide a custom Puppeteer template that ONLY shows the Folio number.
  let finalIncludeHeader = includeHeader;
  let displayHeaderFooter = false;
  let headerTemplate = '';
  let footerTemplate = '';

  if (includeHeader) {
    // Disable backend's default header generation
    finalIncludeHeader = false;
    // Enable Puppeteer's header/footer
    displayHeaderFooter = true;
    
    const folioText = folioNumber ? `Folio: ${folioNumber}` : '';
    
    // Custom header template: Right-aligned Folio, small font
    // Note: Puppeteer templates require explicit font-size and margins to render correctly.
    // We use padding to align roughly with the content margins.
    headerTemplate = `
      <div style="font-size: 9px; width: 100%; text-align: right; padding-right: 2cm; font-family: Arial, sans-serif; color: #333; margin-top: 10px;">
        ${folioText}
      </div>
    `;
    
    // Empty footer to suppress default browser footer (URL, page number, etc.)
    footerTemplate = '<div style="font-size: 0px;"></div>';
  }

  return {
    html: htmlContent,
    assetBaseUrl: resolveAssetBaseUrl(assetBaseUrl),
    options: {
      format: format.toUpperCase(),
      landscape: orientation === 'landscape',
      margin,
      printBackground: true,
      displayHeaderFooter,
      headerTemplate,
      footerTemplate,
    },
    metadata,
    watermark,
    guardianRun,
    folioNumber,
    includeHeader: finalIncludeHeader,
    includeSignatureSection,
  };
}

async function generatePuppeteerPDFFromHTML(options: PDFGenerationOptions): Promise<Blob> {
  const serviceUrl = (import.meta.env?.VITE_PDF_SERVICE_URL || '').trim() || DEFAULT_PDF_SERVICE_URL;
  const payload = buildRemotePayload(options);
  const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
  const timeoutId = controller ? window.setTimeout(() => controller.abort(), PDF_SERVICE_TIMEOUT_MS) : null;

  try {
    const response = await fetch(serviceUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller?.signal,
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => response.statusText);
      throw new Error(`Remote PDF service error: ${response.status} ${errorText}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    return new Blob([arrayBuffer], { type: 'application/pdf' });
  } finally {
    if (timeoutId) window.clearTimeout(timeoutId);
  }
}

/**
 * Download PDF blob as file
 */
export function downloadPDFBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

/**
 * Preview PDF in new tab
 */
export function previewPDFBlob(blob: Blob) {
  const url = URL.createObjectURL(blob);
  window.open(url, '_blank');
}
