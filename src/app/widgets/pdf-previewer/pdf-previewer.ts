import { Component, ElementRef, Input, OnInit, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import * as pdfjsLib from 'pdfjs-dist';
import { debounceTime, Subject } from 'rxjs';

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
  protected viewMode: 'vertical' | 'horizontal' | 'custom' = 'vertical';
  customScale: number = 100;
  private customScaleSubject = new Subject<number>();
  protected isWidthSmallerThenPDF = false;

  private pdfDoc: any = null;
  protected pageRendering = false;
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
      this.pageRendering = true;
      await this.loadPdf(this.pdfUrl);
      this.customScaleSubject.pipe(debounceTime(1200)).subscribe((value) => {
      if (value >= 50 && value <= 300) {
        this.renderPage();
      }
    });
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
    this.pageRendering = true;

    try {
      const page = await this.pdfDoc.getPage(this.currentPage);
      const viewportOriginal = page.getViewport({ scale: 1.0 });

      const toolbarHeight = 80;
      const margin = 32;
      let scale: number;

      this.isWidthSmallerThenPDF = window.innerWidth < viewportOriginal.height;

      const availableWidth = window.innerWidth - margin;
      if (this.viewMode === 'horizontal') {
        scale = availableWidth / viewportOriginal.width;
      } else if (this.viewMode === 'custom') {
        scale = this.customScale / 100;
      } else {
        const availableHeight = window.innerHeight - toolbarHeight - margin;
        scale = availableHeight / viewportOriginal.height;
      }

      const dpiScale = window.devicePixelRatio || 1;
      const viewport = page.getViewport({ scale: scale * dpiScale });

      const canvas = this.pdfCanvas.nativeElement;
      canvas.width = Math.ceil(viewport.width);
      canvas.height = Math.ceil(viewport.height);

      canvas.style.width = `${Math.ceil(viewport.width / dpiScale)}px`;
      canvas.style.height = `${Math.ceil(viewport.height / dpiScale)}px`;

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

  changeCustomScale() {
    if (this.viewMode === 'custom' && typeof this.customScale === 'number' && !isNaN(this.customScale)) {
      this.customScaleSubject.next(this.customScale);
    }
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