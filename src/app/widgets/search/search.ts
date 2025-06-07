import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Output, EventEmitter } from '@angular/core';
import { LouvoresResponse } from '../../models/louvores-response';
import { SearchService } from '../../services/search.service';
import { Louvor } from '../../models/louvor';

@Component({
  selector: 'app-search',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './search.html',
  styleUrl: './search.css'
})
export class Search {
  searchText = '';
  @Output() searchResult = new EventEmitter<LouvoresResponse>();
  @Output() clearSearch = new EventEmitter<any>();

  constructor(private searchService: SearchService) {}

  // async fetchData(query: string): Promise<LouvoresResponse> {
  //   // Simula uma chamada a um serviço ou API
  //   const louvores: Louvor[] = [{
  //     "nome": "Aquilo que fui não sou mais",
  //     "classificacao": "ColAdultos",
  //     "numero": 0,
  //     "categoria": "Contra Capa",
  //     "pdf": "000.pdf",
  //   },
  //   {
  //     "nome": "Meu Deus, meu pai",
  //     "classificacao": "ColCIAs",
  //     "numero": 1,
  //     "categoria": "Clamor",
  //     "pdf": "001.pdf",
  //   },
  //   {
  //     "nome": "O Sangue de Jesus tem poder",
  //     "classificacao": "ColAdultos",
  //     "numero": 1,
  //     "categoria": "Clamor",
  //     "pdf": "001.pdf",
  //   }];
  //   return Promise.resolve({ result: `Dados para: ${query}`, louvores });
  // }

  async buscar(): Promise<void> {
    if (this.hasValue) {
      const data: Louvor[] = await this.searchService.getSearch(this.searchText);
      this.searchResult.emit({ louvores: data });
    }
  }

  get hasValue(): boolean {
    return this.searchText.trim().length > 0;
  }

  get acharButtonText(): string {
    return this.hasValue ? 'Procurar' : 'Digite...';
  }

  limpar(): void {
    this.searchText = '';
    this.clearSearch.emit();
  }

  podeLimpar() {
    if(!this.hasValue) {
      this.limpar();
    }
  }
}