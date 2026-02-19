<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api'
import { UserIcon, LockClosedIcon } from '@heroicons/vue/24/solid'

const router = useRouter()
const email = ref('')
const password = ref('')
const fullName = ref('')
const confirmPassword = ref('')
const errorMsg = ref('')
const loading = ref(false)
const isAdminLogin = ref(true) // Toggle state (Visual only for login)
const isRegistering = ref(false) // Toggle between Login/Register form

const handleAuth = async () => {
  if (isRegistering.value) {
    await handleRegister()
  } else {
    await handleLogin()
  }
}

const handleLogin = async () => {
  loading.value = true
  errorMsg.value = ''
  
  try {
    // Usamos URLSearchParams para application/x-www-form-urlencoded
    const params = new URLSearchParams()
    params.append('username', email.value)
    params.append('password', password.value)

    const response = await api.post('/auth/login', params, {
       headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    })

    localStorage.setItem('token', response.data.access_token)
    
    // Consultar rol para redirigir
    const me = await api.get('/auth/me')
    if (me.data.role === 'admin') {
      router.push('/dashboard')
    } else {
      router.push('/client')
    }

  } catch (err) {
    console.error("Login error:", err)
    if (err.response) {
       errorMsg.value = `Error: ${err.response.data.detail || 'Credenciales incorrectas'}`
    } else {
       errorMsg.value = 'Error de red: El servidor no responde'
    }
  } finally {
    loading.value = false
  }
}

const handleRegister = async () => {
  if (password.value !== confirmPassword.value) {
    errorMsg.value = "Las contraseñas no coinciden"
    return
  }
  
  loading.value = true
  errorMsg.value = ''
  
  try {
    // Registro siempre como cliente
    await api.post('/auth/register', {
      email: email.value,
      full_name: fullName.value,
      password: password.value,
      role: 'client'
    })
    
    // Auto-login tras registro exitoso
    await handleLogin()
    
  } catch (err) {
    errorMsg.value = err.response?.data?.detail || "Error al registrarse"
    loading.value = false
  }
}

const toggleMode = () => {
  isRegistering.value = !isRegistering.value
  errorMsg.value = ''
  // Si vamos a registro, forzamos estilo "Cliente" (verde) porque solo clientes se registran
  if (isRegistering.value) isAdminLogin.value = false
}
</script>

<template>
  <div class="min-h-screen bg-slate-100 flex items-center justify-center p-4">
    <div class="max-w-md w-full bg-white rounded-xl shadow-lg overflow-hidden md:max-w-2xl">
      <div class="md:flex">
        <!-- Decorativo: Imagen lateral o color -->
        <div 
          class="md:shrink-0 md:w-48 flex items-center justify-center transition-colors duration-500"
          :class="isAdminLogin ? 'bg-blue-600' : 'bg-green-600'"
        >
           <div class="text-white text-center p-6">
              <h2 class="text-2xl font-bold mb-2">{{ isAdminLogin ? 'Admin' : 'Cliente' }}</h2>
              <p class="text-blue-100 text-sm">Gestiona tu centro deportivo con eficacia.</p>
           </div>
        </div>
        
        <!-- Formulario -->
        <div class="p-8 w-full transition-colors duration-500" :class="(isAdminLogin && !isRegistering) ? 'bg-white' : 'bg-green-50'">
          
          <div class="flex justify-between items-center mb-6">
            <div class="uppercase tracking-wide text-sm font-semibold" :class="(isAdminLogin && !isRegistering) ? 'text-blue-600' : 'text-green-600'">
              {{ isRegistering ? 'Crear Cuenta Nueva' : (isAdminLogin ? 'Acceso Administrativo' : 'Acceso Cliente') }}
            </div>
            
            <!-- Toggle Slider (Solo visible si NO estamos registrando) -->
            <button 
              v-if="!isRegistering"
              @click="isAdminLogin = !isAdminLogin"
              class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none"
              :class="isAdminLogin ? 'bg-blue-600' : 'bg-green-500'"
            >
              <span class="sr-only">Cambiar modo</span>
              <span 
                aria-hidden="true" 
                class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                :class="isAdminLogin ? 'translate-x-5' : 'translate-x-0'"
              />
            </button>
          </div>
          
          <form @submit.prevent="handleAuth" class="space-y-6">
            
            <!-- Campo Nombre (Solo Registro) -->
            <div v-if="isRegistering">
              <label class="block text-sm font-medium text-slate-700 mb-1">Nombre Completo</label>
              <input 
                type="text" 
                v-model="fullName" 
                required 
                class="block w-full rounded-md border-slate-300 shadow-sm focus:ring-green-500 focus:border-green-500 sm:text-sm py-2 px-3 border" 
                placeholder="Tu Nombre"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Correo Electrónico</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <UserIcon class="h-5 w-5 text-slate-400" />
                </div>
                <input 
                  type="email" 
                  v-model="email" 
                  required 
                  class="pl-10 block w-full rounded-md border-slate-300 shadow-sm sm:text-sm py-2 px-3 border" 
                  :class="(isAdminLogin && !isRegistering) ? 'focus:border-blue-500 focus:ring-blue-500' : 'focus:border-green-500 focus:ring-green-500'"
                  :placeholder="(isAdminLogin && !isRegistering) ? 'admin@empresa.com' : 'cliente@email.com'"
                />
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Contraseña</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <LockClosedIcon class="h-5 w-5 text-slate-400" />
                </div>
                <input 
                  type="password" 
                  v-model="password" 
                  required 
                  class="pl-10 block w-full rounded-md border-slate-300 shadow-sm sm:text-sm py-2 px-3 border" 
                  :class="(isAdminLogin && !isRegistering) ? 'focus:border-blue-500 focus:ring-blue-500' : 'focus:border-green-500 focus:ring-green-500'"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <!-- Confirmar Password (Solo Registro) -->
            <div v-if="isRegistering">
              <label class="block text-sm font-medium text-slate-700 mb-1">Confirmar Contraseña</label>
              <input 
                type="password" 
                v-model="confirmPassword" 
                required 
                class="block w-full rounded-md border-slate-300 shadow-sm focus:ring-green-500 focus:border-green-500 sm:text-sm py-2 px-3 border" 
                placeholder="Repite la contraseña"
              />
            </div>

            <div v-if="errorMsg" class="text-red-600 text-sm bg-red-50 p-2 rounded border border-red-200">
              {{ errorMsg }}
            </div>

            <button 
              type="submit" 
              :disabled="loading"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              :class="(isAdminLogin && !isRegistering) ? 'bg-blue-600 hover:bg-blue-700 focus:ring-blue-500' : 'bg-green-600 hover:bg-green-700 focus:ring-green-500'"
            >
              <svg v-if="loading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ loading ? 'Procesando...' : (isRegistering ? 'Crear Cuenta' : 'Iniciar Sesión') }}
            </button>

            <!-- Toggle Link -->
            <div class="text-center mt-4">
              <button 
                type="button"
                @click="toggleMode" 
                class="text-sm font-medium hover:underline focus:outline-none"
                :class="(isAdminLogin && !isRegistering) ? 'text-blue-600' : 'text-green-600'"
              >
                {{ isRegistering ? '¿Ya tienes cuenta? Inicia Sesión' : '¿No tienes cuenta? Regístrate aquí' }}
              </button>
            </div>

          </form>
        </div>
      </div>
    </div>
  </div>
</template>
