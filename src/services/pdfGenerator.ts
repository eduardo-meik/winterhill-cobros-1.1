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
  folioNumber?: string; // Número de folio del documento
  metadata?: {
    title?: string;
    subject?: string;
    author?: string;
    keywords?: string;
    creator?: string;
  };
}

/**
 * Add professional header with logo (aligned left) - REDUCIDO AL 25%
 */
async function addPDFHeader(pdf: jsPDF, pageWidth: number, folioNumber?: string): Promise<number> {
  const headerHeight = 20; // mm - REDUCIDO de 35 a 20 (aprox 25% menos)
  const leftMargin = 15;
  
  // Logo (aligned to the left, proportional) - MÁS PEQUEÑO
  try {
    const logoImg = new Image();
    logoImg.src = '/logo-winterhill.png';
    await new Promise((resolve, reject) => {
      logoImg.onload = resolve;
      logoImg.onerror = reject;
      setTimeout(reject, 3000); // 3s timeout
    });
    
    // Calculate proportional dimensions (maintaining aspect ratio) - REDUCIDO
    const maxLogoWidth = 20; // Reducido de 35 a 20
    const maxLogoHeight = 15; // Reducido de 25 a 15
    const logoAspectRatio = logoImg.width / logoImg.height;
    
    let logoWidth = maxLogoWidth;
    let logoHeight = logoWidth / logoAspectRatio;
    
    // Adjust if height exceeds max
    if (logoHeight > maxLogoHeight) {
      logoHeight = maxLogoHeight;
      logoWidth = logoHeight * logoAspectRatio;
    }
    
    // Add logo (left-aligned)
    pdf.addImage(logoImg, 'PNG', leftMargin, 5, logoWidth, logoHeight);
  } catch (error) {
    console.warn('Logo not loaded, skipping header image');
  }
  
  // School name and RUT (aligned with logo on the right side) - MÁS COMPACTO
  const textStartX = 40; // Reducido de 55 a 40
  
  pdf.setFontSize(9); // Reducido de 12 a 9
  pdf.setFont('helvetica', 'bold');
  pdf.text('CORPORACIÓN EDUCACIONAL WINTERHILL', textStartX, 10);
  
  pdf.setFontSize(7); // Reducido de 10 a 7
  pdf.setFont('helvetica', 'normal');
  pdf.text('RUT: 65.152.884-4 | Viña del Mar', textStartX, 14);
  
  // Add folio number (top right corner)
  if (folioNumber) {
    pdf.setFontSize(8); // Reducido de 10 a 8
    pdf.setFont('helvetica', 'bold');
    pdf.text(`FOLIO N° ${folioNumber}`, pageWidth - 15, 8, { align: 'right' });
  }
  
  // Horizontal line below header - MÁS DELGADA
  pdf.setDrawColor(0, 51, 102); // Dark blue
  pdf.setLineWidth(0.5); // Reducido de 0.8 a 0.5
  pdf.line(15, headerHeight + 2, pageWidth - 15, headerHeight + 2);
  
  return headerHeight + 5; // Return content start position - REDUCIDO
}

/**
 * Add signature section at bottom with BOXES
 */
function addSignatureSection(
  pdf: jsPDF, 
  pageWidth: number, 
  pageHeight: number,
  guardianRun?: string
) {
  const signatureY = pageHeight - 65; // Más espacio
  
  // Horizontal line above signatures
  pdf.setDrawColor(0, 0, 0);
  pdf.setLineWidth(0.5);
  pdf.line(15, signatureY, pageWidth - 15, signatureY);
  
  // Title
  pdf.setFontSize(11);
  pdf.setFont('helvetica', 'bold');
  pdf.text('FIRMAS:', 20, signatureY + 8);
  
  // Signature boxes
  const col1X = 25;
  const col2X = pageWidth / 2 + 10;
  const boxY = signatureY + 12;
  const boxWidth = 75;
  const boxHeight = 35;
  
  // BOX 1 - APODERADO/A (con borde)
  pdf.setDrawColor(0, 51, 102); // Dark blue border
  pdf.setLineWidth(0.8);
  pdf.rect(col1X, boxY, boxWidth, boxHeight);
  
  // Signature line inside box
  pdf.setDrawColor(0, 0, 0);
  pdf.setLineWidth(0.3);
  const sigLineY = boxY + 22;
  pdf.line(col1X + 10, sigLineY, col1X + boxWidth - 10, sigLineY);
  
  // Labels inside box
  pdf.setFontSize(9);
  pdf.setFont('helvetica', 'bold');
  pdf.text('APODERADO/A', col1X + boxWidth / 2, boxY + 6, { align: 'center' });
  
  pdf.setFont('helvetica', 'normal');
  pdf.setFontSize(8);
  if (guardianRun && guardianRun !== '11111111-1') {
    pdf.text(`RUN: ${guardianRun}`, col1X + boxWidth / 2, sigLineY + 5, { align: 'center' });
  } else {
    pdf.text('RUN: _______________', col1X + boxWidth / 2, sigLineY + 5, { align: 'center' });
  }
  pdf.text('Firma', col1X + boxWidth / 2, sigLineY - 3, { align: 'center' });
  
  // BOX 2 - CORPORACIÓN WINTERHILL (con borde)
  pdf.setDrawColor(0, 51, 102); // Dark blue border
  pdf.setLineWidth(0.8);
  pdf.rect(col2X, boxY, boxWidth, boxHeight);
  
  // Signature line inside box
  pdf.setDrawColor(0, 0, 0);
  pdf.setLineWidth(0.3);
  pdf.line(col2X + 10, sigLineY, col2X + boxWidth - 10, sigLineY);
  
  // Labels inside box
  pdf.setFontSize(9);
  pdf.setFont('helvetica', 'bold');
  pdf.text('CORPORACIÓN WINTERHILL', col2X + boxWidth / 2, boxY + 6, { align: 'center' });
  
  pdf.setFont('helvetica', 'normal');
  pdf.setFontSize(8);
  pdf.text('RUT: 65.152.884-4', col2X + boxWidth / 2, boxY + 12, { align: 'center' });
  pdf.text('Firma', col2X + boxWidth / 2, sigLineY - 3, { align: 'center' });
  pdf.text('Representante Legal', col2X + boxWidth / 2, sigLineY + 5, { align: 'center' });
  
  // Date and place
  pdf.setFontSize(8);
  pdf.setFont('helvetica', 'normal');
  pdf.text(`Viña del Mar, ${new Date().toLocaleDateString('es-CL')}`, pageWidth / 2, boxY + boxHeight + 8, {
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
 * Add page numbers to all pages
 */
function addPageNumbers(pdf: jsPDF, pageWidth: number, pageHeight: number) {
  const totalPages = pdf.getNumberOfPages();
  
  for (let i = 1; i <= totalPages; i++) {
    pdf.setPage(i);
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(100, 100, 100); // Gray
    pdf.text(
      `Página ${i} de ${totalPages}`,
      pageWidth / 2,
      pageHeight - 10,
      { align: 'center' }
    );
    pdf.setTextColor(0, 0, 0); // Reset to black
  }
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
    watermark, // Nota: Ya no se usa por defecto
    guardianRun,
    folioNumber,
    metadata
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

  // Add header with logo and folio
  if (includeHeader) {
    contentStartY = await addPDFHeader(pdf, pageWidth, folioNumber);
  }

  // Create temporary container for HTML
  const container = document.createElement('div');
  container.innerHTML = htmlContent;
  container.style.position = 'absolute';
  container.style.left = '-9999px';
  container.style.width = `${pageWidth - 2 * margin}mm`;
  container.style.padding = `${margin}mm`;
  container.style.paddingTop = `${contentStartY}mm`;
  container.style.paddingBottom = includeSignatureSection ? '90mm' : '40mm'; // AUMENTADO: 90mm/40mm (era 80mm/30mm)
  container.style.backgroundColor = 'white';
  container.style.fontFamily = 'Arial, Helvetica, sans-serif';
  container.style.fontSize = '11pt';
  container.style.lineHeight = '1.6'; // Mejor espaciado
  container.style.color = '#000';
  
  // Add professional styling to content - MANTENER SALTOS DE LÍNEA
  container.style.textAlign = 'justify';
  container.style.whiteSpace = 'pre-wrap'; // Mantiene saltos de línea
  container.style.wordWrap = 'break-word';
  
  // Estilos para tablas (evitar sobreposición)
  const tables = container.querySelectorAll('table');
  tables.forEach(table => {
    (table as HTMLElement).style.width = '100%';
    (table as HTMLElement).style.borderCollapse = 'collapse';
    (table as HTMLElement).style.marginTop = '15px';
    (table as HTMLElement).style.marginBottom = '15px';
    (table as HTMLElement).style.pageBreakInside = 'avoid'; // Evitar corte de tabla
    (table as HTMLElement).style.border = '1px solid #333';
    
    // Estilo para celdas
    const cells = table.querySelectorAll('td, th');
    cells.forEach(cell => {
      (cell as HTMLElement).style.padding = '8px';
      (cell as HTMLElement).style.border = '1px solid #666';
      (cell as HTMLElement).style.fontSize = '10pt';
    });
    
    // Estilo para encabezados
    const headers = table.querySelectorAll('th');
    headers.forEach(header => {
      (header as HTMLElement).style.backgroundColor = '#003366';
      (header as HTMLElement).style.color = 'white';
      (header as HTMLElement).style.fontWeight = 'bold';
    });
  });
  
  document.body.appendChild(container);

  try {
    // Capture HTML as canvas
    const canvas = await html2canvas(container, {
      scale: 2.5, // Mayor calidad para mejor renderizado
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      windowWidth: container.scrollWidth,
      windowHeight: container.scrollHeight,
      imageTimeout: 0,
      removeContainer: false
    } as any);

    // Calculate dimensions
    const imgWidth = pageWidth - 2 * margin;
    const imgHeight = (canvas.height * imgWidth) / canvas.width;
    
    const availableHeight = includeSignatureSection 
      ? pageHeight - contentStartY - 90 // AUMENTADO: Mayor espacio para firmas (era 80)
      : pageHeight - contentStartY - 40; // AUMENTADO: Mayor margen inferior (era 30)

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
      'FAST'
    );
    
    heightLeft -= availableHeight;

    // Add additional pages if content overflows
    while (heightLeft > 0) {
      position = heightLeft - imgHeight + contentStartY;
      pdf.addPage();
      
      // RE-ADD HEADER ON ALL PAGES (SIEMPRE)
      if (includeHeader) {
        await addPDFHeader(pdf, pageWidth, folioNumber);
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

    // ADD PAGE NUMBERS TO ALL PAGES
    addPageNumbers(pdf, pageWidth, pageHeight);

    // MARCA DE AGUA REMOVIDA - Solo se agrega si se pasa explícitamente
    // if (watermark) { ... } - Comentado para quitar marca de agua por defecto

    // Add metadata (allow override)
    pdf.setProperties({
      title: metadata?.title || 'Pagaré - Contrato de Prestación de Servicios Educacionales',
      subject: metadata?.subject || 'Contrato de Matrícula Colegio Winterhill',
      author: metadata?.author || 'Corporación Educacional Winterhill',
      keywords: metadata?.keywords || 'pagare, matricula, educacion, contrato',
      creator: metadata?.creator || 'Sistema de Matrícula Winterhill'
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
