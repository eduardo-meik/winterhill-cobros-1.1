# Mejoras al Formato de PDFs - Pagaré
**Fecha**: 1 de Noviembre, 2025  
**Archivo modificado**: `src/services/pdfGenerator.ts` y `src/components/matricula/MatriculaWizard.jsx`

## 🎯 Cambios Implementados

### ✅ 1. Márgenes Inferiores Aumentados
**Antes**: 
- Margen inferior: 70mm (con firmas) o 20mm (sin firmas)

**Después**:
- Margen inferior: **80mm** (con firmas) o **30mm** (sin firmas)
- Mayor espacio para contenido y firmas
- Mejor distribución visual del documento

---

### ✅ 2. Saltos de Línea Preservados
**Antes**:
```javascript
container.style.textAlign = 'justify';
```

**Después**:
```javascript
container.style.textAlign = 'justify';
container.style.whiteSpace = 'pre-wrap';  // NUEVO: Mantiene saltos de línea
container.style.wordWrap = 'break-word';   // NUEVO: Ajusta palabras largas
container.style.lineHeight = '1.6';        // Mejor espaciado entre líneas
```

**Resultado**: Ahora se respetan todos los saltos de línea (`\n`) del HTML original.

---

### ✅ 3. Marca de Agua Removida
**Antes**:
```javascript
watermark: documentRecord?.status === 'signed' ? undefined : 'NO FIRMADO',
```

**Después**:
```javascript
// watermark removida - ya no se usa por defecto
folioNumber: folioNumber, // Añadido número de folio
```

**Resultado**: Los PDFs ya **NO** llevan marca de agua "NO FIRMADO" por defecto.

---

### ✅ 4. Logo Ajustado Proporcionalmente y Alineado a la Izquierda
**Antes**:
```javascript
// Logo centrado, tamaño fijo
const logoWidth = 30;
const logoHeight = 20;
pdf.addImage(logoImg, 'PNG', (pageWidth - logoWidth) / 2, 10, logoWidth, logoHeight);
```

**Después**:
```javascript
// Logo a la izquierda, proporcional al aspect ratio original
const maxLogoWidth = 35;
const maxLogoHeight = 25;
const logoAspectRatio = logoImg.width / logoImg.height;

let logoWidth = maxLogoWidth;
let logoHeight = logoWidth / logoAspectRatio;

// Ajustar si la altura excede el máximo
if (logoHeight > maxLogoHeight) {
  logoHeight = maxLogoHeight;
  logoWidth = logoHeight * logoAspectRatio;
}

// Agregar logo alineado a la izquierda
pdf.addImage(logoImg, 'PNG', 15, 10, logoWidth, logoHeight);
```

**Resultado**: 
- Logo mantiene proporciones originales
- Ubicado en margen izquierdo (15mm)
- Texto corporativo alineado a la derecha del logo

---

### ✅ 5. Evitar Sobreposición de Tablas
**Nuevo código agregado**:
```javascript
// Estilos para tablas (evitar sobreposición)
const tables = container.querySelectorAll('table');
tables.forEach(table => {
  (table as HTMLElement).style.width = '100%';
  (table as HTMLElement).style.borderCollapse = 'collapse';
  (table as HTMLElement).style.marginTop = '15px';      // Espacio antes
  (table as HTMLElement).style.marginBottom = '15px';   // Espacio después
  (table as HTMLElement).style.pageBreakInside = 'avoid'; // No cortar tabla
  (table as HTMLElement).style.border = '1px solid #333';
  
  // Estilo para celdas
  const cells = table.querySelectorAll('td, th');
  cells.forEach(cell => {
    (cell as HTMLElement).style.padding = '8px';
    (cell as HTMLElement).style.border = '1px solid #666';
    (cell as HTMLElement).style.fontSize = '10pt';
  });
  
  // Encabezados con fondo azul
  const headers = table.querySelectorAll('th');
  headers.forEach(header => {
    (header as HTMLElement).style.backgroundColor = '#003366';
    (header as HTMLElement).style.color = 'white';
    (header as HTMLElement).style.fontWeight = 'bold';
  });
});
```

**Resultado**:
- Tablas con márgenes superior e inferior de 15px
- Evita corte de tablas entre páginas (`page-break-inside: avoid`)
- Bordes bien definidos
- Encabezados con fondo azul oscuro (#003366)

---

### ✅ 6. Número de Folio en Esquina Superior Derecha
**Nuevo parámetro agregado**:
```typescript
export interface PDFGenerationOptions {
  // ... otros parámetros
  folioNumber?: string; // NUEVO: Número de folio del documento
}
```

**Implementación en header**:
```javascript
async function addPDFHeader(pdf: jsPDF, pageWidth: number, folioNumber?: string) {
  // ... logo y texto corporativo
  
  // Add folio number (top right corner)
  if (folioNumber) {
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'bold');
    pdf.text(`FOLIO N° ${folioNumber}`, pageWidth - 15, 15, { align: 'right' });
  }
  
  // ...
}
```

**Generación automática del folio**:
```javascript
// En MatriculaWizard.jsx
const folioNumber = documentRecord?.id 
  ? documentRecord.id.substring(0, 8).toUpperCase() 
  : Date.now().toString().slice(-8);
```

**Resultado**:
- Folio visible en esquina superior derecha
- Formato: `FOLIO N° XXXXXXXX`
- Se genera a partir del ID del documento o timestamp

---

## 📊 Mejoras Visuales Adicionales

### Calidad de Renderizado
```javascript
scale: 2.5,  // AUMENTADO de 2 a 2.5 para mayor nitidez
```

### Línea Separadora del Header
```javascript
pdf.setDrawColor(0, 51, 102); // Azul oscuro corporativo
pdf.setLineWidth(0.8);         // Más gruesa para mayor impacto
```

### Información Corporativa en Header
**Ahora incluye**:
- Logo a la izquierda
- Nombre corporativo
- RUT: 65.152.884-4
- Ubicación: Viña del Mar, Región de Valparaíso
- Folio en esquina superior derecha

---

## 🔧 Archivos Modificados

### 1. `src/services/pdfGenerator.ts`
**Cambios**:
- Interfaz `PDFGenerationOptions`: Agregado `folioNumber?: string`
- Función `addPDFHeader()`: 
  - Logo proporcional y a la izquierda
  - Agregado folio en esquina superior derecha
  - Línea azul oscuro
- Función `generatePDFFromHTML()`:
  - Márgenes inferiores aumentados (80mm/30mm)
  - `whiteSpace: 'pre-wrap'` para mantener saltos de línea
  - Estilos automáticos para tablas
  - Marca de agua removida por defecto
  - Mayor calidad de renderizado (scale: 2.5)

**Líneas modificadas**: ~80 líneas

### 2. `src/components/matricula/MatriculaWizard.jsx`
**Cambios**:
- Función `handleDownloadPDF()`: Agregado `folioNumber`
- Función `handleSendPagareEmail()`: Agregado `folioNumber`
- Removido parámetro `watermark` en ambas funciones

**Líneas modificadas**: ~20 líneas

---

## 🎨 Antes vs Después

### Header
**ANTES**:
```
           [LOGO CENTRADO]
    
    CORPORACIÓN EDUCACIONAL WINTERHILL
            RUT: 65.152.884-4
    
    ════════════════════════════════════
```

**DESPUÉS**:
```
[LOGO]   CORPORACIÓN EDUCACIONAL WINTERHILL      FOLIO N° AB12CD34
         RUT: 65.152.884-4
         Viña del Mar, Región de Valparaíso

══════════════════════════════════════════════════════════════
```

### Tabla de Estudiantes
**ANTES**:
- Sin márgenes, puede sobreponerse al texto
- Bordes simples
- Sin color en encabezados

**DESPUÉS**:
- Márgenes de 15px arriba y abajo
- Encabezados azul oscuro con texto blanco
- Bordes bien definidos
- No se corta entre páginas

### Documento Completo
**ANTES**:
- Marca de agua "NO FIRMADO" diagonal
- Saltos de línea no respetados
- Márgenes inferiores ajustados

**DESPUÉS**:
- ✅ Sin marca de agua
- ✅ Saltos de línea preservados
- ✅ Mayor espacio inferior (80mm)
- ✅ Folio visible
- ✅ Logo proporcional

---

## 🧪 Testing Recomendado

1. **Generar Pagaré**:
   - Ir a Matrícula > Paso 2
   - Hacer clic en "Generar Vista Previa"
   - Descargar PDF
   - Verificar:
     - ✅ Logo a la izquierda, proporcional
     - ✅ Folio en esquina superior derecha
     - ✅ Sin marca de agua
     - ✅ Tabla de estudiantes bien separada
     - ✅ Saltos de línea correctos

2. **Enviar por Email**:
   - Usar botón "Enviar Pagaré"
   - Verificar que el PDF adjunto tenga las mismas mejoras

3. **Múltiples Páginas**:
   - Crear pagaré con mucho contenido
   - Verificar que header con folio aparezca en todas las páginas
   - Verificar que tablas no se corten

---

## 📝 Notas Técnicas

### Logo
- Ruta esperada: `/public/logo-winterhill.png`
- Si no existe, se omite sin error
- Timeout de carga: 3 segundos

### Folio
- Generado a partir de `documentRecord.id` (primeros 8 caracteres)
- Fallback: Últimos 8 dígitos del timestamp
- Formato: Texto en MAYÚSCULAS

### Calidad PDF
- DPI equivalente: ~375 (scale: 2.5)
- Formato: A4 portrait
- Compresión: FAST (balance calidad/tamaño)

---

## ✅ Resumen

Todas las mejoras solicitadas han sido implementadas exitosamente:

1. ✅ **Márgenes inferiores**: Aumentados de 70mm a 80mm
2. ✅ **Saltos de línea**: Preservados con `whiteSpace: 'pre-wrap'`
3. ✅ **Marca de agua**: Removida completamente
4. ✅ **Logo**: Proporcional y alineado a la izquierda
5. ✅ **Tablas**: Con márgenes y sin sobreposición (`page-break-inside: avoid`)
6. ✅ **Folio**: Agregado en esquina superior derecha

El PDF del Pagaré ahora tiene un formato **profesional y limpio**, listo para impresión y distribución.
