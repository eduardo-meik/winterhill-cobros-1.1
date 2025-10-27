import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

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
}

/**
 * Add professional header with logo
 */
async function addPDFHeader(pdf: jsPDF, pageWidth: number): Promise<number> {
  const headerHeight = 35; // mm
  
  // Logo (assumes logo exists in public folder)
  try {
    const logoImg = new Image();
    logoImg.src = '/logo-winterhill.png';
    await new Promise((resolve, reject) => {
      logoImg.onload = resolve;
      logoImg.onerror = reject;
      setTimeout(reject, 3000); // 3s timeout
    });
    
    // Add logo (centered, 30mm width)
    const logoWidth = 30;
    const logoHeight = 20;
    pdf.addImage(logoImg, 'PNG', (pageWidth - logoWidth) / 2, 10, logoWidth, logoHeight);
  } catch (error) {
    console.warn('Logo not loaded, skipping header image');
  }
  
  // School name and RUT
  pdf.setFontSize(12);
  pdf.setFont('helvetica', 'bold');
  pdf.text('CORPORACIÓN EDUCACIONAL WINTERHILL', pageWidth / 2, 32, {
    align: 'center'
  });
  
  pdf.setFontSize(10);
  pdf.setFont('helvetica', 'normal');
  pdf.text('RUT: 65.152.884-4', pageWidth / 2, 37, {
    align: 'center'
  });
  
  // Horizontal line below header
  pdf.setDrawColor(0, 0, 0);
  pdf.setLineWidth(0.5);
  pdf.line(15, headerHeight + 5, pageWidth - 15, headerHeight + 5);
  
  return headerHeight + 10; // Return content start position
}

/**
 * Add signature section at bottom
 */
function addSignatureSection(
  pdf: jsPDF, 
  pageWidth: number, 
  pageHeight: number,
  guardianRun?: string
) {
  const signatureY = pageHeight - 60;
  
  // Horizontal line above signatures
  pdf.setDrawColor(0, 0, 0);
  pdf.setLineWidth(0.5);
  pdf.line(15, signatureY, pageWidth - 15, signatureY);
  
  // Title
  pdf.setFontSize(11);
  pdf.setFont('helvetica', 'bold');
  pdf.text('FIRMAS:', 20, signatureY + 10);
  
  // Guardian signature
  const col1X = 30;
  const col2X = pageWidth / 2 + 20;
  const sigY = signatureY + 25;
  
  // Signature lines
  pdf.setLineWidth(0.3);
  pdf.line(col1X, sigY, col1X + 60, sigY);
  pdf.line(col2X, sigY, col2X + 60, sigY);
  
  // Labels
  pdf.setFontSize(9);
  pdf.setFont('helvetica', 'normal');
  pdf.text('APODERADO/A', col1X, sigY + 5);
  if (guardianRun && guardianRun !== '11111111-1') {
    pdf.text(`RUN: ${guardianRun}`, col1X, sigY + 10);
  } else {
    pdf.text('RUN: _______________', col1X, sigY + 10);
  }
  
  pdf.text('CORPORACIÓN WINTERHILL', col2X, sigY + 5);
  pdf.text('RUT: 65.152.884-4', col2X, sigY + 10);
  pdf.text('Representante Legal', col2X, sigY + 15);
  
  // Date and place
  pdf.setFontSize(8);
  pdf.text(`Viña del Mar, ${new Date().toLocaleDateString('es-CL')}`, pageWidth / 2, signatureY + 55, {
    align: 'center'
  });
}

/**
 * Add watermark (BORRADOR, NO FIRMADO, etc.)
 */
function addWatermark(pdf: jsPDF, pageWidth: number, pageHeight: number, text: string) {
  pdf.setFontSize(60);
  pdf.setTextColor(220, 220, 220); // Light gray
  pdf.setFont('helvetica', 'bold');
  
  // Rotate and center
  const angle = 45;
  const x = pageWidth / 2;
  const y = pageHeight / 2;
  
  pdf.text(text, x, y, {
    align: 'center',
    angle
  });
  
  // Reset color
  pdf.setTextColor(0, 0, 0);
}

/**
 * Generate PDF from HTML content with professional styling
 */
export async function generatePDFFromHTML(
  options: PDFGenerationOptions
): Promise<Blob> {
  const {
    htmlContent,
    orientation = 'portrait',
    format = 'a4',
    margin = 20,
    includeHeader = true,
    includeSignatureSection = true,
    watermark,
    guardianRun
  } = options;

  // Create PDF
  const pdf = new jsPDF({
    orientation,
    unit: 'mm',
    format
  });

  const pageWidth = pdf.internal.pageSize.getWidth();
  const pageHeight = pdf.internal.pageSize.getHeight();
  
  let contentStartY = margin;

  // Add header with logo
  if (includeHeader) {
    contentStartY = await addPDFHeader(pdf, pageWidth);
  }

  // Create temporary container for HTML
  const container = document.createElement('div');
  container.innerHTML = htmlContent;
  container.style.position = 'absolute';
  container.style.left = '-9999px';
  container.style.width = `${pageWidth - 2 * margin}mm`;
  container.style.padding = `${margin}mm`;
  container.style.paddingTop = `${contentStartY}mm`;
  container.style.paddingBottom = includeSignatureSection ? '70mm' : `${margin}mm`;
  container.style.backgroundColor = 'white';
  container.style.fontFamily = 'Arial, Helvetica, sans-serif';
  container.style.fontSize = '11pt';
  container.style.lineHeight = '1.5';
  container.style.color = '#000';
  
  // Add professional styling to content
  container.style.textAlign = 'justify';
  
  document.body.appendChild(container);

  try {
    // Capture HTML as canvas
    const canvas = await html2canvas(container, {
      scale: 2, // High quality (300 DPI equivalent)
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      windowWidth: container.scrollWidth,
      windowHeight: container.scrollHeight
    } as any); // Type assertion needed as scale is not in official types but works in practice

    // Calculate dimensions
    const imgWidth = pageWidth - 2 * margin;
    const imgHeight = (canvas.height * imgWidth) / canvas.width;
    
    const availableHeight = includeSignatureSection 
      ? pageHeight - contentStartY - 70 
      : pageHeight - contentStartY - margin;

    let heightLeft = imgHeight;
    let position = contentStartY;

    // Add first page content
    pdf.addImage(
      canvas.toDataURL('image/png'),
      'PNG',
      margin,
      position,
      imgWidth,
      imgHeight,
      undefined,
      'FAST' // Compression
    );
    
    heightLeft -= availableHeight;

    // Add additional pages if content overflows
    while (heightLeft > 0) {
      position = heightLeft - imgHeight + contentStartY;
      pdf.addPage();
      
      // Re-add header on new pages
      if (includeHeader) {
        await addPDFHeader(pdf, pageWidth);
      }
      
      pdf.addImage(
        canvas.toDataURL('image/png'),
        'PNG',
        margin,
        position,
        imgWidth,
        imgHeight,
        undefined,
        'FAST'
      );
      
      heightLeft -= availableHeight;
    }

    // Add signature section on last page
    if (includeSignatureSection) {
      addSignatureSection(pdf, pageWidth, pageHeight, guardianRun);
    }

    // Add watermark if specified
    if (watermark) {
      // Add watermark to all pages
      const totalPages = pdf.internal.pages.length - 1; // -1 because first item is metadata
      for (let i = 1; i <= totalPages; i++) {
        pdf.setPage(i);
        addWatermark(pdf, pageWidth, pageHeight, watermark);
      }
    }

    // Add metadata
    pdf.setProperties({
      title: 'Pagaré - Contrato de Prestación de Servicios Educacionales',
      subject: 'Contrato de Matrícula Colegio Winterhill',
      author: 'Corporación Educacional Winterhill',
      keywords: 'pagare, matricula, educacion, contrato',
      creator: 'Sistema de Matrícula Winterhill'
    });

    // Return as blob
    return pdf.output('blob');
    
  } finally {
    // Cleanup
    document.body.removeChild(container);
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
