<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api'
import { 
  HomeIcon, 
  CalendarIcon, 
  UsersIcon, 
  ArrowRightOnRectangleIcon,
  PlusIcon,
  TrashIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const users = ref([])
const loading = ref(true)
const currentUser = ref(null)

// Estado para modal de creación
const showModal = ref(false)
const newUser = ref({
  email: '',
  full_name: '',
  password: '',
  role: 'client' // default
})
const creating = ref(false)
const errorMsg = ref('')

onMounted(async () => {
  await fetchUser()
  await fetchUsers()
})

const fetchUser = async () => {
  try {
    const response = await api.get('/auth/me')
    currentUser.value = response.data
    // Security check
    if (currentUser.value.role !== 'admin') {
      alert("Acceso denegado")
      logout()
    }
  } catch (error) {
    logout()
  }
}

const fetchUsers = async () => {
  loading.value = true
  try {
    const response = await api.get('/auth/users')
    users.value = response.data
  } catch (error) {
    console.error("Error fetching users", error)
  } finally {
    loading.value = false
  }
}

const logout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}

const formatDate = (isoString) => {
  if (!isoString) return '-'
  return new Date(isoString).toLocaleDateString('es-ES')
}

const createUser = async () => {
  creating.value = true
  errorMsg.value = ''
  try {
    // Reutilizamos el endpoint de registro público, pero como admin
    // OJO: El endpoint /auth/register loguea al usuario si se usa desde fuera,
    // pero aquí solo queremos crearlo. El backend devuelve el usuario creado.
    await api.post('/auth/register', newUser.value)
    
    // Refresh list
    await fetchUsers()
    closeModal()
  } catch (e) {
    errorMsg.value = e.response?.data?.detail || "Error al crear usuario"
  } finally {
    creating.value = false
  }
}

const deleteUser = async (id) => {
  if(!confirm("¿Seguro que quieres eliminar este usuario?")) return;
  try {
    await api.delete(`/auth/users/${id}`)
    users.value = users.value.filter(u => u.id !== id)
  } catch (e) {
    alert(e.response?.data?.detail || "Error al eliminar usuario")
  }
}

const closeModal = () => {
  showModal.value = false
  newUser.value = { email: '', full_name: '', password: '', role: 'client' }
  errorMsg.value = ''
}
</script>

<template>
  <div class="flex h-screen bg-gray-100 font-sans">
    
    <!-- Sidebar (Duplicated for now) -->
    <aside class="w-64 bg-slate-900 text-white flex flex-col shadow-xl z-10">
      <div class="p-6 border-b border-slate-800">
        <h1 class="text-2xl font-bold tracking-tight text-blue-400">Gym<span class="text-white">Manager</span></h1>
      </div>
      
      <nav class="flex-1 p-4 space-y-2">
        <router-link to="/dashboard" class="flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors" :class="$route.path === '/dashboard' ? 'bg-slate-800 text-white' : 'text-slate-400 hover:bg-slate-800 hover:text-white'">
          <HomeIcon class="w-6 h-6" :class="$route.path === '/dashboard' ? 'text-blue-400' : ''"/>
          <span class="font-medium">Dashboard</span>
        </router-link>
        
        <router-link to="/dashboard" class="flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors" :class="$route.path === '/dashboard' ? 'text-white' : 'text-slate-400 hover:bg-slate-800 hover:text-white'">
           <CalendarIcon class="w-6 h-6"/>
           <span>Actividades</span>
        </router-link>

        <router-link to="/users" class="flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors" :class="$route.path === '/users' ? 'bg-slate-800 text-white' : 'text-slate-400 hover:bg-slate-800 hover:text-white'">
          <UsersIcon class="w-6 h-6" :class="$route.path === '/users' ? 'text-blue-400' : ''"/>
          <span class="font-medium">Usuarios</span>
        </router-link>
      </nav>

      <div class="p-4 border-t border-slate-800">
        <button @click="logout" class="flex items-center space-x-2 text-slate-400 hover:text-red-400 w-full px-4 py-2 transition-colors">
          <ArrowRightOnRectangleIcon class="w-5 h-5"/>
          <span>Cerrar Sesión</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col overflow-hidden">
      
      <header class="bg-white shadow-sm z-0 flex justify-between items-center px-8 py-4">
        <h2 class="text-xl font-semibold text-gray-800">Gestión de Usuarios</h2>
        <div class="flex items-center space-x-4" v-if="currentUser">
          <div class="text-right">
            <p class="text-sm font-medium text-gray-900">{{ currentUser.full_name }}</p>
            <p class="text-xs text-gray-500 capitalize">{{ currentUser.role }}</p>
          </div>
          <div class="h-10 w-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-lg border border-blue-200">
            {{ currentUser.full_name.charAt(0) }}
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-50 p-8">
        
        <!-- Users Table -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
            <h3 class="text-lg font-semibold text-gray-700">Listado de Usuarios</h3>
            <button @click="showModal = true" class="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors shadow-sm">
              <PlusIcon class="w-5 h-5"/>
              <span>Nuevo Usuario</span>
            </button>
          </div>
          
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                  <th class="px-6 py-3 font-semibold">Nombre</th>
                  <th class="px-6 py-3 font-semibold">Email</th>
                  <th class="px-6 py-3 font-semibold">Rol</th>
                  <th class="px-6 py-3 font-semibold">Registro</th>
                  <th class="px-6 py-3 font-semibold text-right">Estado</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="user in users" :key="user._id" class="hover:bg-gray-50 transition-colors">
                  <td class="px-6 py-4 font-medium text-gray-900">{{ user.full_name }}</td>
                  <td class="px-6 py-4 text-gray-600">{{ user.email }}</td>
                  <td class="px-6 py-4">
                    <span :class="`px-2 py-1 text-xs rounded-full font-semibold ${user.role === 'admin' ? 'bg-purple-100 text-purple-700' : 'bg-green-100 text-green-700'}`">
                      {{ user.role }}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-500">{{ formatDate(user.created_at) }}</td>
                  <td class="px-6 py-4 text-right">
                    <button 
                      v-if="currentUser && user.id !== currentUser.id"
                      @click="deleteUser(user.id)" 
                      class="text-slate-400 hover:text-red-600 transition-colors" 
                      title="Eliminar Usuario"
                    >
                      <TrashIcon class="w-5 h-5"/>
                    </button>
                    <span v-else class="text-xs text-gray-400 italic">Tú</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </main>
    </div>

    <!-- Modal Create User -->
    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        <h3 class="text-xl font-bold mb-4">Crear Nuevo Usuario</h3>
        
        <form @submit.prevent="createUser" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Nombre Completo</label>
            <input v-model="newUser.full_name" type="text" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm border p-2 focus:ring-blue-500 focus:border-blue-500" />
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700">Email</label>
            <input v-model="newUser.email" type="email" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm border p-2 focus:ring-blue-500 focus:border-blue-500" />
          </div>
          
          <div>
             <label class="block text-sm font-medium text-gray-700">Rol</label>
             <select v-model="newUser.role" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm border p-2">
               <option value="client">Cliente</option>
               <option value="admin">Administrador</option>
             </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Contraseña</label>
            <input v-model="newUser.password" type="password" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm border p-2 focus:ring-blue-500 focus:border-blue-500" />
          </div>

          <div v-if="errorMsg" class="text-red-600 text-sm">{{ errorMsg }}</div>

          <div class="flex justify-end space-x-3 mt-6">
            <button type="button" @click="closeModal" class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-md">Cancelar</button>
            <button type="submit" :disabled="creating" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {{ creating ? 'Guardando...' : 'Guardar' }}
            </button>
          </div>
        </form>
      </div>
    </div>

  </div>
</template>
