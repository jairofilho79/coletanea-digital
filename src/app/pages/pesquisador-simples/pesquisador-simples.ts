import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Louvor } from '../../models/louvor';
import { LouvoresResponse } from '../../models/louvores-response';
import { PdfPreviewer } from '../../widgets/pdf-previewer/pdf-previewer';
import { SearchOptions } from '../../widgets/search-options/search-options';
import { Search } from '../../widgets/search/search';
import { SidebarMenu } from '../../widgets/sidebar-menu/sidebar-menu';

@Component({
  selector: 'app-pesquisador-simples',
  imports: [CommonModule, Search, SearchOptions, SidebarMenu],
  templateUrl: './pesquisador-simples.html',
  styleUrl: './pesquisador-simples.css'
})
export class PesquisadorSimples {
  louvoresSearchList: Louvor[] = [];
  hasSearched = false;
  louvorListaRapida: Louvor[] = [];

  onSearchResult(event: LouvoresResponse) {
    this.louvoresSearchList = event.louvores;
    this.hasSearched = true;
  }

  onClearSearch() {
    this.louvoresSearchList = [];
    this.hasSearched = false;
  }
  onAddLouvor(louvor: Louvor) {
    if (!this.louvorListaRapida.some(l => l.pdfId === louvor.pdfId)) {
      this.louvorListaRapida = [...this.louvorListaRapida, louvor];
    }
  }
}
