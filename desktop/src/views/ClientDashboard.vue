<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api'
import { CalendarIcon, ArrowRightOnRectangleIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/vue/24/outline'

const router = useRouter()
const user = ref(null)
const activities = ref([])
const myReservations = ref([])
const loading = ref(true)

onMounted(async () => {
  await fetchUser()
  await fetchAll()
})

const fetchUser = async () => {
  try {
    const response = await api.get('/auth/me')
    user.value = response.data
  } catch (error) {
    router.push('/login')
  }
}

const fetchAll = async () => {
  loading.value = true
  try {
    const [actRes, myRes] = await Promise.all([
      api.get('/activities'),
      api.get('/reservations/me')
    ])
    activities.value = actRes.data
    myReservations.value = myRes.data
  } catch (error) {
    console.error(error)
  } finally {
    loading.value = false
  }
}

const isBooked = (activityId) => {
  return myReservations.value.some(r => r.activity_id === activityId && r.status === 'active')
}

const bookActivity = async (activityId) => {
  try {
    await api.post('/reservations/', { activity_id: activityId })
    alert("¡Reserva confirmada!")
    await fetchAll()
  } catch (e) {
    alert(e.response?.data?.detail || "Error al reservar")
  }
}

const cancelReservation = async (reservationId) => {
  if(!confirm("¿Cancelar reserva? Si es <15 min antes, cuenta como falta.")) return;
  try {
    const res = await api.put(`/reservations/${reservationId}/cancel`)
    alert(res.data.message)
    await fetchAll()
  } catch (e) {
    alert("Error al cancelar")
  }
}

const logout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}

const formatDate = (isoString) => {
  return new Date(isoString).toLocaleString('es-ES', { 
    weekday: 'long', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' 
  })
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 font-sans">
    
    <!-- Navbar -->
    <nav class="bg-white shadow-sm px-6 py-4 flex justify-between items-center">
      <div class="flex items-center space-x-2">
        <div class="bg-blue-600 text-white p-2 rounded-lg">
          <CalendarIcon class="w-6 h-6" />
        </div>
        <span class="text-xl font-bold text-gray-800">Mi Gimnasio</span>
      </div>
      
      <div class="flex items-center space-x-4">
        <span v-if="user" class="text-sm font-medium text-gray-600">Hola, {{ user.full_name }}</span>
        <button @click="logout" class="text-gray-500 hover:text-red-500">
          <ArrowRightOnRectangleIcon class="w-6 h-6" />
        </button>
      </div>
    </nav>

    <main class="max-w-5xl mx-auto p-6 space-y-8">
      
      <!-- Mis Reservas -->
      <section>
        <h2 class="text-xl font-bold text-gray-800 mb-4">Mis Reservas Activas</h2>
        <div v-if="myReservations.filter(r => r.status === 'active').length === 0" class="bg-white p-6 rounded-xl shadow-sm text-center text-gray-500">
          No tienes reservas activas. ¡Apúntate a algo!
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div v-for="res in myReservations.filter(r => r.status === 'active')" :key="res._id" class="bg-white p-5 rounded-xl shadow-sm border-l-4 border-green-500 flex justify-between items-center">
            <div>
              <h3 class="font-bold text-lg">{{ res.activity_title }}</h3>
              <p class="text-sm text-gray-500">{{ formatDate(res.activity_start_time) }}</p>
            </div>
            <button @click="cancelReservation(res._id)" class="text-sm text-red-600 hover:bg-red-50 px-3 py-1 rounded border border-red-200">
              Cancelar
            </button>
          </div>
        </div>
      </section>

      <!-- Actividades Disponibles -->
      <section>
        <h2 class="text-xl font-bold text-gray-800 mb-4">Próximas Clases</h2>
        <div class="bg-white rounded-xl shadow-sm overflow-hidden">
          <table class="w-full text-left">
            <thead class="bg-gray-50 border-b">
              <tr>
                <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Actividad</th>
                <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Horario</th>
                <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Plazas</th>
                <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase text-right">Estado</th>
              </tr>
            </thead>
            <tbody class="divide-y">
              <tr v-for="act in activities" :key="act._id" class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <p class="font-medium">{{ act.title }}</p>
                  <p class="text-xs text-gray-500">{{ act.instructor }}</p>
                </td>
                <td class="px-6 py-4 text-sm text-gray-600">
                  {{ formatDate(act.start_time) }}
                </td>
                <td class="px-6 py-4 text-sm">
                  <span :class="act.booked_count >= act.capacity ? 'text-red-500 font-bold' : 'text-green-600'">
                    {{ act.booked_count }} / {{ act.capacity }}
                  </span>
                </td>
                <td class="px-6 py-4 text-right">
                  <button 
                    v-if="isBooked(act._id)"
                    disabled
                    class="text-green-600 text-sm font-medium flex items-center justify-end w-full cursor-default"
                  >
                    <CheckCircleIcon class="w-5 h-5 mr-1"/> Apuntado
                  </button>
                  <button 
                    v-else-if="act.booked_count >= act.capacity"
                    disabled
                    class="text-gray-400 text-sm font-medium cursor-not-allowed"
                  >
                    Completo
                  </button>
                  <button 
                    v-else
                    @click="bookActivity(act._id)"
                    class="bg-blue-600 hover:bg-blue-700 text-white text-sm px-4 py-2 rounded-lg transition-colors"
                  >
                    Reservar
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

    </main>
  </div>
</template>
