# Coletânea Digital

**Organização de Materiais de Estudo - Igreja Cristã Maranata**

Um sistema web desenvolvido em Angular 19 com AWS Amplify para gerenciar e organizar materiais de estudo como PDFs e arquivos de áudio.

## 🚀 Tecnologias Utilizadas

- **Frontend:** Angular 19
- **Backend/Infraestrutura:** AWS Amplify
- **Banco de Dados:** Amazon DynamoDB (metadados)
- **Armazenamento:** Amazon S3 (arquivos)
- **Deploy:** AWS Amplify Hosting

## 📋 Funcionalidades

- ✅ Upload de arquivos PDF e áudio
- ✅ Organização por categorias (Louvor, Estudo Bíblico, Hinário, etc.)
- ✅ Sistema de tags para facilitar a busca
- ✅ Visualização e reprodução de arquivos
- ✅ Download de materiais
- ✅ Busca e filtros avançados
- 🚧 Criação de listas personalizadas (em desenvolvimento)
- 🚧 Autenticação de usuários (planejado)

## 🛠️ Configuração do Projeto

### Pré-requisitos

- Node.js (versão 18+)
- Angular CLI (`npm install -g @angular/cli`)
- AWS CLI configurado
- Conta AWS ativa

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/coletanea-digital.git
cd coletanea-digital
```

2. Instale as dependências:
```bash
npm install
```

3. Configure o AWS Amplify:
```bash
amplify configure
amplify init
```

4. Adicione os serviços AWS:
```bash
amplify add storage
amplify add api
amplify push
```

### Desenvolvimento

Para iniciar o servidor de desenvolvimento:

### Desenvolvimento

Para iniciar o servidor de desenvolvimento:

```bash
ng serve
```

Acesse `http://localhost:4200/` no seu navegador.

## 🏗️ Estrutura do Projeto

```
src/
├── app/
│   ├── components/
│   │   ├── biblioteca/           # Lista e gerencia materiais
│   │   └── upload-material/      # Upload de novos materiais
│   ├── services/
│   │   └── amplify.service.ts    # Integração com AWS Amplify
│   ├── app.component.*          # Componente principal
│   ├── app.routes.ts            # Configuração de rotas
│   └── main.ts                  # Configuração AWS Amplify
├── index.html
└── styles.scss
```

## 📦 Scripts Disponíveis
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in the `dist/` directory. By default, the production build optimizes your application for performance and speed.

## Running unit tests

To execute unit tests with the [Karma](https://karma-runner.github.io) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.
