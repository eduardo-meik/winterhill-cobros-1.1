import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import { format } from 'date-fns';
import html2canvas from 'html2canvas';

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
      this.currentY += 10;
      this.doc.setFontSize(12);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text('Filtros aplicados:', this.margin, this.currentY);
      
      this.doc.setFont('helvetica', 'normal');
      this.doc.setFontSize(10);
      
      Object.entries(this.filters).forEach(([key, value], index) => {
        this.currentY += 5;
        this.doc.text(`${key}: ${value}`, this.margin + 5, this.currentY);
      });
    }

    this.currentY += 15;
  }

  addSummary(summaryData) {
    this.doc.setFontSize(12);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Resumen de Cobros:', this.margin, this.currentY);
    
    this.currentY += 8;
    this.doc.setFontSize(10);
    this.doc.setFont('helvetica', 'normal');
    
    // Format numbers with thousand separators
    const formatNumber = (number) => `$${Math.round(number).toLocaleString('es-CL')}`;
    
    const summaryTable = [
      ['Total Pagado', formatNumber(summaryData.totalPaid)],
      ['Total Pendiente', formatNumber(summaryData.totalPending)],
      ['Total Vencido', formatNumber(summaryData.totalOverdue)],
      ['Cantidad de Pagos', summaryData.paymentCount.toString()],
      ['Tasa de Morosidad', `${summaryData.delinquencyRate}%`]
    ];
    
    this.doc.autoTable({
      startY: this.currentY,
      head: [['Concepto', 'Valor']],
      body: summaryTable,
      theme: 'grid',
      headStyles: {
        fillColor: [79, 70, 229],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      styles: {
        fontSize: 10,
        cellPadding: 5
      },
      margin: { left: this.margin }
    });
    
    this.currentY = this.doc.lastAutoTable.finalY + 15;
  }

  addPaymentsTable(payments) {
    // Check remaining space and add new page if necessary
    if (this.currentY > (this.pageHeight - 100)) {
      this.doc.addPage();
      this.currentY = this.margin;
    }
    
    this.doc.setFontSize(12);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Detalle de Pagos:', this.margin, this.currentY);
    
    const tableData = payments.map(payment => [
      payment.student?.whole_name || 
        `${payment.student?.first_name || ''} ${payment.student?.apellido_paterno || ''}`,
      payment.student?.cursos?.nom_curso || 'No asignado',
      payment.numero_cuota || 'N/A',
      payment.amount ? `$${Math.round(payment.amount).toLocaleString('es-CL')}` : '$0',
      payment.status === 'paid' ? 'Pagado' : 
        payment.status === 'pending' ? 'Pendiente' : 'Vencido',
      payment.due_date ? format(new Date(payment.due_date), 'dd/MM/yyyy') : 'N/A',
      payment.payment_method || 'No especificado'
    ]);
    
    this.doc.autoTable({
      startY: this.currentY + 8,
      head: [['Estudiante', 'Curso', 'Cuota N°', 'Monto', 'Estado', 'Vencimiento', 'Método']],
      body: tableData,
      theme: 'grid',
      headStyles: {
        fillColor: [79, 70, 229],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      },
      styles: {
        fontSize: 8,
        cellPadding: 3
      },
      columnStyles: {
        0: { cellWidth: 40 },
        1: { cellWidth: 25 },
        2: { cellWidth: 15 },
        3: { cellWidth: 20 },
        4: { cellWidth: 20 },
        5: { cellWidth: 25 },
        6: { cellWidth: 25 }
      },
      margin: { left: this.margin },
      didDrawPage: (data) => {
        // Add header on each page
        this.doc.setFontSize(10);
        this.doc.setFont('helvetica', 'normal');
        this.doc.text(
          `Informe de Aranceles - Página ${data.pageCount}`,
          this.margin,
          10
        );
      }
    });
    
    this.currentY = this.doc.lastAutoTable.finalY + 15;
  }

  async addChart(chartRef, title) {
    if (!chartRef || typeof chartRef.current === 'undefined') return;
    
    // Check if we need to add a new page
    if (this.currentY > (this.pageHeight - 120)) {
      this.doc.addPage();
      this.currentY = this.margin;
    }
    
    try {
      // Add chart title
      this.doc.setFontSize(12);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text(title, this.margin, this.currentY);
      this.currentY += 8;
      
      // Convert the chart to image with better options for reliable rendering
      const canvas = await html2canvas(chartRef.current, {
        scale: 2,
        backgroundColor: null,
        logging: false,
        allowTaint: true,
        useCORS: true,
        onclone: (clonedDoc) => {
          // Fix for SVG rendering issues in some browsers
          const svgs = clonedDoc.querySelectorAll('svg');
          svgs.forEach(svg => {
            if (!svg.getAttribute('width') && !svg.getAttribute('height')) {
              const box = svg.getBoundingClientRect();
              svg.setAttribute('width', box.width);
              svg.setAttribute('height', box.height);
            }
          });
        }
      });
      
      // Convert canvas to image and add to PDF
      const chartImage = canvas.toDataURL('image/png');
      
      // Calculate dimensions to fit in the page
      const chartWidth = this.pageWidth - (this.margin * 2);
      const chartHeight = (canvas.height * chartWidth) / canvas.width;
      
      // Ensure the chart fits on the page
      if (this.currentY + chartHeight > this.pageHeight - this.margin) {
        this.doc.addPage();
        this.currentY = this.margin;
        // Add the title again on the new page
        this.doc.setFontSize(12);
        this.doc.setFont('helvetica', 'bold');
        this.doc.text(`${title} (continuación)`, this.margin, this.currentY);
        this.currentY += 8;
      }
      
      this.doc.addImage(
        chartImage,
        'PNG',
        this.margin,
        this.currentY,
        chartWidth,
        chartHeight
      );
      
      this.currentY += chartHeight + 15;
      return true;
    } catch (error) {
      console.error('Error adding chart to PDF:', error);
      // Continue without the chart rather than failing the entire PDF
      return false;
    }
  }

  addFooter() {
    const totalPages = this.doc.internal.getNumberOfPages();
    
    for (let i = 1; i <= totalPages; i++) {
      this.doc.setPage(i);
      this.doc.setFontSize(8);
      this.doc.setFont('helvetica', 'normal');
      this.doc.text(
        `Página ${i} de ${totalPages}`,
        this.pageWidth / 2,
        this.pageHeight - 10,
        { align: 'center' }
      );
    }
  }

  save(filename = 'informe.pdf') {
    this.addFooter();
    this.doc.save(filename);
  }
}