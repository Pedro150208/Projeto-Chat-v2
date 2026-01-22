<script setup>
import { ref, onMounted, nextTick } from 'vue'

const meuUsuario = ref(null) 
const token = ref(null)
const emailLogin = ref("")
const senhaLogin = ref("")
const emailRegister = ref("")
const senhaRegister = ref("")
const currentView = ref('login')
const idBusca = ref("")
const usuarios = ref([]) 
const usuarioSelecionado = ref(null)
const mensagens = ref([])
const novaMensagem = ref("")
const toasts = ref([])
const socket = ref(null)

// Carregar usuário e token salvos
onMounted(() => {
  const savedUser = localStorage.getItem('usuario');
  const savedToken = localStorage.getItem('token');
  const savedContacts = localStorage.getItem('meus_contatos');

  if (savedUser && savedToken) {
    meuUsuario.value = JSON.parse(savedUser);
    token.value = savedToken;
    conectarWebSocket();
  }

  if (savedContacts) {
    usuarios.value = JSON.parse(savedContacts);
  }
});

function addToast(message, type = 'info', userId = null) {
  const id = Date.now();
  toasts.value.push({ id, message, type, userId });
  setTimeout(() => removeToast(id), 5000); // Remove após 5 segundos
}

function removeToast(id) {
  toasts.value = toasts.value.filter(t => t.id !== id);
}

function clicarNoToast(toast) {
  if (toast.userId) {
    const user = usuarios.value.find(u => u.id === toast.userId);
    if (user) selecionarUsuario(user);
  }
  removeToast(toast.id);
}
function logout() {
  meuUsuario.value = null;
  token.value = null;
  localStorage.removeItem('usuario');
  localStorage.removeItem('token');
  if (socket.value) socket.value.close();
}

async function selecionarUsuario(user) {
  if (!meuUsuario.value || !user) return;
  usuarioSelecionado.value = user;
  
  try {
    const response = await fetch(`http://localhost:3000/messages/${meuUsuario.value.id}/${user.id}`, {
      headers: { 'Authorization': `Bearer ${token.value}` }
    });
    if (response.ok) {
      mensagens.value = await response.json(); 
      scrollToBottom();
    }
  } catch (error) {
    console.error(error);
  }
}

async function fazerLogin() {
  if (!emailLogin.value || !senhaLogin.value) {
    addToast("Por favor, preencha email e senha.", 'error');
    return;
  }

  try {
    const req = await fetch('http://localhost:3000/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        email: emailLogin.value, 
        password: senhaLogin.value 
      })
    });

    const data = await req.json();

    if (req.ok) {
      meuUsuario.value = data.user; 
      token.value = data.token;
      localStorage.setItem('usuario', JSON.stringify(data.user));
      localStorage.setItem('token', data.token);
      addToast("Login realizado com sucesso!", 'success');
      conectarWebSocket(); 
    } else {
      addToast(data.error || "Erro no login", 'error');
    }
  } catch (error) {
    addToast("Erro ao conectar com o servidor.", 'error');
  }
}

async function registrar() {
  if (!emailRegister.value || !senhaRegister.value) {
    addToast("Por favor, preencha email e senha.", 'error');
    return;
  }

  try {
    const req = await fetch('http://localhost:3000/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        email: emailRegister.value, 
        password: senhaRegister.value,
        register: true
      })
    });

    const data = await req.json();

    if (req.ok) {
      meuUsuario.value = data.user; 
      token.value = data.token;
      localStorage.setItem('usuario', JSON.stringify(data.user));
      localStorage.setItem('token', data.token);
      addToast("Registrado com sucesso!", 'success');
      conectarWebSocket();
      emailRegister.value = "";
      senhaRegister.value = "";
    } else {
      addToast(data.error || "Erro no registro", 'error');
    }
  } catch (error) {
    addToast("Erro ao conectar com o servidor.", 'error');
  }
}

async function adicionarAmigo() {
  if (!idBusca.value || !meuUsuario.value) return;
  try {
    const res = await fetch(`http://localhost:3000/users/${idBusca.value}`, {
      headers: { 'Authorization': `Bearer ${token.value}` }
    });
    if (!res.ok) throw new Error();
    
    const novoAmigo = await res.json();
    if (novoAmigo.id === meuUsuario.value.id) {
      addToast("É você mesmo!", 'error');
      return;
    }

    const jaTem = usuarios.value.find(u => u.id === novoAmigo.id);
    if (!jaTem) {
      usuarios.value.push(novoAmigo);
      localStorage.setItem('meus_contatos', JSON.stringify(usuarios.value));
    }
    idBusca.value = ""; 
  } catch (e) {
    addToast("ID não encontrado!", 'error');
  }
}

function conectarWebSocket() {
  // Passamos o token na query string para autenticação
  socket.value = new WebSocket(`ws://localhost:3000/cable?token=${token.value}`);

  socket.value.onopen = () => {
    console.log('WebSocket connected');
    const sub = {
      command: "subscribe",
      identifier: JSON.stringify({ channel: "ChatChannel" })
    };
    socket.value.send(JSON.stringify(sub));
  };

  socket.value.onerror = (error) => {
    addToast("Erro na conexão WebSocket.", 'error');
    console.error('WebSocket error:', error);
  };

  socket.value.onmessage = async (event) => {
    const data = JSON.parse(event.data);

    // Ignorar pings e mensagens de sistema do ActionCable
    if (data.type === "ping" || data.type === "welcome" || data.type === "confirm_subscription") return;

    console.log('Received:', data);
    
    // O ActionCable envolve o broadcast em 'message'. 
    // Como o backend envia { message: @message }, aqui recebemos data.message.message
    if (data.message && data.message.message) {
      const msg = data.message.message;
      const souParente = msg.sender_id === meuUsuario.value.id || msg.recipient_id === meuUsuario.value.id;

      if (souParente) {
        const idOutraPessoa = msg.sender_id === meuUsuario.value.id ? msg.recipient_id : msg.sender_id;
        const contatoExiste = usuarios.value.find(u => u.id === idOutraPessoa);

        if (!contatoExiste) {
          try {
            const res = await fetch(`http://localhost:3000/users/${idOutraPessoa}`, {
              headers: { 'Authorization': `Bearer ${token.value}` }
            });
            if (res.ok) {
              const novoContato = await res.json();
              if (novoContato && novoContato.email) {
                usuarios.value.push(novoContato);
                localStorage.setItem('meus_contatos', JSON.stringify(usuarios.value));
              }
            }
          } catch (e) {
            console.error(e);
          }
        }

        if (usuarioSelecionado.value && usuarioSelecionado.value.id === idOutraPessoa) {
          if (!mensagens.value.find(m => m.id === msg.id)) {
            mensagens.value.push(msg);
            scrollToBottom();
          }
        }

        const sender = usuarios.value.find(u => u.id === msg.sender_id);
        if (sender && (!usuarioSelecionado.value || usuarioSelecionado.value.id !== msg.sender_id)) {
          addToast(`Nova mensagem de ${sender.email}`, 'info', msg.sender_id);
        }
      }
    }
  };
}

async function enviarMensagem() {
  if (!novaMensagem.value.trim() || !usuarioSelecionado.value) return;

  const pacote = {
    message: {
      content: novaMensagem.value,
      sender_id: meuUsuario.value.id,
      recipient_id: usuarioSelecionado.value.id
    }
  };

  try {
    const req = await fetch('http://localhost:3000/messages', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token.value}`
      },
      body: JSON.stringify(pacote)
    });
    if (req.ok) {
      const msg = await req.json();
      mensagens.value.push(msg);
      scrollToBottom();
      novaMensagem.value = "";
    }
  } catch (error) {
    console.error(error);
  }
}

function scrollToBottom() {
  nextTick(() => {
    const lista = document.querySelector('.messages-list');
    if (lista) lista.scrollTop = lista.scrollHeight;
  });
}
</script>

<template>
  <div v-if="!meuUsuario" class="auth-screen">
    <div v-if="currentView === 'register'" class="auth-box">
      <h1>Registrar no Messenger 💬</h1>
      <div class="input-stack">
        <input v-model="emailRegister" placeholder="Email" type="email" />
        <input v-model="senhaRegister" type="password" placeholder="Senha" @keyup.enter="registrar" />
        <button class="btn-primary" @click="registrar">Registrar</button>
        <p>Já tem conta? <a href="#" @click="currentView = 'login'">Faça login</a></p>
      </div>
    </div>

    <div v-else class="auth-box">
      <h1>Login no Messenger 💬</h1>
      <div class="input-stack">
        <input v-model="emailLogin" placeholder="Email" type="email" />
        <input v-model="senhaLogin" type="password" placeholder="Senha" @keyup.enter="fazerLogin" />
        <button class="btn-primary" @click="fazerLogin">Entrar</button>
        <p>Não tem conta? <a href="#" @click="currentView = 'register'">Registre-se</a></p>
      </div>
    </div>
  </div>

  <div v-else class="zap-container">
    <aside class="sidebar">
      <div class="user-info">
        <div class="user-row">
          <span class="nome-usuario">{{ meuUsuario.email }}</span>
          <button @click="logout" class="logout-btn">Sair</button>
        </div>
        <span class="id-usuario">Seu ID: {{ meuUsuario.id }}</span>
      </div>

      <div class="search-section-top">
        <label>Novo Contato</label>
        <div class="search-row">
          <input v-model="idBusca" type="number" placeholder="ID..." @keyup.enter="adicionarAmigo"/>
          <button @click="adicionarAmigo">+</button>
        </div>
      </div>

      <div class="lista-contatos">
        <div 
          v-for="user in usuarios" 
          :key="user.id"
          @click="selecionarUsuario(user)"
          :class="['user-item', { active: usuarioSelecionado?.id === user.id }]"
        >
          <div class="avatar-mini">{{ user && user.email ? user.email[0] : '?' }}</div>
          <span>{{ user.email }}</span>
        </div>
      </div>
    </aside>

    <main class="chat-area">
      <div v-if="usuarioSelecionado" class="chat-window">
        <header class="chat-header">
          <span class="header-name">{{ usuarioSelecionado.email }}</span>
        </header>
        
        <div class="messages-list">
          <div 
            v-for="msg in mensagens" 
            :key="msg.id"
            :class="['bubble', msg.sender_id === meuUsuario.id ? 'sent' : 'received']"
          >
            {{ msg.content }}
          </div>
        </div>

        <div class="footer-send">
          <div class="input-wrapper">
            <input v-model="novaMensagem" placeholder="Escreva uma mensagem..." @keyup.enter="enviarMensagem" />
            <button class="send-btn" @click="enviarMensagem">➤</button>
          </div>
        </div>
      </div>
      
      <div v-else class="welcome-screen">
        <div class="welcome-box">
          <h2>Selecione uma conversa</h2>
        </div>
      </div>
    </main>
  </div>

  <div class="toast-container">
    <div 
      v-for="toast in toasts" 
      :key="toast.id"
      :class="['toast', toast.type]"
      @click="clicarNoToast(toast)"
    >
      {{ toast.message }}
    </div>
  </div>
</template>

<style>
body, html {
  margin: 0; 
  padding: 0;
  width: 100%; 
  height: 100%;
  overflow: hidden; 
  background-color: #000;
}
</style>