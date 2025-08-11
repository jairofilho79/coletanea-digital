import { Injectable } from '@angular/core';
import { Storage } from 'aws-amplify/storage';

export interface MaterialEstudo {
  id: string;
  titulo: string;
  descricao?: string;
  tipo: 'pdf' | 'audio';
  arquivo: string; // S3 key
  categoria: string;
  tags: string[];
  dataUpload: Date;
  tamanho: number;
  duracao?: number; // para áudios (em segundos)
  paginas?: number; // para PDFs
}

export interface Lista {
  id: string;
  nome: string;
  descricao?: string;
  materiais: string[]; // IDs dos materiais
  dataCriacao: Date;
  dataModificacao: Date;
}

@Injectable({
  providedIn: 'root'
})
export class AmplifyService {

  constructor() { }

  // Métodos para S3 Storage
  async uploadFile(file: File, key: string): Promise<any> {
    try {
      return await Storage.uploadData({
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
      console.error('Erro ao fazer upload:', error);
      throw error;
    }
  }

  async downloadFile(key: string): Promise<any> {
    try {
      return await Storage.downloadData({ key }).result;
    } catch (error) {
      console.error('Erro ao baixar arquivo:', error);
      throw error;
    }
  }

  async listFiles(prefix?: string): Promise<any> {
    try {
      return await Storage.list({ prefix });
    } catch (error) {
      console.error('Erro ao listar arquivos:', error);
      throw error;
    }
  }

  async deleteFile(key: string): Promise<any> {
    try {
      return await Storage.remove({ key });
    } catch (error) {
      console.error('Erro ao deletar arquivo:', error);
      throw error;
    }
  }

  // Métodos para DynamoDB (serão implementados após configuração)
  async salvarMaterial(material: MaterialEstudo): Promise<MaterialEstudo> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Salvando material:', material);
    return material;
  }

  async obterMaterial(id: string): Promise<MaterialEstudo | null> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Obtendo material:', id);
    return null;
  }

  async listarMateriais(): Promise<MaterialEstudo[]> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Listando materiais');
    return [];
  }

  async excluirMaterial(id: string): Promise<void> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Excluindo material:', id);
  }

  async salvarLista(lista: Lista): Promise<Lista> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Salvando lista:', lista);
    return lista;
  }

  async obterLista(id: string): Promise<Lista | null> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Obtendo lista:', id);
    return null;
  }

  async listarListas(): Promise<Lista[]> {
    // TODO: Implementar após configuração do DynamoDB
    console.log('Listando listas');
    return [];
  }
}
