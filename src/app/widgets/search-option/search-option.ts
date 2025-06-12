import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Louvor } from '../../models/louvor';
import { CommonModule } from '@angular/common';
import { ClassificacaoPipe } from '../../utils/classificacao.pipe';
import { environment } from '../../../environments/environments';
import { ROUTES_PATH_STR } from '../../routes.enum';

@Component({
  selector: 'app-search-option',
  imports: [CommonModule, ClassificacaoPipe],
  templateUrl: './search-option.html',
  styleUrl: './search-option.css'
})
export class SearchOption {
  @Input() louvor!: Louvor;
  @Input() canAddLouvor: boolean = true;
  @Output() addLouvor = new EventEmitter<Louvor>();

  constructor() {}

  async openPdf(event: MouseEvent) {
    event.stopPropagation();
    event.preventDefault();
    const pdfUrl = environment.baseUrl + '/' + ROUTES_PATH_STR.PDF_VIEWER + '/' + this.louvor.pdfId;
    window.open(pdfUrl, '_blank');
  }

  addToList(event: MouseEvent) {
    event.stopPropagation();
    event.preventDefault();
    this.addLouvor.emit(this.louvor);
  }
}