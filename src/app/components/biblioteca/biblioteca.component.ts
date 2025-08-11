import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService, MaterialEstudo } from '../../services/amplify.service';

@Component({
  selector: 'app-biblioteca',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="biblioteca-container">
      <h2>Biblioteca de Materiais</h2>

      <!-- Filtros -->
      <div class="filtros">
        <div class="filtro-grupo">
          <label for="filtroCategoria">Categoria:</label>
          <select id="filtroCategoria" [(ngModel)]="filtroCategoria" (change)="aplicarFiltros()">
            <option value="">Todas as categorias</option>
            <option value="louvor">Louvor</option>
            <option value="estudo-biblico">Estudo Bíblico</option>
            <option value="hinario">Hinário</option>
            <option value="coral">Coral</option>
            <option value="instrumental">Instrumental</option>
          </select>
        </div>

        <div class="filtro-grupo">
          <label for="filtroTipo">Tipo:</label>
          <select id="filtroTipo" [(ngModel)]="filtroTipo" (change)="aplicarFiltros()">
            <option value="">Todos os tipos</option>
            <option value="pdf">PDF</option>
            <option value="audio">Áudio</option>
          </select>
        </div>

        <div class="filtro-grupo">
          <label for="busca">Buscar:</label>
          <input type="text" id="busca" [(ngModel)]="termoBusca" 
                 (input)="aplicarFiltros()" placeholder="Título, descrição ou tags...">
        </div>
      </div>

      <!-- Lista de materiais -->
      <div class="materiais-grid">
        <div *ngFor="let material of materiaisFiltrados" class="material-card">
          <div class="material-header">
            <h3>{{ material.titulo }}</h3>
            <span class="tipo-badge" [ngClass]="material.tipo">
              {{ material.tipo === 'pdf' ? 'PDF' : 'ÁUDIO' }}
            </span>
          </div>

          <div class="material-info">
            <p *ngIf="material.descricao" class="descricao">{{ material.descricao }}</p>
            
            <div class="metadata">
              <span class="categoria">{{ material.categoria }}</span>
              <span class="data">{{ material.dataUpload | date:'dd/MM/yyyy' }}</span>
              <span class="tamanho">{{ formatarTamanho(material.tamanho) }}</span>
            </div>

            <div *ngIf="material.tags.length > 0" class="tags">
              <span *ngFor="let tag of material.tags" class="tag">{{ tag }}</span>
            </div>
          </div>

          <div class="material-actions">
            <button (click)="visualizarMaterial(material)" class="btn-visualizar">
              <span *ngIf="material.tipo === 'pdf'">📄 Ver PDF</span>
              <span *ngIf="material.tipo === 'audio'">🎵 Tocar</span>
            </button>
            <button (click)="baixarMaterial(material)" class="btn-baixar">
              ⬇️ Baixar
            </button>
            <button (click)="excluirMaterial(material)" class="btn-excluir">
              🗑️ Excluir
            </button>
          </div>
        </div>
      </div>

      <div *ngIf="materiaisFiltrados.length === 0" class="sem-materiais">
        <p>Nenhum material encontrado.</p>
      </div>
    </div>
  `,
  styles: [`
    .biblioteca-container {
      padding: 20px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .filtros {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
      margin-bottom: 30px;
      padding: 20px;
      background-color: #f8f9fa;
      border-radius: 8px;
    }

    .filtro-grupo label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
    }

    .filtro-grupo input,
    .filtro-grupo select {
      width: 100%;
      padding: 8px;
      border: 1px solid #ccc;
      border-radius: 4px;
    }

    .materiais-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 20px;
    }

    .material-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 15px;
      background-color: white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .material-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
    }

    .material-header h3 {
      margin: 0;
      flex: 1;
      margin-right: 10px;
    }

    .tipo-badge {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: bold;
    }

    .tipo-badge.pdf {
      background-color: #dc3545;
      color: white;
    }

    .tipo-badge.audio {
      background-color: #28a745;
      color: white;
    }

    .descricao {
      color: #666;
      font-size: 14px;
      margin-bottom: 10px;
    }

    .metadata {
      display: flex;
      gap: 15px;
      font-size: 12px;
      color: #888;
      margin-bottom: 10px;
    }

    .tags {
      display: flex;
      flex-wrap: wrap;
      gap: 5px;
      margin-bottom: 15px;
    }

    .tag {
      background-color: #e9ecef;
      padding: 2px 6px;
      border-radius: 10px;
      font-size: 12px;
    }

    .material-actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .material-actions button {
      padding: 6px 12px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
    }

    .btn-visualizar {
      background-color: #007bff;
      color: white;
    }

    .btn-baixar {
      background-color: #6c757d;
      color: white;
    }

    .btn-excluir {
      background-color: #dc3545;
      color: white;
    }

    .material-actions button:hover {
      opacity: 0.8;
    }

    .sem-materiais {
      text-align: center;
      padding: 40px;
      color: #666;
    }
  `]
})
export class BibliotecaComponent implements OnInit {
  materiais: MaterialEstudo[] = [];
  materiaisFiltrados: MaterialEstudo[] = [];
  
  filtroCategoria: string = '';
  filtroTipo: string = '';
  termoBusca: string = '';

  constructor(private amplifyService: AmplifyService) {}

  async ngOnInit(): Promise<void> {
    await this.carregarMateriais();
  }

  async carregarMateriais(): Promise<void> {
    try {
      this.materiais = await this.amplifyService.listarMateriais();
      this.aplicarFiltros();
    } catch (error) {
      console.error('Erro ao carregar materiais:', error);
    }
  }

  aplicarFiltros(): void {
    this.materiaisFiltrados = this.materiais.filter(material => {
      // Filtro por categoria
      if (this.filtroCategoria && material.categoria !== this.filtroCategoria) {
        return false;
      }

      // Filtro por tipo
      if (this.filtroTipo && material.tipo !== this.filtroTipo) {
        return false;
      }

      // Busca textual
      if (this.termoBusca) {
        const termo = this.termoBusca.toLowerCase();
        const encontrado = 
          material.titulo.toLowerCase().includes(termo) ||
          (material.descricao && material.descricao.toLowerCase().includes(termo)) ||
          material.tags.some(tag => tag.toLowerCase().includes(termo));
        
        if (!encontrado) {
          return false;
        }
      }

      return true;
    });
  }

  async visualizarMaterial(material: MaterialEstudo): Promise<void> {
    try {
      const arquivo = await this.amplifyService.downloadFile(material.arquivo);
      
      if (material.tipo === 'pdf') {
        // Abrir PDF em nova aba
        const blob = new Blob([arquivo.body], { type: 'application/pdf' });
        const url = window.URL.createObjectURL(blob);
        window.open(url, '_blank');
      } else if (material.tipo === 'audio') {
        // Reproduzir áudio
        const blob = new Blob([arquivo.body], { type: 'audio/mpeg' });
        const url = window.URL.createObjectURL(blob);
        const audio = new Audio(url);
        audio.play();
      }
    } catch (error) {
      console.error('Erro ao visualizar material:', error);
      alert('Erro ao carregar o arquivo.');
    }
  }

  async baixarMaterial(material: MaterialEstudo): Promise<void> {
    try {
      const arquivo = await this.amplifyService.downloadFile(material.arquivo);
      
      const blob = new Blob([arquivo.body]);
      const url = window.URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `${material.titulo}.${material.arquivo.split('.').pop()}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Erro ao baixar material:', error);
      alert('Erro ao baixar o arquivo.');
    }
  }

  async excluirMaterial(material: MaterialEstudo): Promise<void> {
    if (confirm(`Tem certeza que deseja excluir o material "${material.titulo}"?`)) {
      try {
        // Excluir arquivo do S3
        await this.amplifyService.deleteFile(material.arquivo);
        
        // Excluir metadados do DynamoDB
        await this.amplifyService.excluirMaterial(material.id);
        
        // Atualizar lista local
        this.materiais = this.materiais.filter(m => m.id !== material.id);
        this.aplicarFiltros();
        
        alert('Material excluído com sucesso.');
      } catch (error) {
        console.error('Erro ao excluir material:', error);
        alert('Erro ao excluir material.');
      }
    }
  }

  formatarTamanho(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
  }
}
