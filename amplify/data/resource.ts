import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

/*== COLETÂNEA DIGITAL - SCHEMA HIERÁRQUICO ===============================
Hierarquia: Lista → Louvor+Arranjo → Arranjo → Material
Relacionamentos 1:N em toda a cadeia
=========================================================================*/

const schema = a.schema({
  // ========== MATERIAL ==========
  Material: a
    .model({
      id: a.id().required(),
      titulo: a.string().required(),
      descricao: a.string(),
      tipo: a.enum(['pdf', 'audio']),
      arquivo: a.string().required(), // S3 key
      partitura: a.enum([
        'coro', 'cifra', 'letra', 'experiencia', 'grade', 'coro_e_piano', 
        'flauta', 'oboe', 'violino_I', 'violino_II', 'viola', 'violoncelo', 
        'trombone', 'trompete', 'saxofone_alto', 'saxofone_tenor', 
        'saxofone_soprano', 'fagote', 'percussao', 'outros'
      ]),
      tags: a.string().array(), // Array de strings para tags
      dataUpload: a.datetime().required(),
      tamanho: a.integer().required(), // Tamanho em bytes
      duracao: a.integer(), // Duração em segundos (para áudio)
      paginas: a.integer(), // Número de páginas (para PDF)
      autorUpload: a.string(), // ID do usuário que fez upload
      
      // Relacionamento com Arranjo
      arranjoId: a.id().required(),
      arranjo: a.belongsTo('Arranjo', 'arranjoId'),
    })
    .authorization((allow) => [
      allow.guest().to(['read']),
      allow.guest().to(['create', 'update', 'delete']),
    ]),

  // ========== ARRANJO ==========
  Arranjo: a
    .model({
      id: a.id().required(),
      nome: a.string().required(),
      autor: a.string(),
      dataCriacao: a.datetime().required(),
      dataAtualizacao: a.datetime().required(),
      historicoModificacao: a.json(), // Array de objetos: {usuario, data, acao, entidade, item}
      
      // Relacionamento com Louvor
      louvorId: a.id().required(),
      louvor: a.belongsTo('Louvor', 'louvorId'),
      
      // Relacionamento com Materiais
      materiais: a.hasMany('Material', 'arranjoId'),
    })
    .authorization((allow) => [
      allow.guest().to(['read', 'create', 'update', 'delete']),
    ]),

  // ========== LOUVOR ==========
  Louvor: a
    .model({
      id: a.id().required(),
      nome: a.string().required(),
      dataCriacao: a.datetime().required(),
      dataModificacao: a.datetime().required(),
      historicoModificacao: a.json(), // Array de objetos: {usuario, data, acao, entidade, item}
      
      // Relacionamento com Arranjos
      arranjos: a.hasMany('Arranjo', 'louvorId'),
    })
    .authorization((allow) => [
      allow.guest().to(['read', 'create', 'update', 'delete']),
    ]),

  // ========== LISTA ==========
  Lista: a
    .model({
      id: a.id().required(),
      nome: a.string().required(),
      descricao: a.string(),
      // Cada item da lista é um objeto: {louvorId, arranjoId, louvorNome, arranjoNome}
      itens: a.json().required(), // Array de objetos de Louvor+Arranjo específicos
      dataCriacao: a.datetime().required(),
      dataModificacao: a.datetime().required(),
      proprietario: a.string(), // ID do usuário proprietário
      publica: a.boolean().required().default(false),
    })
    .authorization((allow) => [
      allow.guest().to(['read', 'create', 'update', 'delete']),
    ]),

  // ========== HISTÓRICO DE MODIFICAÇÃO ==========
  HistoricoModificacao: a
    .model({
      id: a.id().required(),
      usuario: a.string().required(),
      data: a.datetime().required(),
      acao: a.enum(['adicionado', 'removido', 'alterado']),
      entidade: a.enum(['Material', 'Arranjo', 'Louvor']),
      entidadeId: a.string().required(),
      entidadeNome: a.string().required(),
      detalhes: a.json(), // Informações adicionais sobre a modificação
      
      // Referências para facilitar queries
      louvorId: a.id(),
      arranjoId: a.id(),
      materialId: a.id(),
    })
    .authorization((allow) => [
      allow.guest().to(['read', 'create']),
    ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'apiKey',
    // API Key is used for a.allow.guest() rules
    apiKeyAuthorizationMode: {
      expiresInDays: 30,
    },
  },
});
