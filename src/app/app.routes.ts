import { Routes } from '@angular/router';

export const routes: Routes = [
  { 
    path: '', 
    redirectTo: '/biblioteca', 
    pathMatch: 'full' 
  },
  { 
    path: 'biblioteca', 
    loadComponent: () => import('./components/biblioteca/biblioteca.component').then(m => m.BibliotecaComponent)
  },
  { 
    path: 'upload', 
    loadComponent: () => import('./components/upload-material/upload-material.component').then(m => m.UploadMaterialComponent)
  }
];
