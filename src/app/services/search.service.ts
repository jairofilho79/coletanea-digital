import { Injectable } from '@angular/core';
import { environment } from '../../environments/environments';

@Injectable({
  providedIn: 'root'
})
export class SearchService {

  constructor() {}

  getSearch(params: string): Promise<any> {
      return fetch(`${environment.apiUrl}/search/${params}`)
        .then(response => response.json());
    }
}
