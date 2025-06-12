import { Component } from '@angular/core';
import { SidebarMenu } from '../../widgets/sidebar-menu/sidebar-menu';
import { ActivatedRoute } from '@angular/router';
import { environment } from '../../../environments/environments';
import { Louvor } from '../../models/louvor';
import { SearchOptions } from "../../widgets/search-options/search-options";
import { LouvoresService } from '../../services/louvores/louvores-service';

@Component({
  selector: 'app-pdf-collection',
  imports: [SidebarMenu, SearchOptions],
  templateUrl: './pdf-collection.html',
  styleUrl: './pdf-collection.css'
})
export class PdfCollection {

  louvoresList: Louvor[] = [];

  constructor(private route: ActivatedRoute, private louvoresService: LouvoresService) {
  }
  ngOnInit(): void {
    const pdfs = JSON.parse(this.route.snapshot.queryParamMap.get('pdfs') || '[]') as string[];

    Promise.all(pdfs.map(pdf => this.louvoresService.getLouvorByPdfId(pdf)))
      .then(louvores => {
        this.louvoresList = louvores.filter((louvor): louvor is Louvor => !!louvor);
      })
      .catch(error => {
        console.error(error);
      });
  }
}
