import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { Louvor, Lista, CreateLouvorForm, ApiResponse } from '../../models/coletanea.models';

@Component({
  selector: 'app-gerenciar-louvores',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="gerenciar-container">
      <div class="header">
        <h2>Gerenciar Louvores</h2>
        <button class="btn-primary" (click)="mostrarFormulario = !mostrarFormulario">
          {{ mostrarFormulario ? 'Cancelar' : 'Novo Louvor' }}
        </button>
      </div>

      <!-- Seleção de Lista -->
      <div class="lista-selector" *ngIf="listas.length > 0">
        <label for="listaSelecionada">Filtrar por Lista:</label>
        <select 
          id="listaSelecionada" 
          [(ngModel)]="listaSelecionadaId" 
          (change)="filtrarPorLista()"
          class="select-lista">
          <option value="">Todas as listas</option>
          <option *ngFor="let lista of listas" [value]="lista.id">
            {{ lista.nome }}
          </option>
        </select>
      </div>

      <!-- Formulário de Novo Louvor -->
      <div class="form-container" *ngIf="mostrarFormulario">
        <h3>{{ editandoLouvor ? 'Editar Louvor' : 'Novo Louvor' }}</h3>
        <form class="louvor-form" (ngSubmit)="salvarLouvor()" #louvorForm="ngForm">
          <div class="form-group">
            <label for="listaId">Lista *</label>
            <select 
              id="listaId" 
              [(ngModel)]="formulario.listaId" 
              name="listaId" 
              required>
              <option value="">Selecione uma lista</option>
              <option *ngFor="let lista of listas" [value]="lista.id">
                {{ lista.nome }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="titulo">Título do Louvor *</label>
            <input 
              type="text" 
              id="titulo" 
              [(ngModel)]="formulario.titulo" 
              name="titulo" 
              required
              placeholder="Ex: Grande é o Senhor">
          </div>

          <div class="form-group">
            <label for="compositor">Compositor</label>
            <input 
              type="text" 
              id="compositor" 
              [(ngModel)]="formulario.compositor" 
              name="compositor"
              placeholder="Nome do compositor">
          </div>

          <div class="form-group">
            <label for="anoComposicao">Ano de Composição</label>
            <input 
              type="number" 
              id="anoComposicao" 
              [(ngModel)]="formulario.anoComposicao" 
              name="anoComposicao"
              min="1900"
              max="2030"
              placeholder="Ex: 1995">
          </div>

          <div class="form-group">
            <label for="letra">Letra</label>
            <textarea 
              id="letra" 
              [(ngModel)]="formulario.letra" 
              name="letra"
              rows="8"
              placeholder="Digite a letra do louvor aqui...">
            </textarea>
          </div>

          <div class="form-group">
            <label for="observacoes">Observações</label>
            <textarea 
              id="observacoes" 
              [(ngModel)]="formulario.observacoes" 
              name="observacoes"
              rows="3"
              placeholder="Observações, instruções especiais, etc.">
            </textarea>
          </div>

          <div class="form-actions">
            <button 
              type="submit" 
              class="btn-primary" 
              [disabled]="!louvorForm.valid || carregando">
              {{ carregando ? 'Salvando...' : (editandoLouvor ? 'Atualizar' : 'Criar Louvor') }}
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

      <!-- Lista de Louvores Existentes -->
      <div class="louvores-container">
        <div class="louvores-header">
          <h3>
            Louvores Existentes ({{ louvoresFiltrados.length }})
            <span *ngIf="listaSelecionadaId" class="filtro-ativo">
              - Filtrando por: {{ getNomeLista(listaSelecionadaId) }}
            </span>
          </h3>
          <div class="busca">
            <input 
              type="text" 
              [(ngModel)]="termoBusca" 
              (input)="filtrarLouvores()"
              placeholder="Buscar louvores...">
          </div>
        </div>

        <div class="louvores-grid" *ngIf="louvoresFiltrados.length > 0; else semLouvores">
          <div class="louvor-card" *ngFor="let louvor of louvoresFiltrados">
            <div class="louvor-header">
              <div class="louvor-info">
                <h4>{{ louvor.titulo }}</h4>
                <p class="lista-nome">📋 {{ getNomeLista(louvor.listaId || '') }}</p>
                <p class="compositor" *ngIf="louvor.compositor">🎵 {{ louvor.compositor }}</p>
                <p class="ano" *ngIf="louvor.anoComposicao">📅 {{ louvor.anoComposicao }}</p>
              </div>
              <div class="louvor-actions">
                <button class="btn-icon" (click)="editarLouvor(louvor)" title="Editar">
                  ✏️
                </button>
                <button class="btn-icon" (click)="visualizarLouvor(louvor)" title="Ver Detalhes">
                  👁️
                </button>
                <button class="btn-icon danger" (click)="excluirLouvor(louvor)" title="Excluir">
                  🗑️
                </button>
              </div>
            </div>
            
            <div class="louvor-content">
              <div class="letra-preview" *ngIf="louvor.letra">
                <p>{{ getPreviewLetra(louvor.letra) }}</p>
                <button class="btn-link" (click)="toggleLetraCompleta(louvor.id)">
                  {{ mostrandoLetraCompleta[louvor.id] ? 'Mostrar menos' : 'Ver letra completa' }}
                </button>
                <div class="letra-completa" *ngIf="mostrandoLetraCompleta[louvor.id]">
                  <pre>{{ louvor.letra }}</pre>
                </div>
              </div>

              <p *ngIf="louvor.observacoes" class="observacoes">
                <strong>Obs:</strong> {{ louvor.observacoes }}
              </p>
            </div>

            <div class="louvor-footer">
              <small class="timestamp">
                Criado em {{ formatarDataCompleta(louvor.createdAt) }}
                <span *ngIf="louvor.updatedAt !== louvor.createdAt">
                  • Atualizado em {{ formatarDataCompleta(louvor.updatedAt) }}
                </span>
              </small>
            </div>
          </div>
        </div>

        <ng-template #semLouvores>
          <div class="sem-louvores">
            <p>
              {{ termoBusca ? 'Nenhum louvor encontrado com esse termo.' : 
                 listaSelecionadaId ? 'Nenhum louvor cadastrado nesta lista.' : 
                 'Nenhum louvor criado ainda.' }}
            </p>
            <button class="btn-primary" (click)="mostrarFormulario = true" *ngIf="!termoBusca && listas.length > 0">
              Criar Primeiro Louvor
            </button>
            <p *ngIf="listas.length === 0" class="aviso">
              ⚠️ É necessário criar pelo menos uma lista antes de cadastrar louvores.
            </p>
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

    .lista-selector {
      background: white;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
      display: flex;
      align-items: center;
      gap: 15px;
    }

    .lista-selector label {
      font-weight: bold;
      color: #2c3e50;
      white-space: nowrap;
    }

    .select-lista {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
      min-width: 200px;
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

    .louvor-form {
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
    .form-group textarea,
    .form-group select {
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

    .louvores-container {
      background: white;
      border-radius: 8px;
      padding: 25px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
    }

    .louvores-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .louvores-header h3 {
      margin: 0;
      color: #2c3e50;
    }

    .filtro-ativo {
      color: #3498db;
      font-weight: normal;
      font-size: 0.9em;
    }

    .busca input {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      width: 250px;
    }

    .louvores-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
      gap: 20px;
    }

    .louvor-card {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 8px;
      padding: 20px;
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .louvor-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .louvor-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }

    .louvor-info h4 {
      margin: 0 0 8px 0;
      color: #2c3e50;
      font-size: 1.2em;
    }

    .louvor-info .lista-nome,
    .louvor-info .compositor,
    .louvor-info .ano {
      margin: 0 0 5px 0;
      color: #666;
      font-size: 0.9em;
    }

    .louvor-actions {
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

    .louvor-content {
      margin-bottom: 15px;
    }

    .letra-preview {
      margin-bottom: 15px;
    }

    .letra-preview p {
      margin: 0 0 10px 0;
      color: #555;
      line-height: 1.4;
      font-style: italic;
    }

    .btn-link {
      background: none;
      border: none;
      color: #3498db;
      cursor: pointer;
      font-size: 0.9em;
      text-decoration: underline;
    }

    .btn-link:hover {
      color: #2980b9;
    }

    .letra-completa {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 4px;
      padding: 15px;
      margin-top: 10px;
    }

    .letra-completa pre {
      margin: 0;
      font-family: inherit;
      white-space: pre-wrap;
      color: #2c3e50;
      line-height: 1.5;
    }

    .observacoes {
      margin: 0;
      color: #666;
      font-size: 0.9em;
      font-style: italic;
    }

    .louvor-footer {
      border-top: 1px solid #e9ecef;
      padding-top: 10px;
    }

    .timestamp {
      color: #888;
      font-size: 0.8em;
    }

    .sem-louvores {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .sem-louvores p {
      margin-bottom: 20px;
      font-size: 1.1em;
    }

    .aviso {
      background: #fff3cd;
      color: #856404;
      padding: 15px;
      border-radius: 4px;
      border: 1px solid #ffeaa7;
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
      
      .lista-selector {
        flex-direction: column;
        align-items: stretch;
        gap: 10px;
      }
      
      .select-lista {
        min-width: auto;
      }
      
      .louvores-header {
        flex-direction: column;
        gap: 15px;
        align-items: stretch;
      }
      
      .busca input {
        width: 100%;
      }
      
      .louvores-grid {
        grid-template-columns: 1fr;
      }
      
      .form-actions {
        flex-direction: column;
      }
    }
  `]
})
export class GerenciarLouvorComponent implements OnInit {
  louvores: Louvor[] = [];
  louvoresFiltrados: Louvor[] = [];
  listas: Lista[] = [];
  listaSelecionadaId: string = '';
  mostrarFormulario: boolean = false;
  editandoLouvor: Louvor | null = null;
  carregando: boolean = false;
  termoBusca: string = '';
  mensagem: string = '';
  tipoMensagem: 'success' | 'error' = 'success';
  mostrandoLetraCompleta: { [key: string]: boolean } = {};

  formulario: CreateLouvorForm = {
    titulo: '',
    compositor: '',
    anoComposicao: 0,
    letra: '',
    observacoes: '',
    listaId: ''
  };

  constructor(private amplifyService: AmplifyService) {}

  async ngOnInit(): Promise<void> {
    await Promise.all([
      this.carregarListas(),
      this.carregarLouvores()
    ]);
  }

  async carregarListas(): Promise<void> {
    try {
      const response = await this.amplifyService.listarListas();
      if (response.success && response.data) {
        this.listas = response.data.sort((a, b) => a.nome.localeCompare(b.nome));
      } else {
        this.mostrarMensagem('Erro ao carregar listas: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar listas:', error);
      this.mostrarMensagem('Erro ao carregar listas.', 'error');
    }
  }

  async carregarLouvores(): Promise<void> {
    try {
      const response = await this.amplifyService.listarLouvores();
      if (response.success && response.data) {
        this.louvores = response.data.sort((a, b) => a.titulo.localeCompare(b.titulo));
        this.filtrarLouvores();
      } else {
        this.mostrarMensagem('Erro ao carregar louvores: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar louvores:', error);
      this.mostrarMensagem('Erro ao carregar louvores.', 'error');
    }
  }

  filtrarPorLista(): void {
    this.filtrarLouvores();
  }

  filtrarLouvores(): void {
    let louvoresFiltrados = [...this.louvores];

    // Filtrar por lista se selecionada
    if (this.listaSelecionadaId) {
      louvoresFiltrados = louvoresFiltrados.filter(
        louvor => louvor.listaId === this.listaSelecionadaId
      );
    }

    // Filtrar por termo de busca
    if (this.termoBusca) {
      const termo = this.termoBusca.toLowerCase();
      louvoresFiltrados = louvoresFiltrados.filter(louvor =>
        louvor.titulo.toLowerCase().includes(termo) ||
        (louvor.compositor && louvor.compositor.toLowerCase().includes(termo)) ||
        (louvor.letra && louvor.letra.toLowerCase().includes(termo)) ||
        (louvor.observacoes && louvor.observacoes.toLowerCase().includes(termo))
      );
    }

    this.louvoresFiltrados = louvoresFiltrados;
  }

  async salvarLouvor(): Promise<void> {
    this.carregando = true;

    try {
      let response: ApiResponse<Louvor>;

      if (this.editandoLouvor) {
        // Atualizar louvor existente
        response = await this.amplifyService.atualizarLouvor(this.editandoLouvor.id, this.formulario);
      } else {
        // Criar novo louvor
        response = await this.amplifyService.criarLouvor(this.formulario);
      }

      if (response.success) {
        this.mostrarMensagem(
          this.editandoLouvor ? 'Louvor atualizado com sucesso!' : 'Louvor criado com sucesso!',
          'success'
        );
        this.cancelarEdicao();
        await this.carregarLouvores();
      } else {
        this.mostrarMensagem('Erro ao salvar louvor: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao salvar louvor:', error);
      this.mostrarMensagem('Erro ao salvar louvor.', 'error');
    } finally {
      this.carregando = false;
    }
  }

  editarLouvor(louvor: Louvor): void {
    this.editandoLouvor = louvor;
    this.formulario = {
      listaId: louvor.listaId || '',
      titulo: louvor.titulo,
      compositor: louvor.compositor || '',
      anoComposicao: louvor.anoComposicao || 0,
      letra: louvor.letra || '',
      observacoes: louvor.observacoes || ''
    };
    this.mostrarFormulario = true;
  }

  async excluirLouvor(louvor: Louvor): Promise<void> {
    if (!confirm(`Tem certeza que deseja excluir o louvor "${louvor.titulo}"?\n\nEsta ação não pode ser desfeita.`)) {
      return;
    }

    try {
      const response = await this.amplifyService.deletarLouvor(louvor.id);
      if (response.success) {
        this.mostrarMensagem('Louvor excluído com sucesso!', 'success');
        await this.carregarLouvores();
      } else {
        this.mostrarMensagem('Erro ao excluir louvor: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao excluir louvor:', error);
      this.mostrarMensagem('Erro ao excluir louvor.', 'error');
    }
  }

  visualizarLouvor(louvor: Louvor): void {
    const info = [
      `Título: ${louvor.titulo}`,
      `Lista: ${this.getNomeLista(louvor.listaId || '')}`,
      louvor.compositor ? `Compositor: ${louvor.compositor}` : '',
      louvor.anoComposicao ? `Ano de Composição: ${louvor.anoComposicao}` : '',
      louvor.letra ? `\nLetra:\n${louvor.letra}` : '',
      louvor.observacoes ? `\nObservações: ${louvor.observacoes}` : '',
      `\nCriado em: ${this.formatarDataCompleta(louvor.createdAt)}`,
      louvor.updatedAt !== louvor.createdAt ? `Atualizado em: ${this.formatarDataCompleta(louvor.updatedAt)}` : ''
    ].filter(item => item).join('\n');

    alert(info);
  }

  cancelarEdicao(): void {
    this.mostrarFormulario = false;
    this.editandoLouvor = null;
    this.formulario = {
      titulo: '',
      compositor: '',
      anoComposicao: 0,
      letra: '',
      observacoes: '',
      listaId: ''
    };
  }

  getNomeLista(listaId: string): string {
    const lista = this.listas.find(l => l.id === listaId);
    return lista ? lista.nome : 'Lista não encontrada';
  }

  getPreviewLetra(letra: string): string {
    if (!letra) return '';
    const linhas = letra.split('\n');
    const preview = linhas.slice(0, 2).join('\n');
    return linhas.length > 2 ? preview + '...' : preview;
  }

  toggleLetraCompleta(louvorId: string): void {
    this.mostrandoLetraCompleta[louvorId] = !this.mostrandoLetraCompleta[louvorId];
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
