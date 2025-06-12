import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { ListaRapidaModal } from './componentes/lista-rapida-modal/lista-rapida-modal';
import { Louvor } from '../../models/louvor';

@Component({
  selector: 'app-sidebar-menu',
  imports: [CommonModule, ListaRapidaModal],
  templateUrl: './sidebar-menu.html',
  styleUrl: './sidebar-menu.css'
})
export class SidebarMenu {
  isOpen = false;
  @Input() louvorList: Louvor[] = [];

  openSidebar() {
    this.isOpen = true;
  }

  closeSidebar() {
    this.isOpen = false;
  }

  showListaRapidaModal = false;

  openListaRapidaModal(event: Event) {
    event.preventDefault();
    this.showListaRapidaModal = true;
  }

  closeListaRapidaModal() {
    this.showListaRapidaModal = false;
  }

  goHome() {
    window.location.href = '/';
  }
}
