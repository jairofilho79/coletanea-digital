import { Routes } from '@angular/router';
import { BibliotecaComponent } from './components/biblioteca/biblioteca.component';
import { UploadMaterialComponent } from './components/upload-material/upload-material.component';
import { GerenciarListasComponent } from './components/gerenciar-listas/gerenciar-listas.component';
import { GerenciarLouvorComponent } from './components/gerenciar-louvores/gerenciar-louvores.component';
import { GerenciarArranjoComponent } from './components/gerenciar-arranjos/gerenciar-arranjos.component';

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
  },
  {
    path: 'gerenciar-listas',
    component: GerenciarListasComponent
  },
  {
    path: 'gerenciar-louvores',
    component: GerenciarLouvorComponent
  },
  {
    path: 'gerenciar-arranjos',
    component: GerenciarArranjoComponent
  }
];
