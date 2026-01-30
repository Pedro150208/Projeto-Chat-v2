# Messenger Project 💬

Um sistema de mensagens em tempo real completo, com backend em **Ruby on Rails** e frontend em **Vue.js**.  
Inclui suporte a WebSockets via ActionCable para notificações e mensagens instantâneas.

---

## 🚀 Como Executar o Projeto

O projeto agora roda com **Docker**, facilitando a execução do backend e frontend juntos.

### 1. Pré-requisitos

- **Docker**
- **Docker Compose**

> Não é necessário instalar Ruby ou Node localmente.

### 2. Executando com Docker

No diretório raiz do projeto (`Projeto-Chat-v2`), execute:

```bash
docker compose up --build
```

Isso irá:

- Buildar e iniciar o **backend Rails**
- Buildar e iniciar o **frontend Vue + Vite**
- Orquestrar ambos automaticamente

---

## 🌐 Portas de Acesso

| Serviço        | URL |
|----------------|-----|
| Frontend       | http://localhost:5173 |
| Backend/API    | http://localhost:3000 |

---

## 🛠️ Funcionalidades Implementadas

- **Autenticação Segura (JWT)**: Registro e login com tokens JSON Web.  
- **Auto-conversão de contas antigas**: Contas antigas são atualizadas automaticamente para JWT no primeiro login.  
- **Sessões Persistentes**: Usuário permanece logado após recarregar a página.  
- **Mensagens Instantâneas**: Recebimento em tempo real via WebSockets.  
- **Notificações (Toasts)**: Alertas com timeout automático de 5 segundos.  
- **Redirecionamento Inteligente**: Clique na notificação para abrir o chat correspondente.  
- **Busca de Contatos**: Adição de amigos por ID.  
- **Logout**: Encerra a sessão e limpa dados locais.

---

## 📁 Estrutura do Projeto

```
Projeto-Chat-v2/
├── messenger_backend/   # Rails 8 API + ActionCable
├── messenger_frontend/  # Vue 3 + Vite
├── docker-compose.yml
└── README.md
```

> Estrutura em monorepo, eliminando problemas de submódulos Git ou pastas fantasmas.

---

## 📝 Notas Adicionais

- Comunicação entre frontend e backend via **JSON**.  
- Canal WebSocket principal: `ChatChannel`.  
- Contatos persistidos no `localStorage` para facilitar o uso.  
- Node.js fixado na **v20** no Docker para compatibilidade com Rails 8 + Vite.
