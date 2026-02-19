<script setup>
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api'
import ActivityModal from '../components/ActivityModal.vue'
import AttendanceModal from '../components/AttendanceModal.vue'
import { 
  HomeIcon, 
  UsersIcon, 
  ArrowRightOnRectangleIcon,
  PlusIcon,
  TrashIcon,
  PencilSquareIcon,
  EyeIcon,
  CalendarIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const user = ref(null)
const activities = ref([])
const loading = ref(true)

// --- Computed Stats ---
const todayActivitiesCount = computed(() => {
  const today = new Date().toISOString().slice(0, 10) // YYYY-MM-DD
  return activities.value.filter(a => a.start_time.startsWith(today)).length
})

const totalReservationsCount = computed(() => {
  return activities.value.reduce((acc, curr) => acc + (curr.booked_count || 0), 0)
})

// Modal Logic
const showModal = ref(false)
const showAttendanceModal = ref(false)
const selectedActivity = ref(null)

const openCreateModal = () => {
  selectedActivity.value = null
  showModal.value = true
}

const openEditModal = (activity) => {
  selectedActivity.value = activity 
  showModal.value = true
}

const openAttendanceModal = (activity) => {
  selectedActivity.value = activity
  showAttendanceModal.value = true
}

const onActivitySaved = async () => {
  await fetchActivities() // Auto-refresh after save
}

onMounted(async () => {
  await fetchUser()
  await fetchActivities()
})

const fetchUser = async () => {
  try {
    const response = await api.get('/auth/me')
    user.value = response.data
  } catch (error) {
    logout()
  }
}

const fetchActivities = async () => {
  loading.value = true
  try {
    const response = await api.get('/activities')
    activities.value = response.data
  } catch (error) {
    console.error("Error fetching activities", error)
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
  const date = new Date(isoString)
  return date.toLocaleString('es-ES', { 
    weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' 
  })
}

const handleDelete = async (id) => {
  if(!confirm("¿Estás seguro de eliminar esta clase?")) return;
  try {
    await api.delete(`/activities/${id}`)
    activities.value = activities.value.filter(a => a._id !== id)
  } catch (e) {
    alert("Error al eliminar")
  }
}
</script>

<template>
  <div class="flex h-screen bg-gray-100 font-sans">
    
    <!-- Sidebar -->
    <aside class="w-64 bg-slate-900 text-white flex flex-col shadow-xl z-10">
      <div class="p-6 border-b border-slate-800">
        <h1 class="text-2xl font-bold tracking-tight text-blue-400">Gym<span class="text-white">Manager</span></h1>
      </div>
      
      <nav class="flex-1 p-4 space-y-2">
        <!-- Dashboard Link -->
        <router-link to="/dashboard" class="flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors" :class="$route.path === '/dashboard' ? 'bg-slate-800 text-white' : 'text-slate-400 hover:bg-slate-800 hover:text-white'">
          <HomeIcon class="w-6 h-6" :class="$route.path === '/dashboard' ? 'text-blue-400' : ''"/>
          <span class="font-medium">Dashboard</span>
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
      
      <!-- Top Header -->
      <header class="bg-white shadow-sm z-0 flex justify-between items-center px-8 py-4">
        <h2 class="text-xl font-semibold text-gray-800">Panel de Control</h2>
        <div class="flex items-center space-x-4" v-if="user">
          <div class="text-right">
            <p class="text-sm font-medium text-gray-900">{{ user.full_name }}</p>
            <p class="text-xs text-gray-500 capitalize">{{ user.role }}</p>
          </div>
          <div class="h-10 w-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-lg border border-blue-200">
            {{ user.full_name.charAt(0) }}
          </div>
        </div>
      </header>

      <!-- Content Area -->
      <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-50 p-8">
        
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-white rounded-xl shadow-sm p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-500 mb-1">Actividades Hoy</p>
                <h3 class="text-3xl font-bold text-gray-800">{{ todayActivitiesCount }}</h3>
              </div>
              <div class="p-3 bg-blue-50 rounded-full text-blue-600">
                <CalendarIcon class="w-8 h-8"/>
              </div>
            </div>
          </div>
           <div class="bg-white rounded-xl shadow-sm p-6 border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-gray-500 mb-1">Reservas Totales</p>
                <h3 class="text-3xl font-bold text-gray-800">{{ totalReservationsCount }}</h3>
              </div>
              <div class="p-3 bg-green-50 rounded-full text-green-600">
                <UsersIcon class="w-8 h-8"/>
              </div>
            </div>
          </div>
        </div>

        <!-- Activities Table Section -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
            <h3 class="text-lg font-semibold text-gray-700">Próximas Clases</h3>
            <button @click="openCreateModal" class="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors shadow-sm">
              <PlusIcon class="w-5 h-5"/>
              <span>Nueva Clase</span>
            </button>
          </div>
          
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                  <th class="px-6 py-3 font-semibold">Actividad</th>
                  <th class="px-6 py-3 font-semibold">Horario</th>
                  <th class="px-6 py-3 font-semibold">Instructor</th>
                  <th class="px-6 py-3 font-semibold">Aforo</th>
                  <th class="px-6 py-3 font-semibold text-right">Acciones</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="activity in activities" :key="activity._id" class="hover:bg-gray-50 transition-colors">
                  <td class="px-6 py-4">
                    <p class="font-medium text-gray-900">{{ activity.title }}</p>
                    <p class="text-xs text-gray-500">{{ activity.location }}</p>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-600">
                    {{ formatDate(activity.start_time) }}
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-600 flex items-center space-x-2">
                     <div class="h-6 w-6 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">
                        {{ activity.instructor.charAt(0) }}
                     </div>
                     <span>{{ activity.instructor }}</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center">
                      <div class="flex-1 h-2 bg-gray-200 rounded-full max-w-[100px] mr-2 overflow-hidden">
                        <div class="h-full bg-blue-500 rounded-full" :style="`width: ${(activity.booked_count / activity.capacity) * 100}%`"></div>
                      </div>
                      <span class="text-xs font-medium text-gray-600">{{ activity.booked_count }}/{{ activity.capacity }}</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-right space-x-2">
                    <button @click="openAttendanceModal(activity)" class="text-slate-400 hover:text-green-600 transition-colors" title="Ver Lista">
                      <EyeIcon class="w-5 h-5"/>
                    </button>
                    <button @click="openEditModal(activity)" class="text-slate-400 hover:text-blue-600 transition-colors" title="Editar">
                      <PencilSquareIcon class="w-5 h-5"/>
                    </button>
                    <button @click="handleDelete(activity._id)" class="text-slate-400 hover:text-red-600 transition-colors" title="Eliminar">
                      <TrashIcon class="w-5 h-5"/>
                    </button>
                  </td>
                </tr>
                <tr v-if="activities.length === 0 && !loading">
                  <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                    No hay actividades programadas.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </main>
    </div>

    <!-- Modals -->
    <ActivityModal 
      v-if="showModal" 
      :activity="selectedActivity"
      @close="showModal = false"
      @saved="onActivitySaved"
    />

    <AttendanceModal
      v-if="showAttendanceModal"
      :activity="selectedActivity"
      @close="showAttendanceModal = false"
    />

  </div>
</template>
