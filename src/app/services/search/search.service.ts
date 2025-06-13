import { Injectable } from '@angular/core';
import { LouvoresService } from '../louvores/louvores-service';
import { Louvor } from '../../models/louvor';

@Injectable({
  providedIn: 'root'
})
export class SearchService {

  constructor(private louvoresService: LouvoresService) { }

  getSearch(params: string): Promise<Louvor[]> {
    // return fetch(`${environment.apiUrl}/search/${params}`)
    //   .then(response => response.json());
    return Promise.resolve(this.louvoresService.handleSearch(params));
  }
}
