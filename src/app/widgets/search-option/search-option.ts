import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Louvor } from '../../models/louvor';
import { CommonModule } from '@angular/common';
import { ClassificacaoPipe } from '../../utils/classificacao.pipe';
import { ROUTES_PATH_STR } from '../../routes.enum';
import { Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { heroArrowTopRightOnSquare, heroPlus } from '@ng-icons/heroicons/outline';

@Component({
  selector: 'app-search-option',
  imports: [CommonModule, ClassificacaoPipe, NgIcon],
  templateUrl: './search-option.html',
  styleUrl: './search-option.css',
  viewProviders: [provideIcons({ heroArrowTopRightOnSquare, heroPlus })]
})
export class SearchOption {
  @Input() louvor!: Louvor;
  @Input() canAddLouvor: boolean = true;
  @Output() addLouvor = new EventEmitter<Louvor>();

  constructor(private router: Router) { }

  async openPdf(event: MouseEvent) {
    event.stopPropagation();
    event.preventDefault();
    const url = this.router.serializeUrl(
      this.router.createUrlTree([ROUTES_PATH_STR.PDF_VIEWER, this.louvor.pdfId])
    );
    window.open(url, '_blank');
  }

  addToList(event: MouseEvent) {
    event.stopPropagation();
    event.preventDefault();
    this.addLouvor.emit(this.louvor);
  }
}