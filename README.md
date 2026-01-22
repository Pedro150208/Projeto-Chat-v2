# Messenger Project 💬

Um sistema de mensagens em tempo real completo, com backend em **Ruby on Rails** e frontend em **Vue.js**. Inclui suporte a WebSockets via ActionCable para notificações e mensagens instantâneas.

---

## 🚀 Como Executar o Projeto

Siga os passos abaixo para configurar e rodar as duas partes do projeto (Backend e Frontend).

### 1. Pré-requisitos
Certifique-se de ter instalado:
- **Ruby** (recomendado v3.2+)
- **Node.js** (v18+) e **npm**
- **SQLite3**

---

### 2. Configurando o Backend (Rails)

O backend gerencia o banco de dados, autenticação e o servidor de WebSocket.

1.  Abra o terminal na pasta `messenger_backend`.
2.  Instale as dependências de Ruby:
    ```bash
    bundle install
    ```
3.  Prepare o banco de dados (SQLite):
    ```bash
    rails db:create
    rails db:migrate
    ```
4.  Inicie o servidor Rails:
    ```bash
    rails s
    ```
    *O servidor rodará por padrão em `http://localhost:3000`.*

---

### 3. Configurando o Frontend (Vue.js + Vite)

O frontend é a interface onde os usuários interagem.

1.  Abra um **novo terminal** na pasta `messenger_frontend`.
2.  Instale as dependências do Node:
    ```bash
    npm install
    ```
3.  Inicie o servidor de desenvolvimento:
    ```bash
    npm run dev
    ```
    *O Vite abrirá o projeto em uma porta como `http://localhost:5173` ou `http://localhost:5174`.*

---

## 🛠️ Funcionalidades Implementadas

- **Autenticação Segura (JWT)**: Registro e Login com Tokens JSON Web e criptografia de senhas (`bcrypt`).
- **Sessões Persistentes**: O usuário permanece logado após recarregar a página (token persistido).
- **Mensagens Instantâneas**: Recebimento em tempo real via WebSockets autenticados.
- **Toasts de Notificação**: Alertas inteligentes com timeout automático de 5 segundos.
- **Redirecionamento Inteligente**: Clique na notificação para abrir o chat correspondente.
- **Busca de Contatos**: Adição de amigos por ID.
- **Logout**: Botão para encerrar a sessão e limpar dados locais.

---

## 🔐 Segurança e JWT

O projeto utiliza um fluxo de autenticação moderno:
1.  **Backend**: O `ApplicationController` valida o token enviado no header `Authorization: Bearer <token>`.
2.  **Senhas**: Utiliza `has_secure_password` do Rails para garantir que senhas nunca sejam salvas em texto puro.
3.  **WebSocket**: A conexão via ActionCable é protegida; o token é enviado via query string e validado no servidor antes de permitir o tráfego de mensagens.
4.  **Auto-conversão**: O sistema detecta contas antigas e as converte automaticamente para o formato seguro durante o primeiro login bem-sucedido após a atualização.

---

## 📁 Estrutura do Projeto

- `/messenger_backend`: Rails 8 API com ActionCable.
- `/messenger_frontend`: Vue 3 (Composition API) com Vite.

---

## 📝 Notas Adicionais
- O sistema utiliza **JSON** para comunicação entre frontend e backend.
- O WebSocket utiliza o canal `ChatChannel`.
- Dados de contatos são persistidos no `localStorage` do navegador para facilitar o uso.
