import { Routes } from '@angular/router';
import { BibliotecaComponent } from './components/biblioteca/biblioteca.component';
import { UploadMaterialComponent } from './components/upload-material/upload-material.component';

export const routes: Routes = [
  { 
    path: '', 
    redirectTo: '/biblioteca', 
    pathMatch: 'full' 
  },
  { 
    path: 'biblioteca', 
    component: BibliotecaComponent
  },
  { 
    path: 'upload', 
    component: UploadMaterialComponent
  }
];
