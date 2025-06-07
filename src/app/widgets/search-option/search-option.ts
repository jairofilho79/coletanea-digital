import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Louvor } from '../../models/louvor';
import { environment } from '../../../environments/environments';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-search-option',
  imports: [CommonModule],
  templateUrl: './search-option.html',
  styleUrl: './search-option.css'
})
export class SearchOption {
  @Input() louvor!: Louvor;
  @Input() canAddLouvor: boolean = true;
  @Output() addLouvor = new EventEmitter<Louvor>();

  openPdf(event: MouseEvent) {
    event.stopPropagation();
    event.preventDefault();
    window.open(environment.baseUrl + '/pdf-viewer/' + this.louvor.pdfId, '_blank');
  }

  addToList(event: MouseEvent, pdfId: string) {
    event.stopPropagation();
    event.preventDefault();
    this.addLouvor.emit(this.louvor);
  }
}