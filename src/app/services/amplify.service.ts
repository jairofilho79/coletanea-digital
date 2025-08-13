import { Injectable } from '@angular/core';
import { uploadData, downloadData, list, remove } from 'aws-amplify/storage';
import { generateClient } from 'aws-amplify/api';
import { 
  Material, 
  Arranjo, 
  Louvor, 
  Lista, 
  HistoricoModificacao,
  CreateMaterialForm,
  CreateArranjoForm,
  CreateLouvorForm,
  CreateListaForm,
  UploadResponse,
  ApiResponse,
  TipoAcao,
  TipoEntidade
} from '../models/coletanea.models';

@Injectable({
  providedIn: 'root'
})
export class AmplifyService {
  private client = generateClient();

  constructor() { }

  // ========== MÉTODOS S3 STORAGE ==========
  
  async uploadFile(file: File, key: string): Promise<any> {
    try {
      return await uploadData({
        key,
        data: file,
        options: {
          contentType: file.type,
          metadata: {
            originalName: file.name,
            uploadDate: new Date().toISOString()
          }
        }
      }).result;
    } catch (error) {
      console.error('Erro ao fazer upload do arquivo:', error);
      throw error;
    }
  }

  async downloadFile(key: string): Promise<any> {
    try {
      const result = await downloadData({ key }).result;
      return result;
    } catch (error) {
      console.error('Erro ao baixar arquivo:', error);
      throw error;
    }
  }

  async listFiles(path?: string): Promise<any[]> {
    try {
      const result = await list({
        path: path || ''
      });
      return result.items || [];
    } catch (error) {
      console.error('Erro ao listar arquivos:', error);
      throw error;
    }
  }

  async removeFile(key: string): Promise<void> {
    try {
      await remove({ key });
    } catch (error) {
      console.error('Erro ao remover arquivo:', error);
      throw error;
    }
  }

  // ========== MÉTODOS MOCK (IMPLEMENTAÇÃO FUTURA) ==========

  async criarMaterial(material: CreateMaterialForm): Promise<ApiResponse<Material>> {
    try {
      console.log('Mock: Criando material:', material);
      
      // Mock response
      const mockMaterial: Material = {
        id: 'mock-' + Date.now(),
        titulo: material.titulo,
        usuarioUpload: material.usuarioUpload,
        tipoPartitura: material.tipoPartitura,
        arquivoKey: material.arquivoKey,
        descricao: material.descricao,
        observacoes: material.observacoes,
        arranjoId: material.arranjoId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockMaterial,
        message: 'Material criado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao criar material:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao criar material'
      };
    }
  }

  async obterMaterial(id: string): Promise<ApiResponse<Material>> {
    try {
      console.log('Mock: Obtendo material:', id);
      
      // Mock: simular material não encontrado às vezes
      if (id === 'not-found') {
        return {
          success: false,
          message: 'Material não encontrado'
        };
      }
      
      const mockMaterial: Material = {
        id,
        titulo: 'Mock Material',
        usuarioUpload: 'user-123', // Mock user ID
        tipoPartitura: 'coro' as any,
        arquivoKey: 'mock-key.pdf',
        descricao: 'Mock descrição',
        observacoes: 'Mock observações',
        arranjoId: 'mock-arranjo-id',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockMaterial,
        message: 'Material obtido com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao obter material:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao obter material'
      };
    }
  }

  async listarMateriais(arranjoId?: string): Promise<ApiResponse<Material[]>> {
    try {
      console.log('Mock: Listando materiais para arranjo:', arranjoId);
      
      const mockMateriais: Material[] = [
        {
          id: 'material-1',
          titulo: 'Material 1',
          usuarioUpload: 'user-123',
          tipoPartitura: 'coro' as any,
          arquivoKey: 'material1.pdf',
          arranjoId: arranjoId || 'arranjo-1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'material-2',
          titulo: 'Material 2',
          usuarioUpload: 'user-456',
          tipoPartitura: 'cifra' as any,
          arquivoKey: 'material2.pdf',
          arranjoId: arranjoId || 'arranjo-1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ];
      
      return {
        success: true,
        data: mockMateriais,
        message: 'Materiais listados com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao listar materiais:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao listar materiais'
      };
    }
  }

  async atualizarMaterial(id: string, material: Partial<CreateMaterialForm>): Promise<ApiResponse<Material>> {
    try {
      console.log('Mock: Atualizando material:', id, material);
      
      const mockMaterial: Material = {
        id,
        titulo: material.titulo || 'Mock Material Updated',
        usuarioUpload: material.usuarioUpload,
        tipoPartitura: material.tipoPartitura || 'coro' as any,
        arquivoKey: material.arquivoKey || 'mock-key-updated.pdf',
        descricao: material.descricao,
        observacoes: material.observacoes,
        arranjoId: material.arranjoId || 'mock-arranjo',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockMaterial,
        message: 'Material atualizado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao atualizar material:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao atualizar material'
      };
    }
  }

  async deletarMaterial(id: string): Promise<ApiResponse<void>> {
    try {
      console.log('Mock: Deletando material:', id);
      
      return {
        success: true,
        message: 'Material deletado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao deletar material:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao deletar material'
      };
    }
  }

  // ========== MÉTODOS ARRANJO ==========

  async criarArranjo(arranjo: CreateArranjoForm): Promise<ApiResponse<Arranjo>> {
    try {
      console.log('Mock: Criando arranjo:', arranjo);
      
      const mockArranjo: Arranjo = {
        id: 'mock-arranjo-' + Date.now(),
        nome: arranjo.nome,
        autor: arranjo.autor,
        tom: arranjo.tom,
        bpm: arranjo.bpm,
        descricao: arranjo.descricao,
        observacoes: arranjo.observacoes,
        louvorId: arranjo.louvorId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockArranjo,
        message: 'Arranjo criado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao criar arranjo:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao criar arranjo'
      };
    }
  }

  async obterArranjo(id: string): Promise<ApiResponse<Arranjo>> {
    try {
      console.log('Mock: Obtendo arranjo:', id);
      
      const mockArranjo: Arranjo = {
        id,
        nome: 'Mock Arranjo',
        autor: 'Mock Autor do Arranjo',
        tom: 'C',
        bpm: 120,
        descricao: 'Mock descrição',
        louvorId: 'mock-louvor-id',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockArranjo,
        message: 'Arranjo obtido com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao obter arranjo:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao obter arranjo'
      };
    }
  }

  async listarArranjos(louvorId?: string): Promise<ApiResponse<Arranjo[]>> {
    try {
      console.log('Mock: Listando arranjos para louvor:', louvorId);
      
      const mockArranjos: Arranjo[] = [
        {
          id: 'arranjo-1',
          nome: 'Arranjo 1',
          autor: 'Autor Arranjo 1',
          tom: 'C',
          bpm: 120,
          louvorId: louvorId || 'louvor-1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'arranjo-2',
          nome: 'Arranjo 2',
          autor: 'Autor Arranjo 2',
          tom: 'D',
          bpm: 110,
          louvorId: louvorId || 'louvor-1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ];
      
      return {
        success: true,
        data: mockArranjos,
        message: 'Arranjos listados com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao listar arranjos:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao listar arranjos'
      };
    }
  }

  async atualizarArranjo(id: string, arranjo: Partial<CreateArranjoForm>): Promise<ApiResponse<Arranjo>> {
    try {
      console.log('Mock: Atualizando arranjo:', id, arranjo);
      
      const mockArranjo: Arranjo = {
        id,
        nome: arranjo.nome || 'Mock Arranjo Updated',
        autor: arranjo.autor || 'Mock Autor Updated',
        tom: arranjo.tom,
        bpm: arranjo.bpm,
        descricao: arranjo.descricao,
        observacoes: arranjo.observacoes,
        louvorId: arranjo.louvorId || 'mock-louvor',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockArranjo,
        message: 'Arranjo atualizado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao atualizar arranjo:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao atualizar arranjo'
      };
    }
  }

  async deletarArranjo(id: string): Promise<ApiResponse<void>> {
    try {
      console.log('Mock: Deletando arranjo:', id);
      
      return {
        success: true,
        message: 'Arranjo deletado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao deletar arranjo:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao deletar arranjo'
      };
    }
  }

  // ========== MÉTODOS LOUVOR ==========

  async criarLouvor(louvor: CreateLouvorForm): Promise<ApiResponse<Louvor>> {
    try {
      console.log('Mock: Criando louvor:', louvor);
      
      const mockLouvor: Louvor = {
        id: 'mock-louvor-' + Date.now(),
        titulo: louvor.titulo,
        letra: louvor.letra,
        autor: louvor.autor,
        anoComposicao: louvor.anoComposicao,
        observacoes: louvor.observacoes,
        listaId: louvor.listaId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLouvor,
        message: 'Louvor criado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao criar louvor:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao criar louvor'
      };
    }
  }

  async obterLouvor(id: string): Promise<ApiResponse<Louvor>> {
    try {
      console.log('Mock: Obtendo louvor:', id);
      
      const mockLouvor: Louvor = {
        id,
        titulo: 'Mock Louvor',
        letra: 'Mock letra do louvor...',
        autor: 'Mock Autor',
        anoComposicao: 2023,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLouvor,
        message: 'Louvor obtido com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao obter louvor:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao obter louvor'
      };
    }
  }

  async listarLouvores(listaId?: string): Promise<ApiResponse<Louvor[]>> {
    try {
      console.log('Mock: Listando louvores para lista:', listaId);
      
      const mockLouvores: Louvor[] = [
        {
          id: 'louvor-1',
          titulo: 'Louvor 1',
          letra: 'Letra do louvor 1...',
          autor: 'Autor 1',
          listaId: listaId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'louvor-2',
          titulo: 'Louvor 2',
          letra: 'Letra do louvor 2...',
          autor: 'Autor 2',
          listaId: listaId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ];
      
      return {
        success: true,
        data: mockLouvores,
        message: 'Louvores listados com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao listar louvores:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao listar louvores'
      };
    }
  }

  async atualizarLouvor(id: string, louvor: Partial<CreateLouvorForm>): Promise<ApiResponse<Louvor>> {
    try {
      console.log('Mock: Atualizando louvor:', id, louvor);
      
      const mockLouvor: Louvor = {
        id,
        titulo: louvor.titulo || 'Mock Louvor Updated',
        letra: louvor.letra,
        autor: louvor.autor,
        anoComposicao: louvor.anoComposicao,
        observacoes: louvor.observacoes,
        listaId: louvor.listaId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLouvor,
        message: 'Louvor atualizado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao atualizar louvor:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao atualizar louvor'
      };
    }
  }

  async deletarLouvor(id: string): Promise<ApiResponse<void>> {
    try {
      console.log('Mock: Deletando louvor:', id);
      
      return {
        success: true,
        message: 'Louvor deletado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao deletar louvor:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao deletar louvor'
      };
    }
  }

  // ========== MÉTODOS LISTA ==========

  async criarLista(lista: CreateListaForm): Promise<ApiResponse<Lista>> {
    try {
      console.log('Mock: Criando lista:', lista);
      
      const mockLista: Lista = {
        id: 'mock-lista-' + Date.now(),
        nome: lista.nome,
        descricao: lista.descricao,
        data: lista.data,
        observacoes: lista.observacoes,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLista,
        message: 'Lista criada com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao criar lista:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao criar lista'
      };
    }
  }

  async obterLista(id: string): Promise<ApiResponse<Lista>> {
    try {
      console.log('Mock: Obtendo lista:', id);
      
      const mockLista: Lista = {
        id,
        nome: 'Mock Lista',
        descricao: 'Mock descrição da lista',
        data: new Date().toISOString().split('T')[0],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLista,
        message: 'Lista obtida com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao obter lista:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao obter lista'
      };
    }
  }

  async listarListas(): Promise<ApiResponse<Lista[]>> {
    try {
      console.log('Mock: Listando listas');
      
      const mockListas: Lista[] = [
        {
          id: 'lista-1',
          nome: 'Lista 1',
          descricao: 'Descrição da lista 1',
          data: '2024-01-15',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'lista-2',
          nome: 'Lista 2',
          descricao: 'Descrição da lista 2',
          data: '2024-01-20',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ];
      
      return {
        success: true,
        data: mockListas,
        message: 'Listas listadas com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao listar listas:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao listar listas'
      };
    }
  }

  async atualizarLista(id: string, lista: Partial<CreateListaForm>): Promise<ApiResponse<Lista>> {
    try {
      console.log('Mock: Atualizando lista:', id, lista);
      
      const mockLista: Lista = {
        id,
        nome: lista.nome || 'Mock Lista Updated',
        descricao: lista.descricao,
        data: lista.data,
        observacoes: lista.observacoes,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockLista,
        message: 'Lista atualizada com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao atualizar lista:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao atualizar lista'
      };
    }
  }

  async deletarLista(id: string): Promise<ApiResponse<void>> {
    try {
      console.log('Mock: Deletando lista:', id);
      
      return {
        success: true,
        message: 'Lista deletada com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao deletar lista:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao deletar lista'
      };
    }
  }

  // ========== MÉTODOS HISTÓRICO ==========

  async criarHistorico(
    tipoEntidade: TipoEntidade,
    entidadeId: string,
    tipoAcao: TipoAcao,
    detalhes?: string
  ): Promise<ApiResponse<HistoricoModificacao>> {
    try {
      console.log('Mock: Criando histórico:', { tipoEntidade, entidadeId, tipoAcao, detalhes });
      
      const mockHistorico: HistoricoModificacao = {
        id: 'mock-historico-' + Date.now(),
        tipoEntidade,
        entidadeId,
        tipoAcao,
        detalhes: detalhes || '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      return {
        success: true,
        data: mockHistorico,
        message: 'Histórico criado com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao criar histórico:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao criar histórico'
      };
    }
  }

  async obterHistorico(entidadeId: string, tipoEntidade?: TipoEntidade): Promise<ApiResponse<HistoricoModificacao[]>> {
    try {
      console.log('Mock: Obtendo histórico para:', { entidadeId, tipoEntidade });
      
      const mockHistoricos: HistoricoModificacao[] = [
        {
          id: 'historico-1',
          tipoEntidade: tipoEntidade || TipoEntidade.MATERIAL,
          entidadeId,
          tipoAcao: TipoAcao.ADICIONADO,
          detalhes: 'Item adicionado ao sistema',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'historico-2',
          tipoEntidade: tipoEntidade || TipoEntidade.MATERIAL,
          entidadeId,
          tipoAcao: TipoAcao.ALTERADO,
          detalhes: 'Item foi modificado',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ];
      
      return {
        success: true,
        data: mockHistoricos,
        message: 'Histórico obtido com sucesso (mock)'
      };
    } catch (error) {
      console.error('Erro ao obter histórico:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao obter histórico'
      };
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  async buscarPorTitulo(termo: string, tipoEntidade?: 'Material' | 'Louvor'): Promise<ApiResponse<(Material | Louvor)[]>> {
    try {
      console.log('Mock: Buscando por título:', termo, tipoEntidade);
      
      const resultados: (Material | Louvor)[] = [];
      
      if (!tipoEntidade || tipoEntidade === 'Material') {
        resultados.push({
          id: 'material-search-1',
          titulo: `Material com "${termo}"`,
          usuarioUpload: 'Usuario Teste',
          tipoPartitura: 'coro' as any,
          arquivoKey: 'material-search.pdf',
          arranjoId: 'arranjo-search',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        } as Material);
      }
      
      if (!tipoEntidade || tipoEntidade === 'Louvor') {
        resultados.push({
          id: 'louvor-search-1',
          titulo: `Louvor com "${termo}"`,
          letra: 'Letra do louvor encontrado...',
          autor: 'Autor Teste',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        } as Louvor);
      }
      
      return {
        success: true,
        data: resultados,
        message: `Encontrados ${resultados.length} resultados para "${termo}" (mock)`
      };
    } catch (error) {
      console.error('Erro ao buscar por título:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao buscar por título'
      };
    }
  }

  async buscarPorAutor(autor: string): Promise<ApiResponse<(Material | Louvor)[]>> {
    try {
      console.log('Mock: Buscando por autor/usuário:', autor);
      
      const resultados: (Material | Louvor)[] = [
        {
          id: 'material-autor-1',
          titulo: 'Material do Usuário',
          usuarioUpload: autor,
          tipoPartitura: 'coro' as any,
          arquivoKey: 'autor-material.pdf',
          arranjoId: 'arranjo-autor',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        } as Material,
        {
          id: 'louvor-autor-1',
          titulo: 'Louvor do Autor',
          letra: 'Letra do louvor...',
          autor,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        } as Louvor
      ];
      
      return {
        success: true,
        data: resultados,
        message: `Encontrados ${resultados.length} resultados para autor "${autor}" (mock)`
      };
    } catch (error) {
      console.error('Erro ao buscar por autor:', error);
      return {
        success: false,
        error: error as string,
        message: 'Erro ao buscar por autor'
      };
    }
  }
}
