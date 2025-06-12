import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Louvor } from '../../../../models/louvor';
import { environment } from '../../../../../environments/environments';
import { ROUTES_PATH_STR } from '../../../../routes.enum';
import { ClassificacaoPipe } from '../../../../utils/classificacao.pipe';
import { Router } from '@angular/router';

@Component({
  selector: 'app-lista-rapida-modal',
  imports: [CommonModule, ClassificacaoPipe, FormsModule],
  templateUrl: './lista-rapida-modal.html',
  styleUrl: './lista-rapida-modal.css'
})
export class ListaRapidaModal {
  @Input() louvorList: Louvor[] = [];
  @Output() close = new EventEmitter<void>();
  
  copied = false;
  editingIndex: number | null = null;
  newPosition: number = 1;
  removingIndex: number | null = null;
  removeCountdown: number = 0;
  removeTimeout: any = null;

  constructor(private router: Router) {}

  onClose() {
    this.close.emit();
  }

  hasPdf(): boolean {
    return Array.isArray(this.louvorList) && this.louvorList.some((l: any) => !!l && !!l.pdfId);
  }

  getPdfUrl(): string {
    const url = this.router.serializeUrl(
      this.router.createUrlTree([ROUTES_PATH_STR.PDF_COLLECTION], {
        queryParams: { pdfs: JSON.stringify(this.louvorList.filter(l => l.pdfId).map(l => l.pdfId)) }
      })
    );
    return window.location.origin + url;
  }

  getPdfPreviewerUrl(): string {
    const url = this.router.serializeUrl(
      this.router.createUrlTree([ROUTES_PATH_STR.PDF_VIEWER], {
        queryParams: { pdfs: JSON.stringify(this.louvorList.filter(l => l.pdfId).map(l => l.pdfId)) }
      })
    );
    return window.location.origin + url;
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

  startEditing(index: number) {
    this.editingIndex = index;
    this.newPosition = index + 1;
  }

  cancelEditing() {
    this.editingIndex = null;
    this.newPosition = 1;
  }

  confirmReorder() {
    if (this.editingIndex === null) return;
    
    // Validate the new position
    if (this.newPosition < 1 || this.newPosition > this.louvorList.length) {
      alert(`Posição deve estar entre 1 e ${this.louvorList.length}`);
      return;
    }

    const currentIndex = this.editingIndex;
    const targetIndex = this.newPosition - 1;

    if (currentIndex !== targetIndex) {
      // Remove the item from current position
      const item = this.louvorList.splice(currentIndex, 1)[0];
      // Insert it at the new position
      this.louvorList.splice(targetIndex, 0, item);
    }

    this.cancelEditing();
  }

  removeItem(index: number) {
    // If already removing this item, confirm removal immediately
    if (this.removingIndex === index) {
      this.confirmRemoval();
      return;
    }

    // Cancel any existing removal countdown
    this.cancelRemoval();

    // Start new removal countdown
    this.removingIndex = index;
    this.removeCountdown = 5;

    const countdown = () => {
      if (this.removingIndex !== index) return; // Safety check

      if (this.removeCountdown > 1) {
        this.removeCountdown--;
        this.removeTimeout = setTimeout(countdown, 1000);
      } else {
        // Countdown finished, cancel removal
        this.cancelRemoval();
      }
    };

    this.removeTimeout = setTimeout(countdown, 1000);
  }

  confirmRemoval() {
    if (this.removingIndex !== null) {
      const indexToRemove = this.removingIndex;
      this.louvorList.splice(indexToRemove, 1);
      
      // Cancel editing if we were editing the removed item or an item after it
      if (this.editingIndex !== null && this.editingIndex >= indexToRemove) {
        this.cancelEditing();
      }
    }
    this.cancelRemoval();
  }

  cancelRemoval() {
    if (this.removeTimeout) {
      clearTimeout(this.removeTimeout);
      this.removeTimeout = null;
    }
    this.removingIndex = null;
    this.removeCountdown = 0;
  }

  getRemoveButtonText(index: number): string {
    if (this.removingIndex === index) {
      return this.removeCountdown.toString();
    }
    return '❌';
  }

  getRemoveButtonClass(index: number): string {
    const baseClass = 'text-sm px-2 py-1 rounded cursor-pointer';
    if (this.removingIndex === index) {
      return `${baseClass} bg-red-200 text-red-800 hover:bg-red-300`;
    }
    return `${baseClass} text-red-600 hover:text-red-800 bg-gray-200 hover:bg-gray-300`;
  }

  ngOnDestroy() {
    // Clean up timeout when component is destroyed
    this.cancelRemoval();
  }
}