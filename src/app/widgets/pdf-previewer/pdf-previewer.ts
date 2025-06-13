import { Component, ElementRef, Input, OnInit, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import * as pdfjsLib from 'pdfjs-dist';

@Component({
  selector: 'app-pdf-previewer',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './pdf-previewer.html',
  styleUrl: './pdf-previewer.css'
})
export class PdfPreviewer implements OnInit {
  @ViewChild('pdfCanvas') pdfCanvas!: ElementRef<HTMLCanvasElement>;
  @Input() pdfUrl: string = '';

  protected currentPage = 1;
  protected totalPages = 0;
  protected viewMode: 'vertical' | 'horizontal' = 'vertical';
  protected isWidthSmallerThenPDF = false;

  private pdfDoc: any = null;
  private pageRendering = false;
  private pageNumPending: number | null = null;


  constructor() {
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'assets/pdfjs-dist/build/pdf.worker.min.mjs';
  }

  @HostListener('window:resize')
  onResize() {
    if (this.pdfDoc) {
      this.renderPage();
    }
  }

  async ngOnInit() {
    try {
      await this.loadPdf(this.pdfUrl);
    } catch (error) {
      console.error('Error loading PDF:', error);
    }
  }

  async loadPdf(url: string) {
    try {
      this.pdfDoc = await pdfjsLib.getDocument(url).promise;
      this.totalPages = this.pdfDoc.numPages;
      await this.renderPage();
    } catch (error) {
      console.error('Error loading document: ', error);
    }
  }

  async renderPage() {
    if (this.pageRendering) {
      this.pageNumPending = this.currentPage;
      return;
    }

    this.pageRendering = true;

    try {
      const page = await this.pdfDoc.getPage(this.currentPage);
      const viewportOriginal = page.getViewport({ scale: 1.0 });

      const toolbarHeight = 80;
      const margin = 32;
      let scale: number;
      
      const availableWidth = window.innerWidth - margin;
      if (this.viewMode === 'horizontal') {
        // In horizontal mode, fit width to screen (minus margin)
        scale = availableWidth / viewportOriginal.width;
      } else {
        // In vertical mode, fit height to screen (minus toolbar and margin)
        const availableHeight = window.innerHeight - toolbarHeight - margin;
        scale = availableHeight / viewportOriginal.height;
      }

      const viewport = page.getViewport({ scale });
      const canvas = this.pdfCanvas.nativeElement;
      canvas.height = Math.ceil(viewport.height);
      canvas.width = Math.ceil(viewport.width);

      console.log('Viewport dimensions:', availableWidth);
      
      this.isWidthSmallerThenPDF = (availableWidth < 595) && this.viewMode === 'vertical';
      console.log('isWidthSmallerThenPDF:', this.isWidthSmallerThenPDF);

      const renderContext = {
        canvasContext: canvas.getContext('2d'),
        viewport: viewport
      };

      await page.render(renderContext).promise;
      this.pageRendering = false;

      if (this.pageNumPending !== null) {
        this.currentPage = this.pageNumPending;
        this.pageNumPending = null;
        this.renderPage();
      }
    } catch (error) {
      console.error('Error rendering page:', error);
      this.pageRendering = false;
    }
  }

  changeViewMode() {
    this.renderPage();
  }

  previousPage() {
    if (this.currentPage <= 1) return;
    this.currentPage--;
    this.renderPage();
  }

  nextPage() {
    if (this.currentPage >= this.totalPages) return;
    this.currentPage++;
    this.renderPage();
  }
}