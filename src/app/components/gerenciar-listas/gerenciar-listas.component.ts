import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { Lista, CreateListaForm, ApiResponse } from '../../models/coletanea.models';

@Component({
  selector: 'app-gerenciar-listas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="gerenciar-container">
      <div class="header">
        <h2>Gerenciar Listas</h2>
        <button class="btn-primary" (click)="mostrarFormulario = !mostrarFormulario">
          {{ mostrarFormulario ? 'Cancelar' : 'Nova Lista' }}
        </button>
      </div>

      <!-- Formulário de Nova Lista -->
      <div class="form-container" *ngIf="mostrarFormulario">
        <h3>{{ editandoLista ? 'Editar Lista' : 'Nova Lista' }}</h3>
        <form class="lista-form" (ngSubmit)="salvarLista()" #listaForm="ngForm">
          <div class="form-group">
            <label for="nome">Nome da Lista *</label>
            <input 
              type="text" 
              id="nome" 
              [(ngModel)]="formulario.nome" 
              name="nome" 
              required
              placeholder="Ex: Lista de Louvor - Janeiro 2024">
          </div>

          <div class="form-group">
            <label for="data">Data</label>
            <input 
              type="date" 
              id="data" 
              [(ngModel)]="formulario.data" 
              name="data"
              placeholder="Data da apresentação/uso">
          </div>

          <div class="form-group">
            <label for="descricao">Descrição</label>
            <textarea 
              id="descricao" 
              [(ngModel)]="formulario.descricao" 
              name="descricao"
              rows="3"
              placeholder="Descrição opcional da lista">
            </textarea>
          </div>

          <div class="form-group">
            <label for="observacoes">Observações</label>
            <textarea 
              id="observacoes" 
              [(ngModel)]="formulario.observacoes" 
              name="observacoes"
              rows="2"
              placeholder="Observações adicionais">
            </textarea>
          </div>

          <div class="form-actions">
            <button 
              type="submit" 
              class="btn-primary" 
              [disabled]="!listaForm.valid || carregando">
              {{ carregando ? 'Salvando...' : (editandoLista ? 'Atualizar' : 'Criar Lista') }}
            </button>
            <button 
              type="button" 
              class="btn-secondary" 
              (click)="cancelarEdicao()"
              [disabled]="carregando">
              Cancelar
            </button>
          </div>
        </form>
      </div>

      <!-- Lista de Listas Existentes -->
      <div class="listas-container">
        <div class="listas-header">
          <h3>Listas Existentes ({{ listas.length }})</h3>
          <div class="busca">
            <input 
              type="text" 
              [(ngModel)]="termoBusca" 
              (input)="filtrarListas()"
              placeholder="Buscar listas...">
          </div>
        </div>

        <div class="listas-grid" *ngIf="listasFiltradas.length > 0; else semListas">
          <div class="lista-card" *ngFor="let lista of listasFiltradas">
            <div class="lista-header">
              <div class="lista-info">
                <h4>{{ lista.nome }}</h4>
                <p class="data" *ngIf="lista.data">📅 {{ formatarData(lista.data) }}</p>
              </div>
              <div class="lista-actions">
                <button class="btn-icon" (click)="editarLista(lista)" title="Editar">
                  ✏️
                </button>
                <button class="btn-icon" (click)="visualizarLista(lista)" title="Ver Detalhes">
                  👁️
                </button>
                <button class="btn-icon danger" (click)="excluirLista(lista)" title="Excluir">
                  🗑️
                </button>
              </div>
            </div>
            
            <div class="lista-content">
              <p *ngIf="lista.descricao" class="descricao">{{ lista.descricao }}</p>
              <p *ngIf="lista.observacoes" class="observacoes"><strong>Obs:</strong> {{ lista.observacoes }}</p>
            </div>

            <div class="lista-footer">
              <small class="timestamp">
                Criada em {{ formatarDataCompleta(lista.createdAt) }}
                <span *ngIf="lista.updatedAt !== lista.createdAt">
                  • Atualizada em {{ formatarDataCompleta(lista.updatedAt) }}
                </span>
              </small>
            </div>
          </div>
        </div>

        <ng-template #semListas>
          <div class="sem-listas">
            <p>{{ termoBusca ? 'Nenhuma lista encontrada com esse termo.' : 'Nenhuma lista criada ainda.' }}</p>
            <button class="btn-primary" (click)="mostrarFormulario = true" *ngIf="!termoBusca">
              Criar Primeira Lista
            </button>
          </div>
        </ng-template>
      </div>

      <!-- Mensagens -->
      <div *ngIf="mensagem" class="message" [class.error]="tipoMensagem === 'error'" [class.success]="tipoMensagem === 'success'">
        {{ mensagem }}
      </div>
    </div>
  `,
  styles: [`
    .gerenciar-container {
      padding: 20px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
      padding-bottom: 15px;
      border-bottom: 2px solid #e1e5e9;
    }

    .header h2 {
      margin: 0;
      color: #2c3e50;
    }

    .form-container {
      background: white;
      border-radius: 8px;
      padding: 25px;
      margin-bottom: 30px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
    }

    .form-container h3 {
      margin: 0 0 20px 0;
      color: #2c3e50;
    }

    .lista-form {
      display: grid;
      gap: 20px;
    }

    .form-group {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }

    .form-group label {
      font-weight: bold;
      color: #333;
    }

    .form-group input,
    .form-group textarea {
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }

    .form-group textarea {
      resize: vertical;
      font-family: inherit;
    }

    .form-actions {
      display: flex;
      gap: 15px;
      margin-top: 10px;
    }

    .listas-container {
      background: white;
      border-radius: 8px;
      padding: 25px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
    }

    .listas-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .listas-header h3 {
      margin: 0;
      color: #2c3e50;
    }

    .busca input {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      width: 250px;
    }

    .listas-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
      gap: 20px;
    }

    .lista-card {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 8px;
      padding: 20px;
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .lista-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .lista-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }

    .lista-info h4 {
      margin: 0 0 5px 0;
      color: #2c3e50;
      font-size: 1.1em;
    }

    .lista-info .data {
      margin: 0;
      color: #666;
      font-size: 0.9em;
    }

    .lista-actions {
      display: flex;
      gap: 8px;
    }

    .btn-icon {
      background: none;
      border: none;
      font-size: 16px;
      cursor: pointer;
      padding: 5px;
      border-radius: 4px;
      transition: background-color 0.2s;
    }

    .btn-icon:hover {
      background: rgba(0, 0, 0, 0.1);
    }

    .btn-icon.danger:hover {
      background: rgba(231, 76, 60, 0.1);
    }

    .lista-content {
      margin-bottom: 15px;
    }

    .lista-content .descricao {
      margin: 0 0 8px 0;
      color: #555;
      line-height: 1.4;
    }

    .lista-content .observacoes {
      margin: 0;
      color: #666;
      font-size: 0.9em;
      font-style: italic;
    }

    .lista-footer {
      border-top: 1px solid #e9ecef;
      padding-top: 10px;
    }

    .timestamp {
      color: #888;
      font-size: 0.8em;
    }

    .sem-listas {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .sem-listas p {
      margin-bottom: 20px;
      font-size: 1.1em;
    }

    .btn-primary, .btn-secondary {
      padding: 10px 20px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: bold;
      transition: background-color 0.2s;
    }

    .btn-primary {
      background: #3498db;
      color: white;
    }

    .btn-primary:hover:not(:disabled) {
      background: #2980b9;
    }

    .btn-primary:disabled {
      background: #bdc3c7;
      cursor: not-allowed;
    }

    .btn-secondary {
      background: #95a5a6;
      color: white;
    }

    .btn-secondary:hover:not(:disabled) {
      background: #7f8c8d;
    }

    .message {
      margin-top: 20px;
      padding: 15px;
      border-radius: 4px;
      font-weight: bold;
    }

    .message.success {
      background: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
    }

    .message.error {
      background: #f8d7da;
      color: #721c24;
      border: 1px solid #f5c6cb;
    }

    @media (max-width: 768px) {
      .header {
        flex-direction: column;
        gap: 15px;
        align-items: stretch;
      }
      
      .listas-header {
        flex-direction: column;
        gap: 15px;
        align-items: stretch;
      }
      
      .busca input {
        width: 100%;
      }
      
      .listas-grid {
        grid-template-columns: 1fr;
      }
      
      .form-actions {
        flex-direction: column;
      }
    }
  `]
})
export class GerenciarListasComponent implements OnInit {
  listas: Lista[] = [];
  listasFiltradas: Lista[] = [];
  mostrarFormulario: boolean = false;
  editandoLista: Lista | null = null;
  carregando: boolean = false;
  termoBusca: string = '';
  mensagem: string = '';
  tipoMensagem: 'success' | 'error' = 'success';

  formulario: CreateListaForm = {
    nome: '',
    descricao: '',
    data: '',
    observacoes: ''
  };

  constructor(private amplifyService: AmplifyService) {}

  async ngOnInit(): Promise<void> {
    await this.carregarListas();
  }

  async carregarListas(): Promise<void> {
    try {
      const response = await this.amplifyService.listarListas();
      if (response.success && response.data) {
        this.listas = response.data.sort((a, b) => 
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
        this.filtrarListas();
      } else {
        this.mostrarMensagem('Erro ao carregar listas: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar listas:', error);
      this.mostrarMensagem('Erro ao carregar listas.', 'error');
    }
  }

  filtrarListas(): void {
    if (!this.termoBusca) {
      this.listasFiltradas = [...this.listas];
    } else {
      const termo = this.termoBusca.toLowerCase();
      this.listasFiltradas = this.listas.filter(lista =>
        lista.nome.toLowerCase().includes(termo) ||
        (lista.descricao && lista.descricao.toLowerCase().includes(termo)) ||
        (lista.observacoes && lista.observacoes.toLowerCase().includes(termo))
      );
    }
  }

  async salvarLista(): Promise<void> {
    this.carregando = true;

    try {
      let response: ApiResponse<Lista>;

      if (this.editandoLista) {
        // Atualizar lista existente
        response = await this.amplifyService.atualizarLista(this.editandoLista.id, this.formulario);
      } else {
        // Criar nova lista
        response = await this.amplifyService.criarLista(this.formulario);
      }

      if (response.success) {
        this.mostrarMensagem(
          this.editandoLista ? 'Lista atualizada com sucesso!' : 'Lista criada com sucesso!',
          'success'
        );
        this.cancelarEdicao();
        await this.carregarListas();
      } else {
        this.mostrarMensagem('Erro ao salvar lista: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao salvar lista:', error);
      this.mostrarMensagem('Erro ao salvar lista.', 'error');
    } finally {
      this.carregando = false;
    }
  }

  editarLista(lista: Lista): void {
    this.editandoLista = lista;
    this.formulario = {
      nome: lista.nome,
      descricao: lista.descricao || '',
      data: lista.data || '',
      observacoes: lista.observacoes || ''
    };
    this.mostrarFormulario = true;
  }

  async excluirLista(lista: Lista): Promise<void> {
    if (!confirm(`Tem certeza que deseja excluir a lista "${lista.nome}"?\n\nEsta ação não pode ser desfeita.`)) {
      return;
    }

    try {
      const response = await this.amplifyService.deletarLista(lista.id);
      if (response.success) {
        this.mostrarMensagem('Lista excluída com sucesso!', 'success');
        await this.carregarListas();
      } else {
        this.mostrarMensagem('Erro ao excluir lista: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao excluir lista:', error);
      this.mostrarMensagem('Erro ao excluir lista.', 'error');
    }
  }

  visualizarLista(lista: Lista): void {
    // TODO: Implementar navegação para visualização detalhada da lista
    // Por enquanto, mostra as informações em um alert
    const info = [
      `Nome: ${lista.nome}`,
      lista.data ? `Data: ${this.formatarData(lista.data)}` : '',
      lista.descricao ? `Descrição: ${lista.descricao}` : '',
      lista.observacoes ? `Observações: ${lista.observacoes}` : '',
      `Criada em: ${this.formatarDataCompleta(lista.createdAt)}`,
      lista.updatedAt !== lista.createdAt ? `Atualizada em: ${this.formatarDataCompleta(lista.updatedAt)}` : ''
    ].filter(item => item).join('\n');

    alert(info);
  }

  cancelarEdicao(): void {
    this.mostrarFormulario = false;
    this.editandoLista = null;
    this.formulario = {
      nome: '',
      descricao: '',
      data: '',
      observacoes: ''
    };
  }

  formatarData(data: string): string {
    try {
      return new Date(data).toLocaleDateString('pt-BR');
    } catch {
      return data;
    }
  }

  formatarDataCompleta(data: string): string {
    try {
      return new Date(data).toLocaleString('pt-BR');
    } catch {
      return data;
    }
  }

  private mostrarMensagem(mensagem: string, tipo: 'success' | 'error'): void {
    this.mensagem = mensagem;
    this.tipoMensagem = tipo;

    // Limpar mensagem após 5 segundos
    setTimeout(() => {
      this.mensagem = '';
    }, 5000);
  }
}
