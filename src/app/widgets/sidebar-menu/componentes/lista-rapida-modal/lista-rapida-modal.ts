import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Louvor } from '../../../../models/louvor';
import { environment } from '../../../../../environments/environments';
import { ROUTES_PATH_STR } from '../../../../routes.enum';

@Component({
  selector: 'app-lista-rapida-modal',
  imports: [CommonModule],
  templateUrl: './lista-rapida-modal.html',
  styleUrl: './lista-rapida-modal.css'
})
export class ListaRapidaModal {
  @Input() louvorList: Louvor[] = [];
  @Output() close = new EventEmitter<void>();
  onClose() {
    this.close.emit();
  }
  copied = false;

  hasPdf(): boolean {
    return Array.isArray(this.louvorList) && this.louvorList.some((l: any) => !!l && !!l.pdfId);
  }

  getPdfUrl(): string {
    return environment.baseUrl + '/' + ROUTES_PATH_STR.PDF_COLLECTION + '?pdfs=' + JSON.stringify(this.louvorList.filter(l => l.pdfId).map(l => l.pdfId));
  }

  copyToClipboard() {
    const pdfUrl = this.getPdfUrl();
    navigator.clipboard.writeText(pdfUrl).then(() => {
      console.log('PDF URL copied to clipboard:', pdfUrl);
      this.copied = true;
    }).catch(err => {
      console.error('Failed to copy PDF URL:', err);
    });
  }

}
