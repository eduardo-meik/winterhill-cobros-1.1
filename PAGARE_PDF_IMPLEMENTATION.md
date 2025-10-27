# 📄 Pagaré PDF Generation - Implementation Complete

## ✅ Implementation Status

### Core Features (COMPLETED)
- ✅ PDF generation from HTML templates using jsPDF + html2canvas
- ✅ Professional PDF styling with logo, borders, and signature sections
- ✅ Supabase Storage integration for PDF file storage
- ✅ Download and preview PDF functionality
- ✅ Automatic upload to cloud storage with signed URLs
- ✅ Version control and hash tracking for documents
- ✅ RLS policies for secure document access

### Optional Features (TODO)
- ⏳ Email notification system (Supabase Edge Function)
- ⏳ Template editor for administrators

---

## 🚀 Deployment Checklist

### 1. Supabase Storage Setup
Before deploying to production, you MUST create the Storage bucket:

#### Manual Steps (Supabase Dashboard):
1. Go to **Supabase Dashboard** → **Storage**
2. Click **"Create new bucket"**
3. Configure:
   - **Name**: `enrollment-documents`
   - **Public**: ❌ OFF (private bucket)
   - **File size limit**: `10 MB`
   - **Allowed MIME types**: `application/pdf`
4. Click **"Create bucket"**

#### Apply RLS Policies:
Run the migration file in your Supabase SQL Editor:
```bash
# File: supabase/migrations/20251027_setup_enrollment_documents_bucket.sql
```

The migration includes:
- RLS policies for guardians to view their own documents
- Admin access to all documents
- Upload permissions for authenticated users
- Delete permissions for admins only

### 2. Logo File
Add your school logo to enable professional PDF headers:

1. **Prepare logo**:
   - Format: PNG with transparency
   - Recommended size: 300×200 pixels
   - Aspect ratio: ~3:2

2. **Add to project**:
   ```
   public/logo-winterhill.png
   ```

3. **Verify**: Open `http://localhost:5173/logo-winterhill.png` in browser

> **Note**: If logo is missing, PDFs will still generate with text-only headers.

### 3. Environment Variables
Ensure your `.env` file has the correct Supabase credentials:

```env
VITE_SUPABASE_URL=your-project-url
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 4. Dependencies
Already installed (verify in `package.json`):
```json
{
  "dependencies": {
    "jspdf": "^2.5.x",
    "html2canvas": "^1.4.x"
  },
  "devDependencies": {
    "@types/html2canvas": "^1.0.x"
  }
}
```

---

## 📖 User Guide

### For Guardians (Apoderados)

#### How to Generate a Pagaré:

1. **Navigate to Matrícula**:
   - Log in to the portal
   - Go to the "Matrícula" section

2. **Step 1: Select Students**:
   - Choose the enrollment year
   - Add students to the enrollment

3. **Step 2: Economic Data**:
   - Enter "Colegiatura Anual" (annual tuition)
   - Enter "Cantidad Cuotas" (number of installments)
   - Enter "Monto por Cuota" (amount per installment)
   - Enter "Día Vencimiento" (due day, 1-28)
   - Click "Guardar Datos"

4. **Step 3: Generate Document**:
   - Click "Generar Documento"
   - Wait for PDF generation (automatic)

5. **Step 4: Review & Download**:
   - Review the HTML preview
   - Click **"📥 Descargar PDF"** to download
   - Click **"👁️ Vista Previa PDF"** to view in browser
   - Print the PDF
   - Take it to the notary for physical signature

6. **Sign Digitally** (optional):
   - Click "Firmar" to record digital acceptance
   - This is separate from the physical notary signature

### PDF Features:
- ✅ Professional header with school logo and RUT
- ✅ Bordered sections for clarity
- ✅ Signature lines for both parties (Guardian + Corporation)
- ✅ Watermark "NO FIRMADO" until signed
- ✅ Date and place (Viña del Mar)
- ✅ Complete contract text with all legal clauses

---

## 🔧 Technical Documentation

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   MatriculaWizard Component                  │
│  (User fills data → Generates document → Downloads PDF)     │
└─────────────┬───────────────────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────────────────┐
│               src/services/matricula.ts                      │
│  • buildPagarePayload() - Build data object                 │
│  • renderTemplate() - Replace {{placeholders}}              │
│  • createPagareDocument() - Orchestrates PDF generation     │
│  • uploadDocumentPDF() - Upload to Supabase Storage         │
│  • getDocumentPDFUrl() - Get signed URL                     │
└─────────────┬───────────────────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────────────────┐
│              src/services/pdfGenerator.ts                    │
│  • generatePDFFromHTML() - Convert HTML to PDF blob         │
│  • addPDFHeader() - Add logo, school name, borders          │
│  • addSignatureSection() - Add signature lines              │
│  • addWatermark() - Add "NO FIRMADO" watermark              │
│  • downloadPDFBlob() - Download file                        │
│  • previewPDFBlob() - Open in new tab                       │
└─────────────┬───────────────────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────────────────┐
│                 Supabase Storage Bucket                      │
│  • Name: enrollment-documents                                │
│  • Path: {enrollmentId}/{filename}.pdf                      │
│  • Access: Private with RLS policies                        │
└─────────────┬───────────────────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────────────────┐
│              Database: enrollment_documents                  │
│  • pdf_url: Signed URL (1-year validity)                    │
│  • storage_path: Bucket path                                │
│  • pdf_hash: SHA-256 hash for integrity                     │
│  • content_hash: SHA-256 hash of HTML content               │
└─────────────────────────────────────────────────────────────┘
```

### Key Functions

#### `createPagareDocument(params)`
Main orchestration function that:
1. Generates PDF blob from HTML content
2. Computes PDF hash (SHA-256)
3. Uploads PDF to Supabase Storage
4. Gets signed URL (valid for 1 year)
5. Saves record to database with URLs and hashes
6. Handles errors with automatic cleanup

**Parameters**:
```typescript
{
  enrollmentId: string;
  template: DocumentTemplate;
  payload: PagarePayload;
  finalContent: string;
  contentHash?: string;
  generatePDF?: boolean; // default: true
  guardianRun?: string; // for signature section
}
```

#### `generatePDFFromHTML(options)`
Converts HTML to professionally styled PDF:
- Uses html2canvas to capture HTML rendering
- Uses jsPDF to create PDF document
- Adds header with logo and school info
- Adds signature section with lines for both parties
- Adds watermark if specified
- Handles multi-page documents automatically

**Options**:
```typescript
{
  htmlContent: string;
  orientation?: 'portrait' | 'landscape'; // default: portrait
  format?: 'a4' | 'letter'; // default: a4
  margin?: number; // default: 20mm
  includeHeader?: boolean; // default: true
  includeSignatureSection?: boolean; // default: true
  watermark?: string; // e.g., 'NO FIRMADO'
  guardianRun?: string; // for signature label
}
```

### Database Schema

#### Table: `enrollment_documents`
```sql
CREATE TABLE enrollment_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id UUID NOT NULL REFERENCES enrollments(id),
  type TEXT NOT NULL, -- 'PAGARE', 'DECLARACION', etc.
  template_version INTEGER NOT NULL,
  status TEXT NOT NULL, -- 'generated', 'signed'
  generated_payload JSONB,
  final_content TEXT,
  content_hash TEXT, -- SHA-256 of HTML
  pdf_url TEXT, -- Signed URL (1-year validity)
  storage_path TEXT, -- Path in Storage bucket
  pdf_hash TEXT, -- SHA-256 of PDF file
  signed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Storage Structure
```
enrollment-documents/
├── {enrollment-id-1}/
│   ├── {enrollment-id-1}_PAGARE_2025-10-27T10-30-45.pdf
│   └── {enrollment-id-1}_PAGARE_2025-11-15T14-22-10.pdf
├── {enrollment-id-2}/
│   └── {enrollment-id-2}_PAGARE_2025-10-28T09-15-33.pdf
```

---

## 🧪 Testing Guide

### Manual Testing Steps

1. **Test PDF Generation**:
   ```
   ✓ Navigate to Matrícula
   ✓ Complete steps 1-2 with valid data
   ✓ Click "Generar Documento"
   ✓ Verify "PDF generado exitosamente" toast
   ✓ Verify "PDF Generado" badge appears
   ```

2. **Test PDF Download**:
   ```
   ✓ Click "📥 Descargar PDF" button
   ✓ Verify file downloads with correct name
   ✓ Open PDF and verify:
     - Logo appears in header (if logo file exists)
     - School name and RUT in header
     - Borders and professional formatting
     - Signature lines for both parties
     - Watermark "NO FIRMADO"
     - Complete contract text
   ```

3. **Test PDF Preview**:
   ```
   ✓ Click "👁️ Vista Previa PDF" button
   ✓ Verify PDF opens in new browser tab
   ✓ Verify all content is visible and properly formatted
   ```

4. **Test Storage Upload**:
   ```
   ✓ Go to Supabase Dashboard → Storage → enrollment-documents
   ✓ Verify folder created for enrollment ID
   ✓ Verify PDF file uploaded with timestamp in name
   ✓ Verify file size is reasonable (usually 100-500 KB)
   ```

5. **Test RLS Policies**:
   ```
   ✓ Log in as guardian
   ✓ Verify can download own documents
   ✓ Verify cannot access other guardians' documents
   ✓ Log in as admin
   ✓ Verify can access all documents
   ```

### Error Scenarios to Test

1. **Missing Logo**:
   - Remove logo file
   - Generate PDF
   - Expected: Console warning, PDF generates with text-only header

2. **Storage Bucket Not Created**:
   - Generate document without bucket
   - Expected: Error toast "No se pudo subir el PDF"

3. **Network Error**:
   - Disconnect internet during upload
   - Expected: Error toast, no database record created

4. **Invalid Data**:
   - Generate with missing economic data
   - Expected: Template renders with {{placeholder}} markers

---

## 🔐 Security Considerations

### Row Level Security (RLS)
All documents are protected by RLS policies:

- **Guardians**: Can only view/download their own enrollment documents
- **Admins**: Can view/download/delete all documents
- **Anonymous**: No access

### File Storage Security
- Bucket is **private** (not publicly accessible)
- All file access requires authentication
- URLs are **signed** with 1-year expiration
- URLs can be revoked by deleting the file

### Hash Verification
Two hashes are stored for integrity:
1. **content_hash**: SHA-256 of HTML content
2. **pdf_hash**: SHA-256 of PDF file

These allow verification that documents haven't been tampered with.

---

## 📦 Files Created/Modified

### New Files:
- ✅ `src/services/pdfGenerator.ts` - PDF generation service
- ✅ `supabase/migrations/20251027_setup_enrollment_documents_bucket.sql` - Storage setup
- ✅ `public/LOGO_INSTRUCTIONS.md` - Logo documentation
- ✅ `PAGARE_PDF_IMPLEMENTATION.md` - This documentation

### Modified Files:
- ✅ `src/services/matricula.ts` - Added Storage functions and updated createPagareDocument
- ✅ `src/components/matricula/MatriculaWizard.jsx` - Added PDF download/preview buttons
- ✅ `package.json` - Added jspdf and html2canvas dependencies

---

## 🔄 Future Enhancements

### Phase 1 (Completed)
- ✅ Basic PDF generation
- ✅ Storage upload
- ✅ Download/preview functionality
- ✅ Professional styling

### Phase 2 (Optional - Not Yet Implemented)
- ⏳ **Email Notifications**:
  - Supabase Edge Function
  - Send PDF as attachment after generation
  - Use SendGrid or Resend service
  
- ⏳ **Template Editor**:
  - Admin interface to edit document_templates
  - Real-time preview of changes
  - Version control for templates

- ⏳ **Digital Signature**:
  - Integration with Chilean digital signature providers
  - E-signature workflow
  - Compliance with Chilean e-signature laws

- ⏳ **Batch Generation**:
  - Generate PDFs for multiple guardians
  - Bulk download as ZIP
  - Progress tracking

---

## 🐛 Troubleshooting

### Issue: "No se pudo subir el PDF"
**Causes**:
1. Storage bucket not created
2. RLS policies not applied
3. Network error

**Solutions**:
1. Create bucket in Supabase Dashboard (see Deployment Checklist)
2. Run migration SQL to apply RLS policies
3. Check browser console for detailed error

### Issue: Logo not appearing in PDF
**Causes**:
1. Logo file missing
2. Logo file has wrong name
3. Logo path incorrect

**Solutions**:
1. Add `logo-winterhill.png` to `public/` folder
2. Verify exact filename (case-sensitive)
3. Test access: `http://localhost:5173/logo-winterhill.png`

### Issue: PDF quality is poor
**Causes**:
1. Low DPI setting
2. Complex HTML rendering

**Solutions**:
1. Verify `scale: 2` in pdfGenerator.ts (300 DPI equivalent)
2. Simplify HTML if excessive elements
3. Use vector graphics (SVG) in logo if possible

### Issue: "Failed to load resource: 400"
**Causes**:
1. Database constraint violation
2. Missing required fields
3. RLS policy blocking insert

**Solutions**:
1. Check browser console for detailed error
2. Verify all required fields in payload
3. Check user authentication status

---

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review browser console errors
3. Check Supabase Dashboard logs
4. Verify deployment checklist completed

---

## 📝 License & Copyright

© 2025 Corporación Educacional Winterhill
All rights reserved.

---

**Last Updated**: October 27, 2025
**Version**: 1.0.0
**Status**: ✅ Core Implementation Complete
