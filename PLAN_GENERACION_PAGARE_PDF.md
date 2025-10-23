# 📄 PLAN: GENERACIÓN DE PAGARÉ CON PDF

**Fecha:** October 23, 2025  
**Estado:** 🔍 ANALYSIS & PLANNING  
**Prioridad:** 🔴 ALTA

---

## 📊 ANÁLISIS DE LA SITUACIÓN ACTUAL

### ✅ Lo que YA está implementado:

1. **Sistema de Plantillas** (`document_templates`)
   - Tabla en BD con columnas: `type`, `version`, `content`, `placeholders`, `active`
   - Template de Pagaré v1 ya insertado con texto completo de `contratos/pagare.txt`
   - Sistema de versionado para poder actualizar plantillas

2. **Sistema de Documentos** (`enrollment_documents`)
   - Registra documentos generados por matrícula
   - Columnas: `pdf_url`, `storage_path`, `final_content`, `content_hash`, `status`
   - RLS configurado (guardians pueden ver sus documentos)

3. **Flujo de Generación** (MatriculaWizard)
   - `getActivePagareTemplate()` - Obtiene última plantilla activa
   - `buildPagarePayload()` - Construye datos (apoderado, estudiantes, montos)
   - `renderTemplate()` - Reemplaza `{{placeholders}}` con valores reales
   - `createPagareDocument()` - Guarda HTML renderizado en BD

4. **Sistema de Firmas** (`signatures`)
   - Registro de aceptación del documento
   - Métodos: checkbox, drawn, upload
   - Actualiza `enrollment_documents.status` a 'signed'

### ❌ Lo que FALTA implementar:

1. **Generación de PDF** - No existe función para convertir HTML → PDF
2. **Upload a Storage** - No se sube el PDF a Supabase Storage
3. **Bucket configurado** - No existe bucket para documentos
4. **Descarga de PDF** - No hay botón/link para descargar
5. **Preview PDF** - Solo muestra HTML, no PDF final
6. **Edición Pre-generación** - No se puede modificar texto antes de generar

---

## 🎯 OBJETIVO

Implementar sistema completo de generación de Pagaré en PDF que permita:

1. ✅ Generar PDF desde HTML renderizado
2. ✅ Almacenar PDF en Supabase Storage
3. ✅ Registrar versiones y modificaciones
4. ✅ Permitir editar texto antes de generar PDF
5. ✅ Descargar PDF generado
6. ✅ Imprimir para firma analógica en notaría

---

## 🏗️ ARQUITECTURA PROPUESTA

### Componentes del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                  GUARDIAN PORTAL                         │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │        MatriculaWizard Component                 │    │
│  │                                                   │    │
│  │  Step 1: Seleccionar Alumnos                     │    │
│  │  Step 2: Datos Económicos                        │    │
│  │  Step 3: Generar Pagaré                          │    │
│  │           ├─> [Editar Texto] (Opcional)         │    │
│  │           ├─> [Generar PDF] ──────┐             │    │
│  │           └─> [Preview PDF]       │             │    │
│  │  Step 4: Revisar y Firmar         │             │    │
│  │           ├─> [Descargar PDF]     │             │    │
│  │           └─> [Firmar Checkbox]   │             │    │
│  └──────────────────────────────────▼─────────────┘    │
│                                      │                   │
│                ┌────────────────────▼────────────────┐  │
│                │   matricula.ts SERVICE               │  │
│                │                                      │  │
│                │  ├─> getActivePagareTemplate()      │  │
│                │  ├─> buildPagarePayload()           │  │
│                │  ├─> renderTemplate()               │  │
│                │  ├─> generatePDF() ◄──NEW           │  │
│                │  ├─> uploadDocumentPDF() ◄──NEW     │  │
│                │  ├─> createPagareDocument()         │  │
│                │  └─> signEnrollmentDocument()       │  │
│                └───────┬──────────────┬───────────────┘  │
│                        │              │                   │
└────────────────────────┼──────────────┼───────────────────┘
                         │              │
                 ┌───────▼──────┐  ┌───▼────────────┐
                 │   SUPABASE   │  │ SUPABASE       │
                 │   DATABASE   │  │ STORAGE        │
                 │              │  │                │
                 │ ┌──────────┐ │  │ Bucket:        │
                 │ │document_ │ │  │ enrollment-    │
                 │ │templates │ │  │ documents/     │
                 │ └──────────┘ │  │  ├─ 2025/      │
                 │              │  │  │  ├─uuid.pdf  │
                 │ ┌──────────┐ │  │  │  └─uuid.pdf  │
                 │ │enrollment│ │  └────────────────┘
                 │ │_documents│ │
                 │ │ ├─pdf_url│ │
                 │ │ └─storage│ │
                 │ │   _path  │ │
                 │ └──────────┘ │
                 │              │
                 │ ┌──────────┐ │
                 │ │signatures│ │
                 │ └──────────┘ │
                 └──────────────┘
```

---

## 🛠️ OPCIONES TÉCNICAS PARA GENERACIÓN PDF

### Opción 1: **jsPDF + html2canvas** ⭐ RECOMENDADO
**Pros:**
- ✅ Más popular y estable (50K+ ⭐ en GitHub)
- ✅ Genera PDFs cliente-side (no necesita servidor)
- ✅ Buen control de layout y estilos
- ✅ Puede capturar HTML complejo con html2canvas
- ✅ Tamaño razonable (~500KB bundle)
- ✅ Buena documentación

**Contras:**
- ⚠️ html2canvas puede tener issues con fuentes custom
- ⚠️ Calidad depende del rendering HTML

**Instalación:**
```bash
npm install jspdf html2canvas
npm install --save-dev @types/html2canvas
```

**Ejemplo de uso:**
```typescript
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

async function htmlToPDF(htmlContent: string): Promise<Blob> {
  // Create temporary div
  const div = document.createElement('div');
  div.innerHTML = htmlContent;
  div.style.width = '210mm'; // A4 width
  div.style.padding = '20mm';
  document.body.appendChild(div);
  
  // Capture as canvas
  const canvas = await html2canvas(div, {
    scale: 2, // High quality
    useCORS: true
  });
  
  // Remove temporary div
  document.body.removeChild(div);
  
  // Create PDF
  const pdf = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4'
  });
  
  const imgWidth = 210;
  const imgHeight = (canvas.height * imgWidth) / canvas.width;
  
  pdf.addImage(
    canvas.toDataURL('image/png'),
    'PNG',
    0,
    0,
    imgWidth,
    imgHeight
  );
  
  return pdf.output('blob');
}
```

### Opción 2: **pdfmake**
**Pros:**
- ✅ No depende de HTML, usa estructura de documento
- ✅ PDFs más pequeños
- ✅ Mejor control tipográfico

**Contras:**
- ❌ Requiere convertir HTML a estructura pdfmake (complejo)
- ❌ Menor flexibilidad visual
- ❌ Más trabajo inicial para migrar plantilla

### Opción 3: **react-pdf**
**Pros:**
- ✅ Componentes React nativos
- ✅ TypeScript friendly

**Contras:**
- ❌ Requiere reescribir toda la plantilla como componentes
- ❌ Curva de aprendizaje
- ❌ Más código para mantener

### Opción 4: **Servidor con Puppeteer/wkhtmltopdf**
**Pros:**
- ✅ Calidad perfecta (rendering real Chrome)
- ✅ Soporte completo de CSS

**Contras:**
- ❌ Requiere backend/serverless function
- ❌ Costo adicional
- ❌ Más complejo de mantener
- ❌ Latencia adicional

---

## 📋 RECOMENDACIÓN FINAL

### ⭐ **Usar jsPDF + html2canvas**

**Razones:**

1. **Simplicidad:** Aprovecha el HTML ya renderizado
2. **Sin backend:** Todo cliente-side, menor complejidad
3. **Probado:** Librería madura y bien documentada
4. **Costo:** Zero (no requiere servicios adicionales)
5. **Velocidad:** Genera PDF instantáneamente en el navegador
6. **Mantenimiento:** Solo frontend, más fácil de debuggear

**Flujo propuesto:**
```
HTML Template + Placeholders 
    ↓
renderTemplate(content, payload)
    ↓
HTML Final (editable opcional)
    ↓
html2canvas() → Canvas
    ↓
jsPDF.addImage() → PDF Blob
    ↓
Upload to Supabase Storage
    ↓
Save URL in enrollment_documents
```

---

## 🔧 IMPLEMENTACIÓN DETALLADA

### FASE 1: Configurar Supabase Storage

**Archivo:** `supabase/migrations/20251023_setup_enrollment_documents_bucket.sql`

```sql
-- Create bucket for enrollment documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'enrollment-documents',
  'enrollment-documents',
  false, -- Private bucket, access via signed URLs
  10485760, -- 10MB limit
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for enrollment-documents bucket

-- Policy 1: Guardians can read their own documents
CREATE POLICY "Guardians can read own enrollment documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND (storage.foldername(name))[1] IN (
    SELECT e.id::text
    FROM enrollments e
    JOIN guardians g ON g.id = e.guardian_id
    WHERE g.owner_id = auth.uid()
  )
);

-- Policy 2: Guardians can upload to their own enrollment folder
CREATE POLICY "Guardians can upload to own enrollment"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'enrollment-documents'
  AND (storage.foldername(name))[1] IN (
    SELECT e.id::text
    FROM enrollments e
    JOIN guardians g ON g.id = e.guardian_id
    WHERE g.owner_id = auth.uid()
  )
);

-- Policy 3: Admins can access all documents
CREATE POLICY "Admins can access all enrollment documents"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'enrollment-documents'
  AND EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);
```

### FASE 2: Servicios de Generación PDF con Estilo Profesional

**Archivo:** `src/services/pdfGenerator.ts`

```typescript
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
async function addPDFHeader(pdf: jsPDF, pageWidth: number) {
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
  if (guardianRun) {
    pdf.text(`RUT: ${guardianRun}`, col1X, sigY + 10);
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
    });

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
```

### FASE 3: Upload a Supabase Storage

**Agregar a:** `src/services/matricula.ts`

```typescript
/**
 * Upload PDF blob to Supabase Storage
 * Path format: enrollment-documents/{enrollmentId}/{documentId}.pdf
 */
export async function uploadDocumentPDF(
  enrollmentId: string,
  documentId: string,
  pdfBlob: Blob
): Promise<{ url: string; path: string } | null> {
  const path = `${enrollmentId}/${documentId}.pdf`;
  
  const { error: uploadError } = await supabase.storage
    .from('enrollment-documents')
    .upload(path, pdfBlob, {
      contentType: 'application/pdf',
      cacheControl: '3600',
      upsert: true // Allow regeneration
    });

  if (uploadError) {
    console.error('uploadDocumentPDF error', uploadError);
    toast.error('No se pudo subir el PDF');
    return null;
  }

  // Get signed URL (valid for 1 year)
  const { data: urlData, error: urlError } = await supabase.storage
    .from('enrollment-documents')
    .createSignedUrl(path, 31536000); // 365 days

  if (urlError) {
    console.error('createSignedUrl error', urlError);
    toast.error('No se pudo obtener URL del PDF');
    return null;
  }

  return {
    url: urlData.signedUrl,
    path
  };
}

/**
 * Get signed URL for existing document
 */
export async function getDocumentPDFUrl(
  storagePath: string,
  expiresIn: number = 3600
): Promise<string | null> {
  const { data, error } = await supabase.storage
    .from('enrollment-documents')
    .createSignedUrl(storagePath, expiresIn);

  if (error) {
    console.error('getDocumentPDFUrl error', error);
    return null;
  }

  return data.signedUrl;
}
```

### FASE 4: Actualizar createPagareDocument

**Modificar en:** `src/services/matricula.ts`

```typescript
import { generatePDFFromHTML } from './pdfGenerator';

export async function createPagareDocument(params: {
  enrollmentId: string;
  template: DocumentTemplate;
  payload: PagarePayload;
  finalContent: string;
  contentHash?: string;
  generatePDF?: boolean; // NEW: optional flag
}): Promise<EnrollmentDocumentRecord | null> {
  const { 
    enrollmentId, 
    template, 
    payload, 
    finalContent, 
    contentHash,
    generatePDF: shouldGeneratePDF = true // Default true
  } = params;

  // Step 1: Insert document record (without PDF initially)
  const insertObj: any = {
    enrollment_id: enrollmentId,
    type: 'PAGARE',
    template_version: template.version,
    status: 'generated',
    generated_payload: payload,
    final_content: finalContent,
    content_hash: contentHash || null
  };

  const { data: docRecord, error: insertError } = await supabase
    .from('enrollment_documents')
    .insert(insertObj)
    .select()
    .single();

  if (insertError) {
    console.error('createPagareDocument insert error', insertError);
    toast.error('No se pudo crear el documento');
    return null;
  }

  // Step 2: Generate and upload PDF if requested
  if (shouldGeneratePDF) {
    try {
      toast.loading('Generando PDF...', { id: 'pdf-gen' });

      // Generate PDF blob
      const pdfBlob = await generatePDFFromHTML({
        htmlContent: finalContent,
        filename: `pagare-${docRecord.id}.pdf`
      });

      // Upload to Storage
      const uploadResult = await uploadDocumentPDF(
        enrollmentId,
        docRecord.id,
        pdfBlob
      );

      if (!uploadResult) {
        toast.error('PDF generado pero no se pudo subir', { id: 'pdf-gen' });
        return docRecord; // Return without PDF
      }

      // Update document record with PDF info
      const { error: updateError } = await supabase
        .from('enrollment_documents')
        .update({
          pdf_url: uploadResult.url,
          storage_path: uploadResult.path,
          pdf_hash: await sha256(await pdfBlob.text()) // Hash for integrity
        })
        .eq('id', docRecord.id);

      if (updateError) {
        console.error('createPagareDocument update error', updateError);
        toast.error('PDF subido pero no se pudo actualizar registro', { id: 'pdf-gen' });
        return docRecord;
      }

      toast.success('Pagaré y PDF generados', { id: 'pdf-gen' });
      
      // Return updated record
      return {
        ...docRecord,
        pdf_url: uploadResult.url,
        storage_path: uploadResult.path
      };

    } catch (pdfError) {
      console.error('PDF generation error', pdfError);
      toast.error('Error al generar PDF', { id: 'pdf-gen' });
      return docRecord; // Return document without PDF
    }
  }

  toast.success('Pagaré generado (sin PDF)');
  return docRecord;
}
```

### FASE 5: Actualizar MatriculaWizard UI

**Modificar en:** `src/components/matricula/MatriculaWizard.jsx`

```jsx
import { downloadPDFBlob, previewPDFBlob } from '../../services/pdfGenerator';

// Add state for PDF
const [pdfBlob, setPdfBlob] = useState<Blob | null>(null);

// In generateDoc function, after createPagareDocument:
const doc = await createPagareDocument({
  enrollmentId: enrollment.id,
  template: tmpl,
  payload,
  finalContent: html,
  contentHash,
  generatePDF: true // Enable PDF generation
});

setDocumentRecord(doc);
setLoading(false);

if (doc) {
  setStep(3); // jump to final step
}

// Add download handler
const handleDownloadPDF = () => {
  if (!documentRecord?.pdf_url) {
    toast.error('No hay PDF disponible');
    return;
  }
  
  // Download via signed URL
  const link = document.createElement('a');
  link.href = documentRecord.pdf_url;
  link.download = `pagare-${documentRecord.id}.pdf`;
  link.click();
};

// In Step 4 UI, add buttons:
{step === 3 && documentRecord && (
  <Card>
    <CardHeader>Paso 4: Revisar y Firmar</CardHeader>
    <CardContent className="space-y-3">
      {/* HTML Preview */}
      <div className="border rounded p-3 max-h-[500px] overflow-auto prose prose-sm dark:prose-invert bg-white dark:bg-dark/40 shadow-inner">
        <div dangerouslySetInnerHTML={{ __html: previewHtml.replace(/\n/g, '<br/>') }} />
      </div>

      {/* PDF Actions */}
      <div className="flex gap-2 flex-wrap">
        {documentRecord.pdf_url && (
          <>
            <Button 
              variant="outline" 
              onClick={handleDownloadPDF}
            >
              📥 Descargar PDF
            </Button>
            <Button 
              variant="outline" 
              onClick={() => window.open(documentRecord.pdf_url, '_blank')}
            >
              👁️ Ver PDF
            </Button>
          </>
        )}
        
        {documentRecord.status !== 'signed' && (
          <Button onClick={handleSign} disabled={loading}>
            ✍️ Firmar
          </Button>
        )}
        
        <Button variant="outline" onClick={() => setStep(2)}>
          🔄 Regenerar
        </Button>
      </div>

      {/* Instructions */}
      <div className="text-sm text-gray-600 dark:text-gray-400 border-t pt-3">
        <p><strong>Instrucciones para firma notarial:</strong></p>
        <ol className="list-decimal ml-5 space-y-1">
          <li>Descargue el PDF haciendo clic en "Descargar PDF"</li>
          <li>Imprima el documento</li>
          <li>Firme en presencia de notario</li>
          <li>Entregue el documento firmado al colegio</li>
        </ol>
      </div>
    </CardContent>
  </Card>
)}
```

### FASE 6: Editor de Plantilla (Opcional)

**Nuevo componente:** `src/components/admin/TemplateEditor.tsx`

```typescript
import React, { useState, useEffect } from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function TemplateEditor() {
  const [templates, setTemplates] = useState([]);
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [editContent, setEditContent] = useState('');
  const [preview, setPreview] = useState('');

  const loadTemplates = async () => {
    const { data } = await supabase
      .from('document_templates')
      .select('*')
      .order('version', { ascending: false });
    setTemplates(data || []);
  };

  const handleSaveNewVersion = async () => {
    if (!selectedTemplate) return;

    const newVersion = selectedTemplate.version + 1;
    
    const { error } = await supabase
      .from('document_templates')
      .insert({
        type: selectedTemplate.type,
        version: newVersion,
        title: `${selectedTemplate.title} (v${newVersion})`,
        content: editContent,
        placeholders: selectedTemplate.placeholders,
        active: true
      });

    if (error) {
      toast.error('No se pudo guardar nueva versión');
      return;
    }

    // Deactivate old version
    await supabase
      .from('document_templates')
      .update({ active: false })
      .eq('id', selectedTemplate.id);

    toast.success('Nueva versión guardada');
    loadTemplates();
  };

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Editor de Plantillas</h2>
      
      {/* Template selector */}
      <select onChange={(e) => {
        const tmpl = templates.find(t => t.id === e.target.value);
        setSelectedTemplate(tmpl);
        setEditContent(tmpl?.content || '');
      }}>
        <option>Seleccionar plantilla...</option>
        {templates.map(t => (
          <key={t.id} value={t.id}>
            {t.title} (v{t.version}) {t.active && '✓'}
          </option>
        ))}
      </select>

      {selectedTemplate && (
        <div className="grid grid-cols-2 gap-4">
          {/* Editor */}
          <Card>
            <CardHeader>Editar Contenido</CardHeader>
            <CardContent>
              <textarea
                className="w-full h-96 p-2 font-mono text-sm"
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
              />
              <Button onClick={handleSaveNewVersion}>
                Guardar como Nueva Versión
              </Button>
            </CardContent>
          </Card>

          {/* Preview */}
          <Card>
            <CardHeader>Vista Previa</CardHeader>
            <CardContent>
              <div 
                className="prose prose-sm max-w-none"
                dangerouslySetInnerHTML={{ __html: editContent }}
              />
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
```

---

## 🎨 REQUISITOS CONFIRMADOS POR EL CLIENTE

### ✅ **Estilo del PDF: Formato Profesional**

**Requerido:**
- ✅ Logo del colegio en el encabezado
- ✅ Bordes y formato profesional
- ✅ Sección para firmas con líneas

**Implementación:**
El PDF tendrá estructura profesional con:
- Encabezado con logo (público/logo-winterhill.png)
- Bordes decorativos y secciones delimitadas
- Pie de página con espacios para firmas:
  - Firma Apoderado (con línea y RUT)
  - Firma Corporación Winterhill (con línea y RUT)

### ✅ **Edición Pre-generación: Plantillas Versionadas (Simple)**

**Decisión:** Usar sistema de plantillas versionadas (ya implementado)
- Administrador puede crear nuevas versiones de plantilla
- No se implementará editor inline antes de generar (más simple)
- Si necesita cambios, se regenera con nueva versión

### ✅ **Notificaciones: Email Automático**

**Requerido:**
- ✅ Enviar PDF por email automáticamente al apoderado

**Implementación:**
Usar Supabase Edge Functions para envío de email:
- Trigger al generar PDF (status = 'generated')
- Email con PDF adjunto
- Template HTML para el email
- Servicio: SendGrid o Resend (a definir)

### ✅ **Firma: Analógica (Notaría)**

**Decisión:** Por ahora solo firma impresa en notaría
- PDF para descargar e imprimir
- Instrucciones claras para firma notarial
- No se implementará firma digital (DocuSign) en esta fase

---

## 🎨 MEJORAS IMPLEMENTADAS EN EL PDF

### 1. **Estructura Profesional**
```
┌─────────────────────────────────────────┐
│  [LOGO WINTERHILL]                      │
│  CORPORACIÓN EDUCACIONAL WINTERHILL     │
│  RUT: 65.152.884-4                      │
├─────────────────────────────────────────┤
│                                          │
│  CONTRATO DE PRESTACIÓN DE SERVICIOS    │
│         EDUCACIONALES                    │
│                                          │
│  [Contenido del pagaré]                 │
│                                          │
├─────────────────────────────────────────┤
│  FIRMAS:                                │
│                                          │
│  _____________________                  │
│  APODERADO/A                            │
│  RUT: {{guardian_run}}                  │
│                                          │
│  _____________________                  │
│  CORPORACIÓN WINTERHILL                 │
│  RUT: 65.152.884-4                      │
│  Representante Legal                    │
└─────────────────────────────────────────┘
```

### 2. **Watermark en PDFs No Firmados**
Agregar marca de agua "BORRADOR" o "NO FIRMADO" en PDFs que no han sido firmados

### 3. **Metadata en PDFs**
Información del documento para gestión documental

### 4. **Compresión Optimizada**
Para PDFs más livianos (mejor para email)

---

## 📊 ESTIMACIÓN DE TIEMPO

| Fase | Tarea | Tiempo Estimado |
|------|-------|----------------|
| 1 | Configurar Storage bucket + RLS | 30 min |
| 2 | Implementar pdfGenerator.ts | 1 hora |
| 3 | Implementar upload a Storage | 30 min |
| 4 | Actualizar createPagareDocument | 45 min |
| 5 | Actualizar MatriculaWizard UI | 1 hora |
| 6 | Editor de plantilla (opcional) | 2 horas |
| 7 | Testing y fixes | 1 hora |
| 8 | Documentación | 30 min |

**Total Mínimo (sin editor):** ~4.5 horas  
**Total Completo (con editor):** ~6.5 horas

---

## 🧪 PLAN DE TESTING

### Test Cases:

1. **Generación Básica**
   - [ ] Generar Pagaré con 1 estudiante
   - [ ] Generar Pagaré con múltiples estudiantes
   - [ ] Verificar placeholders reemplazados correctamente

2. **PDF Generation**
   - [ ] PDF se genera sin errores
   - [ ] PDF contiene todo el contenido HTML
   - [ ] PDF tiene formato A4 correcto
   - [ ] PDF mantiene estilos (negrita, tablas, etc.)

3. **Storage**
   - [ ] PDF se sube a Supabase Storage
   - [ ] URL firmada funciona
   - [ ] RLS permite acceso al guardian correcto
   - [ ] RLS bloquea acceso a otros guardians

4. **UI/UX**
   - [ ] Botón de descarga funciona
   - [ ] Preview PDF funciona
   - [ ] Loading states apropiados
   - [ ] Error handling correcto

5. **Versionado**
   - [ ] Nueva versión de plantilla crea nuevo PDF
   - [ ] Historial de versiones se mantiene
   - [ ] Admin puede ver todas las versiones

---

## 🚀 DEPLOYMENT CHECKLIST

- [ ] Instalar dependencias (`npm install jspdf html2canvas`)
- [ ] Ejecutar migración de Storage bucket
- [ ] Crear pdfGenerator.ts service
- [ ] Actualizar matricula.ts con upload functions
- [ ] Modificar createPagareDocument para generar PDF
- [ ] Actualizar MatriculaWizard UI
- [ ] Testing en ambiente de desarrollo
- [ ] Testing con usuario real (guardian)
- [ ] Verificar performance (tiempo de generación)
- [ ] Documentar proceso para admin
- [ ] Deploy a producción
- [ ] Monitorear errores primeros días

---

## 📚 DOCUMENTACIÓN PARA USUARIOS

### Para Apoderados:

1. **Generar Pagaré:**
   - Complete los datos de matrícula
   - El sistema generará automáticamente el PDF
   - Descargue el PDF usando el botón "Descargar PDF"

2. **Firma Notarial:**
   - Imprima el PDF descargado
   - Lleve el documento a una notaría
   - Firme en presencia del notario
   - Entregue el documento firmado al colegio

### Para Administradores:

1. **Modificar Plantilla:**
   - Acceda al Editor de Plantillas (Admin panel)
   - Seleccione la plantilla "Pagaré"
   - Edite el contenido usando placeholders `{{variable}}`
   - Guarde como nueva versión
   - La plantilla activa será usada automáticamente

2. **Placeholders Disponibles:**
   - `{{guardian_full_name}}` - Nombre completo del apoderado
   - `{{guardian_run}}` - RUT del apoderado
   - `{{guardian_address}}` - Dirección
   - `{{year}}` - Año académico
   - `{{students_table}}` - Tabla con estudiantes
   - `{{colegiatura_anual}}` - Monto anual
   - `{{cantidad_cuotas}}` - Número de cuotas
   - `{{monto_cuota}}` - Monto por cuota
   - `{{dia_vencimiento}}` - Día de vencimiento

---

## ✅ CONCLUSIÓN Y PRÓXIMOS PASOS

### Decisión Final: ✅ **Implementar jsPDF + html2canvas**

**¿Por qué?**
- Menor complejidad (cliente-side only)
- Aprovecha HTML ya renderizado
- Zero costo adicional
- Fácil mantenimiento

### Próximos Pasos Inmediatos:

1. ✅ **Aprobar este plan** - Confirmar enfoque técnico
2. 🔨 **Implementar Fase 1-5** - Core functionality
3. 🧪 **Testing** - Probar con datos reales
4. 📄 **Documentar** - Guías para usuarios
5. 🚀 **Deploy** - Subir a producción
6. 📊 **Monitorear** - Ver uso y errores

### Mejoras Futuras (Post-MVP):

- Editor de plantilla con WYSIWYG
- Firma digital con certificado
- Envío automático por email
- Integración con DocuSign
- Plantillas para otros documentos (DECLARACION, etc.)

---

**¿Procedemos con la implementación?** 🚀
