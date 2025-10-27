# Logo Instructions for PDF Generation

## Required File
- **Filename**: `logo-winterhill.png`
- **Location**: `/public/` folder (root of public directory)
- **Format**: PNG with transparency
- **Recommended dimensions**: 300x200 pixels (or similar aspect ratio)
- **Aspect ratio**: Approximately 3:2 (width:height)

## How to Add Your Logo

1. **Prepare your logo**:
   - Export your school logo as PNG format
   - Ensure it has a transparent background
   - Recommended size: 300x200 px or higher for quality

2. **Add to project**:
   - Place the file in the `public` folder
   - Name it exactly: `logo-winterhill.png`

3. **Verify**:
   - The file should be accessible at `/logo-winterhill.png` when the app runs
   - Test by opening `http://localhost:5173/logo-winterhill.png` in your browser

## Current Status
⚠️ **PLACEHOLDER NEEDED**: Add your actual logo file before generating PDFs

## Fallback Behavior
If the logo file is not found:
- The PDF will still generate successfully
- A console warning will appear: "Logo not loaded, skipping header image"
- The header will show only text (school name and RUT)
- No error will be thrown

## Example Logo Specifications
- School name in the logo (optional, as it's also in text)
- School emblem or shield
- High contrast colors for printing
- Professional appearance suitable for legal documents

## Technical Details
- The logo is loaded asynchronously with a 3-second timeout
- Used in `src/services/pdfGenerator.ts` in the `addPDFHeader` function
- Positioned centered at the top of each PDF page
- Rendered at 30mm width × 20mm height in the PDF
