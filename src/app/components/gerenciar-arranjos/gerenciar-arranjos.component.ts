import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { Arranjo, Louvor, Lista, CreateArranjoForm, ApiResponse } from '../../models/coletanea.models';

@Component({
  selector: 'app-gerenciar-arranjos',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="gerenciar-container">
      <div class="header">
        <h2>Gerenciar Arranjos</h2>
        <button class="btn-primary" (click)="mostrarFormulario = !mostrarFormulario">
          {{ mostrarFormulario ? 'Cancelar' : 'Novo Arranjo' }}
        </button>
      </div>

      <!-- Filtros -->
      <div class="filtros-container" *ngIf="listas.length > 0">
        <div class="filtro-group">
          <label for="listaSelecionada">Filtrar por Lista:</label>
          <select 
            id="listaSelecionada" 
            [(ngModel)]="listaSelecionadaId" 
            (change)="filtrarPorLista()"
            class="select-filtro">
            <option value="">Todas as listas</option>
            <option *ngFor="let lista of listas" [value]="lista.id">
              {{ lista.nome }}
            </option>
          </select>
        </div>

        <div class="filtro-group" *ngIf="louvoresDisponiveis.length > 0">
          <label for="louvorSelecionado">Filtrar por Louvor:</label>
          <select 
            id="louvorSelecionado" 
            [(ngModel)]="louvorSelecionadoId" 
            (change)="filtrarPorLouvor()"
            class="select-filtro">
            <option value="">Todos os louvores</option>
            <option *ngFor="let louvor of louvoresDisponiveis" [value]="louvor.id">
              {{ louvor.titulo }}
            </option>
          </select>
        </div>
      </div>

      <!-- Formulário de Novo Arranjo -->
      <div class="form-container" *ngIf="mostrarFormulario">
        <h3>{{ editandoArranjo ? 'Editar Arranjo' : 'Novo Arranjo' }}</h3>
        <form class="arranjo-form" (ngSubmit)="salvarArranjo()" #arranjoForm="ngForm">
          <div class="form-group">
            <label for="listaId">Lista *</label>
            <select 
              id="listaId" 
              [(ngModel)]="listaFormulario" 
              (change)="carregarLouvoresDaLista()"
              name="listaId" 
              required>
              <option value="">Selecione uma lista</option>
              <option *ngFor="let lista of listas" [value]="lista.id">
                {{ lista.nome }}
              </option>
            </select>
          </div>

          <div class="form-group" *ngIf="louvoresFormulario.length > 0">
            <label for="louvorId">Louvor *</label>
            <select 
              id="louvorId" 
              [(ngModel)]="formulario.louvorId" 
              name="louvorId" 
              required>
              <option value="">Selecione um louvor</option>
              <option *ngFor="let louvor of louvoresFormulario" [value]="louvor.id">
                {{ louvor.titulo }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="nome">Nome do Arranjo *</label>
            <input 
              type="text" 
              id="nome" 
              [(ngModel)]="formulario.nome" 
              name="nome" 
              required
              placeholder="Ex: Arranjo para Piano e Voz">
          </div>

          <div class="form-group">
            <label for="tom">Tom</label>
            <input 
              type="text" 
              id="tom" 
              [(ngModel)]="formulario.tom" 
              name="tom"
              placeholder="Ex: D, Em, F#m">
          </div>

          <div class="form-group">
            <label for="bpm">BPM (Batidas por Minuto)</label>
            <input 
              type="number" 
              id="bpm" 
              [(ngModel)]="formulario.bpm" 
              name="bpm"
              min="60"
              max="200"
              placeholder="Ex: 120">
          </div>

          <div class="form-group">
            <label for="descricao">Descrição</label>
            <textarea 
              id="descricao" 
              [(ngModel)]="formulario.descricao" 
              name="descricao"
              rows="3"
              placeholder="Descrição do arranjo, instrumentos utilizados, etc.">
            </textarea>
          </div>

          <div class="form-group">
            <label for="observacoes">Observações</label>
            <textarea 
              id="observacoes" 
              [(ngModel)]="formulario.observacoes" 
              name="observacoes"
              rows="3"
              placeholder="Observações especiais, instruções de execução, etc.">
            </textarea>
          </div>

          <div class="form-actions">
            <button 
              type="submit" 
              class="btn-primary" 
              [disabled]="!arranjoForm.valid || carregando">
              {{ carregando ? 'Salvando...' : (editandoArranjo ? 'Atualizar' : 'Criar Arranjo') }}
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

      <!-- Lista de Arranjos Existentes -->
      <div class="arranjos-container">
        <div class="arranjos-header">
          <h3>
            Arranjos Existentes ({{ arranjosFiltrados.length }})
            <span *ngIf="listaSelecionadaId || louvorSelecionadoId" class="filtro-ativo">
              - Filtrando
              <span *ngIf="listaSelecionadaId"> por Lista: {{ getNomeLista(listaSelecionadaId) }}</span>
              <span *ngIf="louvorSelecionadoId"> por Louvor: {{ getNomeLouvor(louvorSelecionadoId) }}</span>
            </span>
          </h3>
          <div class="busca">
            <input 
              type="text" 
              [(ngModel)]="termoBusca" 
              (input)="filtrarArranjos()"
              placeholder="Buscar arranjos...">
          </div>
        </div>

        <div class="arranjos-grid" *ngIf="arranjosFiltrados.length > 0; else semArranjos">
          <div class="arranjo-card" *ngFor="let arranjo of arranjosFiltrados">
            <div class="arranjo-header">
              <div class="arranjo-info">
                <h4>{{ arranjo.nome }}</h4>
                <p class="louvor-info">🎵 {{ getNomeLouvor(arranjo.louvorId) }}</p>
                <p class="lista-info">📋 {{ getNomeListaDoLouvor(arranjo.louvorId) }}</p>
              </div>
              <div class="arranjo-actions">
                <button class="btn-icon" (click)="editarArranjo(arranjo)" title="Editar">
                  ✏️
                </button>
                <button class="btn-icon" (click)="visualizarArranjo(arranjo)" title="Ver Detalhes">
                  👁️
                </button>
                <button class="btn-icon danger" (click)="excluirArranjo(arranjo)" title="Excluir">
                  🗑️
                </button>
              </div>
            </div>
            
            <div class="arranjo-content">
              <div class="musical-info" *ngIf="arranjo.tom || arranjo.bpm">
                <span *ngIf="arranjo.tom" class="tom">🎼 Tom: {{ arranjo.tom }}</span>
                <span *ngIf="arranjo.bpm" class="bpm">⏱️ {{ arranjo.bpm }} BPM</span>
              </div>
              
              <p *ngIf="arranjo.descricao" class="descricao">{{ arranjo.descricao }}</p>
              
              <p *ngIf="arranjo.observacoes" class="observacoes">
                <strong>Obs:</strong> {{ arranjo.observacoes }}
              </p>
            </div>

            <div class="arranjo-footer">
              <small class="timestamp">
                Criado em {{ formatarDataCompleta(arranjo.createdAt) }}
                <span *ngIf="arranjo.updatedAt !== arranjo.createdAt">
                  • Atualizado em {{ formatarDataCompleta(arranjo.updatedAt) }}
                </span>
              </small>
            </div>
          </div>
        </div>

        <ng-template #semArranjos>
          <div class="sem-arranjos">
            <p>
              {{ termoBusca ? 'Nenhum arranjo encontrado com esse termo.' : 
                 listaSelecionadaId || louvorSelecionadoId ? 'Nenhum arranjo cadastrado nos filtros selecionados.' : 
                 'Nenhum arranjo criado ainda.' }}
            </p>
            <button class="btn-primary" (click)="mostrarFormulario = true" *ngIf="!termoBusca && louvores.length > 0">
              Criar Primeiro Arranjo
            </button>
            <p *ngIf="louvores.length === 0" class="aviso">
              ⚠️ É necessário criar pelo menos um louvor antes de cadastrar arranjos.
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
      max-width: 1400px;
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

    .filtros-container {
      background: white;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
      display: flex;
      gap: 30px;
      flex-wrap: wrap;
    }

    .filtro-group {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .filtro-group label {
      font-weight: bold;
      color: #2c3e50;
      white-space: nowrap;
    }

    .select-filtro {
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

    .arranjo-form {
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

    .arranjos-container {
      background: white;
      border-radius: 8px;
      padding: 25px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      border: 1px solid #e1e5e9;
    }

    .arranjos-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }

    .arranjos-header h3 {
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

    .arranjos-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
      gap: 20px;
    }

    .arranjo-card {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 8px;
      padding: 20px;
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .arranjo-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .arranjo-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }

    .arranjo-info h4 {
      margin: 0 0 8px 0;
      color: #2c3e50;
      font-size: 1.1em;
    }

    .arranjo-info .louvor-info,
    .arranjo-info .lista-info {
      margin: 0 0 5px 0;
      color: #666;
      font-size: 0.9em;
    }

    .arranjo-actions {
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

    .arranjo-content {
      margin-bottom: 15px;
    }

    .musical-info {
      display: flex;
      gap: 15px;
      margin-bottom: 15px;
      flex-wrap: wrap;
    }

    .musical-info .tom,
    .musical-info .bpm {
      background: #e8f4fd;
      color: #2980b9;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.9em;
      font-weight: bold;
    }

    .descricao {
      margin: 0 0 12px 0;
      color: #555;
      line-height: 1.4;
    }

    .observacoes {
      margin: 0;
      color: #666;
      font-size: 0.9em;
      font-style: italic;
    }

    .arranjo-footer {
      border-top: 1px solid #e9ecef;
      padding-top: 10px;
    }

    .timestamp {
      color: #888;
      font-size: 0.8em;
    }

    .sem-arranjos {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .sem-arranjos p {
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
      
      .filtros-container {
        flex-direction: column;
        gap: 15px;
      }
      
      .filtro-group {
        flex-direction: column;
        align-items: stretch;
        gap: 5px;
      }
      
      .select-filtro {
        min-width: auto;
      }
      
      .arranjos-header {
        flex-direction: column;
        gap: 15px;
        align-items: stretch;
      }
      
      .busca input {
        width: 100%;
      }
      
      .arranjos-grid {
        grid-template-columns: 1fr;
      }
      
      .form-actions {
        flex-direction: column;
      }
      
      .musical-info {
        justify-content: center;
      }
    }
  `]
})
export class GerenciarArranjoComponent implements OnInit {
  arranjos: Arranjo[] = [];
  arranjosFiltrados: Arranjo[] = [];
  louvores: Louvor[] = [];
  louvoresDisponiveis: Louvor[] = [];
  louvoresFormulario: Louvor[] = [];
  listas: Lista[] = [];
  listaSelecionadaId: string = '';
  louvorSelecionadoId: string = '';
  listaFormulario: string = '';
  mostrarFormulario: boolean = false;
  editandoArranjo: Arranjo | null = null;
  carregando: boolean = false;
  termoBusca: string = '';
  mensagem: string = '';
  tipoMensagem: 'success' | 'error' = 'success';

  formulario: CreateArranjoForm = {
    louvorId: '',
    nome: '',
    tom: '',
    bpm: 0,
    descricao: '',
    observacoes: ''
  };

  constructor(private amplifyService: AmplifyService) {}

  async ngOnInit(): Promise<void> {
    await Promise.all([
      this.carregarListas(),
      this.carregarLouvores(),
      this.carregarArranjos()
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
        this.louvoresDisponiveis = [...this.louvores];
      } else {
        this.mostrarMensagem('Erro ao carregar louvores: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar louvores:', error);
      this.mostrarMensagem('Erro ao carregar louvores.', 'error');
    }
  }

  async carregarArranjos(): Promise<void> {
    try {
      const response = await this.amplifyService.listarArranjos();
      if (response.success && response.data) {
        this.arranjos = response.data.sort((a, b) => a.nome.localeCompare(b.nome));
        this.filtrarArranjos();
      } else {
        this.mostrarMensagem('Erro ao carregar arranjos: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar arranjos:', error);
      this.mostrarMensagem('Erro ao carregar arranjos.', 'error');
    }
  }

  filtrarPorLista(): void {
    if (this.listaSelecionadaId) {
      this.louvoresDisponiveis = this.louvores.filter(
        louvor => louvor.listaId === this.listaSelecionadaId
      );
      // Limpar seleção de louvor se não estiver na lista filtrada
      if (this.louvorSelecionadoId && !this.louvoresDisponiveis.find(l => l.id === this.louvorSelecionadoId)) {
        this.louvorSelecionadoId = '';
      }
    } else {
      this.louvoresDisponiveis = [...this.louvores];
    }
    this.filtrarArranjos();
  }

  filtrarPorLouvor(): void {
    this.filtrarArranjos();
  }

  carregarLouvoresDaLista(): void {
    if (this.listaFormulario) {
      this.louvoresFormulario = this.louvores.filter(
        louvor => louvor.listaId === this.listaFormulario
      );
    } else {
      this.louvoresFormulario = [];
    }
    // Limpar seleção de louvor no formulário
    this.formulario.louvorId = '';
  }

  filtrarArranjos(): void {
    let arranjosFiltrados = [...this.arranjos];

    // Filtrar por lista se selecionada
    if (this.listaSelecionadaId) {
      const louvoresDaLista = this.louvores
        .filter(louvor => louvor.listaId === this.listaSelecionadaId)
        .map(louvor => louvor.id);
      
      arranjosFiltrados = arranjosFiltrados.filter(
        arranjo => louvoresDaLista.includes(arranjo.louvorId)
      );
    }

    // Filtrar por louvor se selecionado
    if (this.louvorSelecionadoId) {
      arranjosFiltrados = arranjosFiltrados.filter(
        arranjo => arranjo.louvorId === this.louvorSelecionadoId
      );
    }

    // Filtrar por termo de busca
    if (this.termoBusca) {
      const termo = this.termoBusca.toLowerCase();
      arranjosFiltrados = arranjosFiltrados.filter(arranjo =>
        arranjo.nome.toLowerCase().includes(termo) ||
        (arranjo.descricao && arranjo.descricao.toLowerCase().includes(termo)) ||
        (arranjo.observacoes && arranjo.observacoes.toLowerCase().includes(termo)) ||
        this.getNomeLouvor(arranjo.louvorId).toLowerCase().includes(termo)
      );
    }

    this.arranjosFiltrados = arranjosFiltrados;
  }

  async salvarArranjo(): Promise<void> {
    this.carregando = true;

    try {
      let response: ApiResponse<Arranjo>;

      if (this.editandoArranjo) {
        // Atualizar arranjo existente
        response = await this.amplifyService.atualizarArranjo(this.editandoArranjo.id, this.formulario);
      } else {
        // Criar novo arranjo
        response = await this.amplifyService.criarArranjo(this.formulario);
      }

      if (response.success) {
        this.mostrarMensagem(
          this.editandoArranjo ? 'Arranjo atualizado com sucesso!' : 'Arranjo criado com sucesso!',
          'success'
        );
        this.cancelarEdicao();
        await this.carregarArranjos();
      } else {
        this.mostrarMensagem('Erro ao salvar arranjo: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao salvar arranjo:', error);
      this.mostrarMensagem('Erro ao salvar arranjo.', 'error');
    } finally {
      this.carregando = false;
    }
  }

  editarArranjo(arranjo: Arranjo): void {
    this.editandoArranjo = arranjo;
    
    // Encontrar a lista do louvor
    const louvor = this.louvores.find(l => l.id === arranjo.louvorId);
    this.listaFormulario = louvor?.listaId || '';
    this.carregarLouvoresDaLista();

    this.formulario = {
      louvorId: arranjo.louvorId,
      nome: arranjo.nome,
      tom: arranjo.tom || '',
      bpm: arranjo.bpm || 0,
      descricao: arranjo.descricao || '',
      observacoes: arranjo.observacoes || ''
    };
    this.mostrarFormulario = true;
  }

  async excluirArranjo(arranjo: Arranjo): Promise<void> {
    if (!confirm(`Tem certeza que deseja excluir o arranjo "${arranjo.nome}"?\n\nEsta ação não pode ser desfeita.`)) {
      return;
    }

    try {
      const response = await this.amplifyService.deletarArranjo(arranjo.id);
      if (response.success) {
        this.mostrarMensagem('Arranjo excluído com sucesso!', 'success');
        await this.carregarArranjos();
      } else {
        this.mostrarMensagem('Erro ao excluir arranjo: ' + response.error, 'error');
      }
    } catch (error) {
      console.error('Erro ao excluir arranjo:', error);
      this.mostrarMensagem('Erro ao excluir arranjo.', 'error');
    }
  }

  visualizarArranjo(arranjo: Arranjo): void {
    const info = [
      `Nome: ${arranjo.nome}`,
      `Louvor: ${this.getNomeLouvor(arranjo.louvorId)}`,
      `Lista: ${this.getNomeListaDoLouvor(arranjo.louvorId)}`,
      arranjo.tom ? `Tom: ${arranjo.tom}` : '',
      arranjo.bpm ? `BPM: ${arranjo.bpm}` : '',
      arranjo.descricao ? `Descrição: ${arranjo.descricao}` : '',
      arranjo.observacoes ? `Observações: ${arranjo.observacoes}` : '',
      `\nCriado em: ${this.formatarDataCompleta(arranjo.createdAt)}`,
      arranjo.updatedAt !== arranjo.createdAt ? `Atualizado em: ${this.formatarDataCompleta(arranjo.updatedAt)}` : ''
    ].filter(item => item).join('\n');

    alert(info);
  }

  cancelarEdicao(): void {
    this.mostrarFormulario = false;
    this.editandoArranjo = null;
    this.listaFormulario = '';
    this.louvoresFormulario = [];
    this.formulario = {
      louvorId: '',
      nome: '',
      tom: '',
      bpm: 0,
      descricao: '',
      observacoes: ''
    };
  }

  getNomeLista(listaId: string): string {
    const lista = this.listas.find(l => l.id === listaId);
    return lista ? lista.nome : 'Lista não encontrada';
  }

  getNomeLouvor(louvorId: string): string {
    const louvor = this.louvores.find(l => l.id === louvorId);
    return louvor ? louvor.titulo : 'Louvor não encontrado';
  }

  getNomeListaDoLouvor(louvorId: string): string {
    const louvor = this.louvores.find(l => l.id === louvorId);
    if (!louvor || !louvor.listaId) return 'Lista não encontrada';
    return this.getNomeLista(louvor.listaId);
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
