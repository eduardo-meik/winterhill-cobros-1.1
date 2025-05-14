import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import { format } from 'date-fns';

export class PDFReport {
  constructor(title, filters = {}) {
    this.doc = new jsPDF();
    this.title = title;
    this.filters = filters;
    this.pageHeight = this.doc.internal.pageSize.height;
    this.pageWidth = this.doc.internal.pageSize.width;
    this.margin = 20;
    this.currentY = this.margin;
  }

  addHeader() {
    // Add logo or institution name
    this.doc.setFontSize(16);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Sistema de Cobros Escolares', this.margin, this.currentY);
    
    // Add report title
    this.currentY += 10;
    this.doc.setFontSize(14);
    this.doc.text(this.title, this.margin, this.currentY);
    
    // Add date and time
    this.currentY += 6;
    this.doc.setFontSize(10);
    this.doc.setFont('helvetica', 'normal');
    this.doc.text(
      `Generado el: ${format(new Date(), 'dd/MM/yyyy HH:mm')}`,
      this.margin,
      this.currentY
    );

    // Add filters if any
    if (Object.keys(this.filters).length > 0) {
      this.currentY += 8;
      this.doc.setFontSize(10);
      this.doc.text('Filtros aplicados:', this.margin, this.currentY);
      
      Object.entries(this.filters).forEach(([key, value]) => {
        if (value && value !== 'all' && value.length > 0) { // Ensure value is not empty array for multi-selects
          this.currentY += 5;
          const displayValue = Array.isArray(value) ? value.join(', ') : value;
          this.doc.text(`${key}: ${displayValue}`, this.margin + 10, this.currentY);
        }
      });
    }

    this.currentY += 15;
  }

  addSummary(summaryInput) {
    this.doc.setFontSize(12);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Resumen', this.margin, this.currentY);
    
    this.currentY += 8;
    this.doc.setFont('helvetica', 'normal');
    this.doc.setFontSize(10);

    const totalPaid = (typeof summaryInput.totalPaid === 'number' ? summaryInput.totalPaid : 0).toLocaleString('es-CL');
    const totalPending = (typeof summaryInput.totalPending === 'number' ? summaryInput.totalPending : 0).toLocaleString('es-CL');
    const totalOverdue = (typeof summaryInput.totalOverdue === 'number' ? summaryInput.totalOverdue : 0).toLocaleString('es-CL');
    const paymentCount = (typeof summaryInput.paymentCount === 'number' ? summaryInput.paymentCount : 0).toString();
    const delinquencyRate = (summaryInput.delinquencyRate !== undefined && summaryInput.delinquencyRate !== null) ? summaryInput.delinquencyRate.toString() : '0.0';
    
    const summaryDisplayData = [
      ['Total Pagado:', `$${totalPaid}`],
      ['Total Pendiente:', `$${totalPending}`],
      ['Total Vencido:', `$${totalOverdue}`],
      ['Cantidad de Pagos:', paymentCount],
      ['Tasa de Morosidad:', `${delinquencyRate}%`]
    ];

    summaryDisplayData.forEach(([label, value]) => {
      this.doc.text(label, this.margin, this.currentY);
      this.doc.text(value, this.margin + 50, this.currentY); // Adjusted x-position for value
      this.currentY += 6;
    });

    this.currentY += 10;
  }

  addPaymentsTable(payments) {
    if (!payments || payments.length === 0) {
      this.doc.setFontSize(10); // Adjusted font size
      this.doc.setFont('helvetica', 'italic'); // Italic for placeholder
      this.doc.text('No hay datos de pagos para mostrar con los filtros seleccionados.', this.margin, this.currentY);
      this.currentY += 10;
      return;
    }
    
    this.doc.setFontSize(12);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Detalle de Pagos', this.margin, this.currentY);
    
    this.currentY += 8; // Reduced space

    const headers = [
      'Estudiante',
      'Curso',
      'Monto',
      'Estado',
      'Vencimiento',
      'Método'
    ];

    const data = payments.map(payment => {
      try {
        return [
          payment.student?.whole_name || `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`,
          payment.student?.cursos?.nom_curso || 'Sin curso',
          `$${Math.round(payment.amount || 0).toLocaleString('es-CL')}`,
          payment.status === 'paid' ? 'Pagado' : payment.status === 'pending' ? 'Pendiente' : 'Vencido',
          payment.due_date ? format(new Date(payment.due_date), 'dd/MM/yyyy') : 'N/A',
          payment.payment_method || '-'
        ];
      } catch (e) {
        console.error('Error processing payment for PDF table:', e, payment);
        return ['Error', 'Error', 'Error', 'Error', 'Error', 'Error'];
      }
    });

    this.doc.autoTable({
      head: [headers],
      body: data,
      startY: this.currentY,
      margin: { top: 5, right: this.margin, bottom: 10, left: this.margin }, // Reduced top margin
      styles: {
        fontSize: 8, // Reduced font size for more data
        cellPadding: 2 // Reduced cell padding
      },
      headStyles: {
        fillColor: [79, 70, 229], // Primary color
        textColor: 255,
        fontStyle: 'bold',
        fontSize: 9
      },
      alternateRowStyles: {
        fillColor: [243, 244, 246] // Lighter gray for alternate rows
      },
      tableWidth: 'auto' // Auto width
    });

    this.currentY = this.doc.lastAutoTable.finalY + 10; // Reduced space after table
  }

  addFooter() {
    const pageCount = this.doc.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      this.doc.setPage(i);
      this.doc.setFontSize(8);
      this.doc.text(
        `Página ${i} de ${pageCount}`,
        this.pageWidth / 2,
        this.pageHeight - 10,
        { align: 'center' }
      );
    }
  }

  addChart(chartRef, title) {
    try {
      if (!chartRef?.current) {
        console.warn(`Chart ref for "${title}" is not current.`);
        return;
      }
      
      const chartAPI = chartRef.current;

      // Check if adding a new page is necessary
      if (this.currentY + 80 > this.pageHeight - this.margin) { // Estimate chart height + title
         this.doc.addPage();
         this.currentY = this.margin;
      } else {
        this.currentY += 5; // Some spacing if not a new page
      }

      this.doc.setFontSize(12);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text(title, this.margin, this.currentY);
      this.currentY += 8;

      const canvas = chartAPI.canvas; 
    
      if (canvas && typeof canvas.toDataURL === 'function') {
        const imgData = canvas.toDataURL('image/png', 0.9); // Use 0.9 for slight compression if needed
        const aspectRatio = canvas.width / canvas.height;
        let imgWidth = this.pageWidth - (this.margin * 2);
        let imgHeight = imgWidth / aspectRatio;

        // If image is too tall, constrain by height and recalculate width
        const maxHeight = this.pageHeight - this.currentY - this.margin - 10; // Max available height
        if (imgHeight > maxHeight) {
            imgHeight = maxHeight;
            imgWidth = imgHeight * aspectRatio;
        }

        this.doc.addImage(
          imgData,
          'PNG',
          this.margin,
          this.currentY,
          imgWidth,
          imgHeight
        );
        this.currentY += imgHeight + 10;
      } else {
        console.warn(`Canvas not found or not a valid canvas element for chart: "${title}"`);
      }
    } catch (error) {
      console.error(`Error adding chart "${title}" to PDF:`, error);
    }
  }
}