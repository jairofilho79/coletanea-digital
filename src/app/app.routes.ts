import { Routes } from '@angular/router';
import { PesquisadorSimples } from './pages/pesquisador-simples/pesquisador-simples';
import { PdfViewer } from './pages/pdf-viewer/pdf-viewer';
import { ROUTES_PATH_STR } from './routes.enum';
import { PdfCollection } from './pages/pdf-collection/pdf-collection';

export const routes: Routes = [
    { 
        path: ROUTES_PATH_STR.HOME, 
        component: PesquisadorSimples 
    },
    {
        path: ROUTES_PATH_STR.PDF_VIEWER + '/:pdfId',
        component: PdfViewer
    },
    {
        path: ROUTES_PATH_STR.PDF_COLLECTION,
        component: PdfCollection
    }
];
