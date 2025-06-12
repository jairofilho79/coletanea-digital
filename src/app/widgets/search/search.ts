import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Output, EventEmitter } from '@angular/core';
import { LouvoresResponse } from '../../models/louvores-response';
import { Louvor } from '../../models/louvor';
import { LouvoresService } from '../../services/louvores/louvores-service';

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

  constructor(private louvoresService: LouvoresService) {}

  async buscar(): Promise<void> {
    if (this.hasValue) {
      const data: Louvor[] = await this.louvoresService.handleSearch(this.searchText);
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