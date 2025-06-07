import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { PdfPreviewer } from '../../widgets/pdf-previewer/pdf-previewer';
import { environment } from '../../../environments/environments';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-pdf-viewer',
  imports: [CommonModule, PdfPreviewer],
  templateUrl: './pdf-viewer.html',
  styleUrl: './pdf-viewer.css'
})
export class PdfViewer implements OnInit {

  pdfUrl: string = '';
  pdfId: string = '';
  constructor(private route: ActivatedRoute) {
  }
  ngOnInit(): void {
    const pdfId = this.route.snapshot.paramMap.get('pdfId');
    console.log('PDF ID:', pdfId);

    fetch(environment.pdfUrlBase + '/' + pdfId)
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('PDF not found');
      })
      .then(pdfData => {
        this.pdfUrl = pdfData;
        console.log('PDF URL:', this.pdfUrl);
      })
      .catch(error => {
        console.error(error);
      });
  }
}
