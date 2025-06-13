import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { PdfPreviewer } from '../../widgets/pdf-previewer/pdf-previewer';
import { environment } from '../../../environments/environments';
import { CommonModule } from '@angular/common';
import { LouvoresService } from '../../services/louvores/louvores-service';

@Component({
  selector: 'app-pdf-viewer',
  imports: [CommonModule, PdfPreviewer],
  templateUrl: './pdf-viewer.html',
  styleUrl: './pdf-viewer.css'
})
export class PdfViewer implements OnInit {

  pdfUrl: string = '';
  pdfId: string = '';
  constructor(private route: ActivatedRoute, private louvoresService: LouvoresService) {
  }
  async ngOnInit(): Promise<void> {
    const pdfId = this.route.snapshot.paramMap.get('pdfId');

    const louvor = await this.louvoresService.getLouvorByPdfId(pdfId || '');
    if (louvor) {
      this.pdfUrl = await this.louvoresService.getPDFUrl(louvor);
    } else {
      console.error('PDF not found');
    }
  }
}
