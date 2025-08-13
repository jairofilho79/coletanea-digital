// ========== ENUMS ==========
export enum TipoMaterial {
  PDF = 'pdf',
  AUDIO = 'audio'
}

export enum TipoPartitura {
  CORO = 'coro',
  CIFRA = 'cifra',
  LETRA = 'letra',
  EXPERIENCIA = 'experiencia',
  GRADE = 'grade',
  CORO_E_PIANO = 'coro_e_piano',
  FLAUTA = 'flauta',
  OBOE = 'oboe',
  VIOLINO_I = 'violino_I',
  VIOLINO_II = 'violino_II',
  VIOLA = 'viola',
  VIOLONCELO = 'violoncelo',
  TROMBONE = 'trombone',
  TROMPETE = 'trompete',
  SAXOFONE_ALTO = 'saxofone_alto',
  SAXOFONE_TENOR = 'saxofone_tenor',
  SAXOFONE_SOPRANO = 'saxofone_soprano',
  FAGOTE = 'fagote',
  PERCUSSAO = 'percussao',
  OUTROS = 'outros'
}

export enum TipoAcao {
  ADICIONADO = 'adicionado',
  REMOVIDO = 'removido',
  ALTERADO = 'alterado'
}

export enum TipoEntidade {
  MATERIAL = 'Material',
  ARRANJO = 'Arranjo',
  LOUVOR = 'Louvor',
  LISTA = 'Lista'
}

// ========== INTERFACES PRINCIPAIS ==========

export interface Material {
  id: string;
  titulo: string;
  usuarioUpload?: string; // ID do usuário que fez o upload
  tipoPartitura: TipoPartitura;
  arquivoKey: string; // S3 key
  descricao?: string;
  observacoes?: string;
  arranjoId: string;
  createdAt: string;
  updatedAt: string;
}

export interface Arranjo {
  id: string;
  nome: string;
  autor?: string; // Compositor/autor do arranjo
  tom?: string;
  bpm?: number;
  descricao?: string;
  observacoes?: string;
  louvorId: string;
  createdAt: string;
  updatedAt: string;
}

export interface Louvor {
  id: string;
  titulo: string;
  letra?: string;
  autor?: string; // Compositor/autor do louvor
  anoComposicao?: number;
  observacoes?: string;
  listaId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Lista {
  id: string;
  nome: string;
  descricao?: string;
  data?: string;
  observacoes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface HistoricoModificacao {
  id: string;
  tipoEntidade: TipoEntidade;
  entidadeId: string;
  tipoAcao: TipoAcao;
  detalhes?: string;
  createdAt: string;
  updatedAt: string;
}

// ========== TYPES PARA FORMULÁRIOS ==========

export interface CreateMaterialForm {
  titulo: string;
  usuarioUpload?: string; // ID do usuário que fez o upload
  tipoPartitura: TipoPartitura;
  arquivoKey: string;
  descricao?: string;
  observacoes?: string;
  arranjoId: string;
}

export interface CreateArranjoForm {
  nome: string;
  autor?: string; // Compositor/autor do arranjo
  tom?: string;
  bpm?: number;
  descricao?: string;
  observacoes?: string;
  louvorId: string;
}

export interface CreateLouvorForm {
  titulo: string;
  letra?: string;
  autor?: string; // Compositor/autor do louvor
  anoComposicao?: number;
  observacoes?: string;
  listaId?: string;
}

export interface CreateListaForm {
  nome: string;
  descricao?: string;
  data?: string;
  observacoes?: string;
}

// ========== INTERFACES DE RESPOSTA DA API ==========

export interface UploadResponse {
  success: boolean;
  materialId?: string;
  error?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// ========== UTILITÁRIOS ==========

export const TipoPartituraLabels: Record<TipoPartitura, string> = {
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

export const TipoAcaoLabels: Record<TipoAcao, string> = {
  [TipoAcao.ADICIONADO]: 'Adicionado',
  [TipoAcao.REMOVIDO]: 'Removido',
  [TipoAcao.ALTERADO]: 'Alterado'
};

export const TipoEntidadeLabels: Record<TipoEntidade, string> = {
  [TipoEntidade.MATERIAL]: 'Material',
  [TipoEntidade.ARRANJO]: 'Arranjo',
  [TipoEntidade.LOUVOR]: 'Louvor',
  [TipoEntidade.LISTA]: 'Lista'
};
