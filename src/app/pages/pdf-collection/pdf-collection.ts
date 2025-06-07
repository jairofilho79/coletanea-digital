import { Component } from '@angular/core';
import { SidebarMenu } from '../../widgets/sidebar-menu/sidebar-menu';
import { ActivatedRoute } from '@angular/router';
import { environment } from '../../../environments/environments';
import { Louvor } from '../../models/louvor';
import { SearchOptions } from "../../widgets/search-options/search-options";

@Component({
  selector: 'app-pdf-collection',
  imports: [SidebarMenu, SearchOptions],
  templateUrl: './pdf-collection.html',
  styleUrl: './pdf-collection.css'
})
export class PdfCollection {

  louvoresList: Louvor[] = [];

  constructor(private route: ActivatedRoute) {
  }
  ngOnInit(): void {
    const pdfs = JSON.parse(this.route.snapshot.queryParamMap.get('pdfs') || '[]') as string[];
    console.log('PDF ID:', pdfs);

    fetch(environment.apiUrl + '/pdfs/' + this.route.snapshot.queryParamMap.get('pdfs'))
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('PDF not found');
      })
      .then(pdfsData => {
        this.louvoresList = pdfsData;
        console.log('PDFs: ', pdfsData);
      })
      .catch(error => {
        console.error(error);
      });
  }
}
