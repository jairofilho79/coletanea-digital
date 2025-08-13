import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { Material, TipoPartitura, ApiResponse } from '../../models/coletanea.models';

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
          <label for="filtroCategoria">Tipo de Partitura:</label>
          <select id="filtroCategoria" [(ngModel)]="filtroTipoPartitura" (change)="aplicarFiltros()">
            <option value="">Todos os tipos</option>
            <option value="coro">Coro</option>
            <option value="cifra">Cifra</option>
            <option value="letra">Letra</option>
            <option value="grade">Grade</option>
            <option value="flauta">Flauta</option>
            <option value="violino_I">Violino I</option>
            <option value="violino_II">Violino II</option>
            <option value="outros">Outros</option>
          </select>
        </div>

        <div class="filtro-grupo">
          <label for="termoBusca">Buscar:</label>
          <input 
            type="text" 
            id="termoBusca" 
            [(ngModel)]="termoBusca" 
            (input)="aplicarFiltros()" 
            placeholder="Buscar por título ou usuário...">
        </div>
      </div>

      <!-- Lista de Materiais -->
      <div class="materiais-grid" *ngIf="materiaisFiltrados.length > 0; else semMateriais">
        <div class="material-card" *ngFor="let material of materiaisFiltrados">
          <div class="material-header">
            <h3>{{ material.titulo }}</h3>
            <span class="tipo-badge">{{ getTipoPartituraLabel(material.tipoPartitura) }}</span>
          </div>
          
          <div class="material-info">
            <p *ngIf="material.usuarioUpload"><strong>Usuário:</strong> {{ material.usuarioUpload }}</p>
            <p *ngIf="material.descricao"><strong>Descrição:</strong> {{ material.descricao }}</p>
            <p *ngIf="material.observacoes"><strong>Observações:</strong> {{ material.observacoes }}</p>
          </div>

          <div class="material-actions">
            <button class="btn-primary" (click)="visualizarMaterial(material)">
              Visualizar
            </button>
            <button class="btn-secondary" (click)="baixarMaterial(material)">
              Baixar
            </button>
            <button class="btn-danger" (click)="excluirMaterial(material)">
              Excluir
            </button>
          </div>
        </div>
      </div>

      <ng-template #semMateriais>
        <div class="sem-materiais">
          <p>Nenhum material encontrado.</p>
        </div>
      </ng-template>
    </div>
  `,
  styles: [`
    .biblioteca-container {
      padding: 20px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .filtros {
      display: flex;
      gap: 20px;
      margin-bottom: 30px;
      flex-wrap: wrap;
    }

    .filtro-grupo {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }

    .filtro-grupo label {
      font-weight: bold;
      color: #333;
    }

    .filtro-grupo select,
    .filtro-grupo input {
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      min-width: 200px;
    }

    .materiais-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 20px;
    }

    .material-card {
      background: white;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      transition: transform 0.2s;
    }

    .material-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
    }

    .material-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }

    .material-header h3 {
      margin: 0;
      color: #2c3e50;
      font-size: 1.2em;
    }

    .tipo-badge {
      background: #3498db;
      color: white;
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.8em;
      white-space: nowrap;
    }

    .material-info {
      margin-bottom: 15px;
    }

    .material-info p {
      margin: 8px 0;
      color: #666;
      font-size: 0.9em;
    }

    .material-actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .btn-primary, .btn-secondary, .btn-danger {
      padding: 8px 16px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.9em;
      transition: background-color 0.2s;
    }

    .btn-primary {
      background: #3498db;
      color: white;
    }

    .btn-primary:hover {
      background: #2980b9;
    }

    .btn-secondary {
      background: #95a5a6;
      color: white;
    }

    .btn-secondary:hover {
      background: #7f8c8d;
    }

    .btn-danger {
      background: #e74c3c;
      color: white;
    }

    .btn-danger:hover {
      background: #c0392b;
    }

    .sem-materiais {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .sem-materiais p {
      font-size: 1.1em;
      margin: 0;
    }

    @media (max-width: 768px) {
      .filtros {
        flex-direction: column;
      }
      
      .materiais-grid {
        grid-template-columns: 1fr;
      }
      
      .material-actions {
        justify-content: center;
      }
    }
  `]
})
export class BibliotecaComponent implements OnInit {
  materiais: Material[] = [];
  materiaisFiltrados: Material[] = [];
  
  filtroTipoPartitura: string = '';
  termoBusca: string = '';

  constructor(private amplifyService: AmplifyService) {}

  async ngOnInit(): Promise<void> {
    await this.carregarMateriais();
  }

  async carregarMateriais(): Promise<void> {
    try {
      const response = await this.amplifyService.listarMateriais();
      if (response.success && response.data) {
        this.materiais = response.data;
        this.aplicarFiltros();
      } else {
        console.error('Erro ao carregar materiais:', response.error);
      }
    } catch (error) {
      console.error('Erro ao carregar materiais:', error);
    }
  }

  aplicarFiltros(): void {
    this.materiaisFiltrados = this.materiais.filter(material => {
      // Filtro por tipo de partitura
      const passaTipoPartitura = !this.filtroTipoPartitura || 
        material.tipoPartitura === this.filtroTipoPartitura;

      // Filtro por termo de busca (título ou usuário)
      const passaBusca = !this.termoBusca || 
        material.titulo.toLowerCase().includes(this.termoBusca.toLowerCase()) ||
        (material.usuarioUpload && material.usuarioUpload.toLowerCase().includes(this.termoBusca.toLowerCase()));

      return passaTipoPartitura && passaBusca;
    });
  }

  getTipoPartituraLabel(tipo: TipoPartitura): string {
    const labels: Record<TipoPartitura, string> = {
      [TipoPartitura.CORO]: 'Coro',
      [TipoPartitura.CIFRA]: 'Cifra',
      [TipoPartitura.LETRA]: 'Letra',
      [TipoPartitura.EXPERIENCIA]: 'Experiência',
      [TipoPartitura.GRADE]: 'Grade',
      [TipoPartitura.CORO_E_PIANO]: 'Coro e Piano',
      [TipoPartitura.FLAUTA]: 'Flauta',
      [TipoPartitura.OBOE]: 'Oboé',
      [TipoPartitura.VIOLINO_I]: 'Violino I',
      [TipoPartitura.VIOLINO_II]: 'Violino II',
      [TipoPartitura.VIOLA]: 'Viola',
      [TipoPartitura.VIOLONCELO]: 'Violoncelo',
      [TipoPartitura.TROMBONE]: 'Trombone',
      [TipoPartitura.TROMPETE]: 'Trompete',
      [TipoPartitura.SAXOFONE_ALTO]: 'Saxofone Alto',
      [TipoPartitura.SAXOFONE_TENOR]: 'Saxofone Tenor',
      [TipoPartitura.SAXOFONE_SOPRANO]: 'Saxofone Soprano',
      [TipoPartitura.FAGOTE]: 'Fagote',
      [TipoPartitura.PERCUSSAO]: 'Percussão',
      [TipoPartitura.OUTROS]: 'Outros'
    };
    return labels[tipo] || tipo;
  }

  async visualizarMaterial(material: Material): Promise<void> {
    try {
      const blob = await this.amplifyService.downloadFile(material.arquivoKey);
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
      
      // Limpar a URL após um tempo para liberar memória
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (error) {
      console.error('Erro ao visualizar material:', error);
      alert('Erro ao visualizar o material. Tente novamente.');
    }
  }

  async baixarMaterial(material: Material): Promise<void> {
    try {
      const blob = await this.amplifyService.downloadFile(material.arquivoKey);
      const url = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `${material.titulo}.pdf`; // Assumindo que são PDFs por padrão
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Erro ao baixar material:', error);
      alert('Erro ao baixar o material. Tente novamente.');
    }
  }

  async excluirMaterial(material: Material): Promise<void> {
    if (!confirm(`Tem certeza que deseja excluir o material "${material.titulo}"?`)) {
      return;
    }

    try {
      // Remover arquivo do S3
      await this.amplifyService.removeFile(material.arquivoKey);
      
      // Remover registro do DynamoDB
      const response = await this.amplifyService.deletarMaterial(material.id);
      
      if (response.success) {
        // Remover da lista local
        this.materiais = this.materiais.filter(m => m.id !== material.id);
        this.aplicarFiltros();
        alert('Material excluído com sucesso!');
      } else {
        alert('Erro ao excluir material: ' + response.error);
      }
    } catch (error) {
      console.error('Erro ao excluir material:', error);
      alert('Erro ao excluir o material. Tente novamente.');
    }
  }
}
