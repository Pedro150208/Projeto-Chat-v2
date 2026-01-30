<script setup>
import { ref, onMounted, nextTick, computed } from 'vue'
import messages from './i18n.json'

const locale = ref('pt')

function t(key) {
  return messages[locale.value][key] || key
}

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
  setTimeout(() => removeToast(id), 5000); 
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
    addToast(t('toastFillFields'), 'error');
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
      addToast(t('toastLoginSuccess'), 'success');
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
    addToast(t('toastFillFields'), 'error');
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
      addToast(t('toastRegisterSuccess'), 'success');
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
      addToast(t('toastSelfAdd'), 'error');
      return;
    }

    const jaTem = usuarios.value.find(u => u.id === novoAmigo.id);
    if (!jaTem) {
      usuarios.value.push(novoAmigo);
      localStorage.setItem('meus_contatos', JSON.stringify(usuarios.value));
    }
    idBusca.value = ""; 
  } catch (e) {
    addToast(t('toastNotFound'), 'error');
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

    
    if (data.type === "ping" || data.type === "welcome" || data.type === "confirm_subscription") return;

    console.log('Received:', data);
    
  
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
          addToast(`${t('newMsgFrom')} ${sender.email}`, 'info', msg.sender_id);
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
      if (!mensagens.value.find(m => m.id === msg.id)) {
        mensagens.value.push(msg);
        scrollToBottom();
      }
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
      <h1>{{ t('registerTitle') }}</h1>
      <div class="input-stack">
        <input v-model="emailRegister" :placeholder="t('emailPlaceholder')" type="email" />
        <input v-model="senhaRegister" type="password" :placeholder="t('passwordPlaceholder')" @keyup.enter="registrar" />
        <button class="btn-primary" @click="registrar">{{ t('btnRegister') }}</button>
        <p>{{ t('hasAccount') }} <a href="#" @click="currentView = 'login'">{{ t('linkLogin') }}</a></p>
      </div>
      <div class="lang-switcher">
        <img src="https://flagcdn.com/24x18/br.png" alt="Português" @click="locale = 'pt'" class="flag-icon" :class="{ active: locale === 'pt' }" />
        <img src="https://flagcdn.com/24x18/us.png" alt="English" @click="locale = 'en'" class="flag-icon" :class="{ active: locale === 'en' }" />
        <img src="https://flagcdn.com/24x18/es.png" alt="Español" @click="locale = 'es'" class="flag-icon" :class="{ active: locale === 'es' }" />
      </div>
    </div>

    <div v-else class="auth-box">
      <h1>{{ t('loginTitle') }}</h1>
      <div class="input-stack">
        <input v-model="emailLogin" :placeholder="t('emailPlaceholder')" type="email" />
        <input v-model="senhaLogin" type="password" :placeholder="t('passwordPlaceholder')" @keyup.enter="fazerLogin" />
        <button class="btn-primary" @click="fazerLogin">{{ t('btnLogin') }}</button>
        <p>{{ t('noAccount') }} <a href="#" @click="currentView = 'register'">{{ t('linkRegister') }}</a></p>
      </div>
      <div class="lang-switcher">
        <img src="https://flagcdn.com/24x18/br.png" alt="Português" @click="locale = 'pt'" class="flag-icon" :class="{ active: locale === 'pt' }" />
        <img src="https://flagcdn.com/24x18/us.png" alt="English" @click="locale = 'en'" class="flag-icon" :class="{ active: locale === 'en' }" />
        <img src="https://flagcdn.com/24x18/es.png" alt="Español" @click="locale = 'es'" class="flag-icon" :class="{ active: locale === 'es' }" />
      </div>
    </div>
  </div>

  <div v-else class="zap-container">
    <aside class="sidebar">
      <div class="user-info">
        <div class="lang-switcher-sidebar">
           <img src="https://flagcdn.com/24x18/br.png" alt="Português" @click="locale = 'pt'" class="flag-icon" :class="{ active: locale === 'pt' }" />
           <img src="https://flagcdn.com/24x18/us.png" alt="English" @click="locale = 'en'" class="flag-icon" :class="{ active: locale === 'en' }" />
           <img src="https://flagcdn.com/24x18/es.png" alt="Español" @click="locale = 'es'" class="flag-icon" :class="{ active: locale === 'es' }" />
        </div>
        <div class="user-row">
          <span class="nome-usuario">{{ meuUsuario.email }}</span>
          <button @click="logout" class="logout-btn">{{ t('logout') }}</button>
        </div>
        <span class="id-usuario">{{ t('yourId') }}: {{ meuUsuario.id }}</span>
      </div>

      <div class="search-section-top">
        <label>{{ t('newContact') }}</label>
        <div class="search-row">
          <input v-model="idBusca" type="number" :placeholder="t('idPlaceholder')" @keyup.enter="adicionarAmigo"/>
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
            <input v-model="novaMensagem" :placeholder="t('typeMessage')" @keyup.enter="enviarMensagem" />
            <button class="send-btn" @click="enviarMensagem">➤</button>
          </div>
        </div>
      </div>
      
      <div v-else class="welcome-screen">
        <div class="welcome-box">
          <h2>{{ t('selectChat') }}</h2>
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
.flag-icon {
  cursor: pointer;
  margin: 0 5px;
  border: 2px solid transparent;
  border-radius: 4px;
  transition: transform 0.2s;
}
.flag-icon:hover {
  transform: scale(1.1);
}
.flag-icon.active {
  border-color: #fff;
}
.lang-switcher-sidebar {
  margin-bottom: 15px;
  display: flex;
  justify-content: center;
}
.lang-switcher {
  margin-top: 20px;
}
.nome-usuario {
  margin-left: 65px;
}
</style>