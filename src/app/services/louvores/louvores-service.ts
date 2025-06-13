import { Injectable } from '@angular/core';
import jsonData from '../../../../louvores.json';
import { Louvor } from '../../models/louvor';
import { environment } from '../../../environments/environments';

@Injectable({
  providedIn: 'root'
})
export class LouvoresService {
  private louvores = jsonData as unknown as Louvor[];

  constructor() { }

  async handleSearch(searchStr: string): Promise<Louvor[]> {
    const search = searchStr.trim();
    console.log('Search input:', search);
    if (!isNaN(Number(search))) {
      console.log('Search is a number:', this.louvores);
      return this.louvores.filter(louvor => Number(louvor.numero) === Number(search))
    }
    const searchT = this.normalizeSearchString(search);
    console.log('Normalized search string:', searchT);
    const louvor = this.louvores.filter(louvor => {
      const titulo = this.normalizeSearchString(louvor.nome);
      return titulo.includes(searchT);
    });
    console.log('Search result:', louvor);
    return louvor;
  }

  normalizeSearchString = (str: string) => {
    return str.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9\s]/g, '');
  };

  getLouvorByPdfId(pdfId: string): Promise<Louvor | undefined> {
    return Promise.resolve(this.louvores.find(louvor => louvor.pdfId === pdfId));
  }

  getPDFUrl(louvor: Louvor): Promise<string> {
    return Promise.resolve(environment.pdfFileUrlApi + '/' + this.decodeBase64(louvor.pdfId));
  }

  decodeBase64(pdfId: string): string {
    return atob(pdfId);
  }


}
